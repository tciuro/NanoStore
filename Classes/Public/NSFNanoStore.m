/*
     NSFNanoStore.m
     NanoStore
     
     Copyright (c) 2010 Webbo, L.L.C. All rights reserved.
     
     Redistribution and use in source and binary forms, with or without modification, are permitted
     provided that the following conditions are met:
 
     * Redistributions of source code must retain the above copyright notice, this list of conditions
     and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
     and the following disclaimer in the documentation and/or other materials provided with the distribution.
     * Neither the name of Webbo nor the names of its contributors may be used to endorse or promote
     products derived from this software without specific prior written permission.
     
     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
     WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
     PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
     DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
     PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
     OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
     SUCH DAMAGE.
 */

#import "NanoStore.h"
#import "NSFNanoObjectProtocol.h"
#import "NanoStore_Private.h"
#import "NSFNanoStore_Private.h"
#import "NSFNanoEngine_Private.h"
#import "NSFOrderedDictionary.h"

#include <stdlib.h>

@interface NSFNanoStore ()

/** \cond */
@property (nonatomic, strong, readwrite) NSFNanoEngine *nanoStoreEngine;
@property (nonatomic, readwrite) BOOL hasUnsavedChanges;
@property (nonatomic) NSMutableArray *addedObjects;
@property (nonatomic) BOOL isOurTransaction;
@property (nonatomic, assign) sqlite3_stmt *insertDeleteKeysStatement;
@property (nonatomic, assign) sqlite3_stmt *storeValuesStatement;
@property (nonatomic, assign) sqlite3_stmt *storeKeysStatement;
/** \endcond */

@end

@implementation NSFNanoStore

@synthesize nanoStoreEngine;
@synthesize nanoEngineProcessingMode;
@synthesize saveInterval;

// ----------------------------------------------
// Initialization / Cleanup
// ----------------------------------------------

+ (NSFNanoStore *)createStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath
{
    return [[self alloc]initStoreWithType:theType path:thePath];
}

+ (NSFNanoStore *)createAndOpenStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath error:(out NSError **)outError
{
    NSFNanoStore *nanoStore = [[self alloc]initStoreWithType:theType path:thePath];
    [nanoStore openWithError:outError];
    return nanoStore;
}

- (id)initStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath
{
    switch (theType) {
        case NSFMemoryStoreType:
            thePath = NSFMemoryDatabase;
            break;
        case NSFTemporaryStoreType:
            thePath = NSFTemporaryDatabase;
            break;
        default:
                // Do nothing
            break;
    }
    
    if (nil == thePath) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the path cannot be nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    if ((self = [super init])) {
        nanoStoreEngine = [[NSFNanoEngine alloc]initWithPath:[thePath stringByExpandingTildeInPath]];
        if (nil == nanoStoreEngine) {
            _NSFLog([NSString stringWithFormat:@"*** -[%@ %@]: [NSFNanoEngine initWithPath:] failed: %@", [self class], NSStringFromSelector(_cmd), thePath]);
            [self closeWithError:nil];
            return nil;
        }
        
        nanoEngineProcessingMode = NSFEngineProcessingDefaultMode;
        
        _isOurTransaction = NO;
        saveInterval = 1;
        
        _insertDeleteKeysStatement = NULL;
        _storeValuesStatement = NULL;
        _storeKeysStatement = NULL;
        
        _addedObjects = [[NSMutableArray alloc]initWithCapacity:saveInterval];
    }
    
    return self;
}

- (void)dealloc
{
    [self closeWithError:nil];
}

- (NSString *)filePath
{
    return [nanoStoreEngine path];
}

- (BOOL)openWithError:(out NSError **)outError
{
    if ([nanoStoreEngine isDatabaseOpen] == YES)
        return YES;
    
    if ([nanoStoreEngine openWithCacheMethod:CacheAllData useFastMode:(NSFEngineProcessingFastMode == nanoEngineProcessingMode)] == NO) {
        NSString *message = [NSString stringWithFormat:@"*** -[%@ %@]: open database failed: %@", [self class], NSStringFromSelector(_cmd), [self filePath]];
        _NSFLog(message);
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:message
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        [self closeWithError:nil];
        return NO;
    }
    
    if ([self _setupCachingSchema] == NO) {
        NSString *message = [NSString stringWithFormat:@"*** -[%@ %@]: the schema could not be created when opening database: %@", [self class], NSStringFromSelector(_cmd), [self filePath]];
        _NSFLog(message);
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:message
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        [self closeWithError:nil];
        return NO;
    }
    
    if ([self _initializePreparedStatementsWithError:outError] == NO) {
        NSString *message = [NSString stringWithFormat:@"*** -[%@ %@]: the SQL statements could not be prepared when opening database: %@", [self class], NSStringFromSelector(_cmd), [self filePath]];
        _NSFLog(message);
        [self closeWithError:nil];
        return NO;
    }
    
    return YES;
}

- (BOOL)closeWithError:(out NSError **)outError
{
    BOOL success = [self saveStoreAndReturnError:outError];
    [self _releasePreparedStatements];
    [nanoStoreEngine close];
    
    return success;
}

- (BOOL)isClosed
{
    return ([nanoStoreEngine isDatabaseOpen] == NO);
}

- (NSString *)description
{
    return [self JSONDescription];
}

- (NSFOrderedDictionary *)dictionaryDescription
{
    NSFOrderedDictionary *values = [NSFOrderedDictionary new];
    
    values[@"NanoStore address"] = [NSString stringWithFormat:@"%p", self];
    values[@"Is our transaction?"] = (_isOurTransaction ? @"YES" : @"NO");
    values[@"Save interval"] = (saveInterval ? @(saveInterval) : @(1));
    values[@"Engine"] = [nanoStoreEngine dictionaryDescription];
    
    return values;
}

- (NSString *)JSONDescription
{
    NSFOrderedDictionary *values = [self dictionaryDescription];
    
    NSError *outError = nil;
    NSString *description = [NSFNanoObject _NSObjectToJSONString:values error:&outError];
    
    return description;
}

- (BOOL)hasUnsavedChanges
{
    return ([_addedObjects count] > 0);
}

#pragma mark -

- (BOOL)addObject:(id <NSFNanoObjectProtocol>)object error:(out NSError **)outError
{
    NSArray *wrapper = [[NSArray alloc]initWithObjects:object, nil];
    BOOL success = [self addObjectsFromArray:wrapper error:outError];
    return success;
}

- (BOOL)addObjectsFromArray:(NSArray *)someObjects error:(out NSError **)outError
{
    if (nil == someObjects) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: someObjects is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    if ([someObjects count] == 0) {
        if (nil != outError) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: ([someObjects count] == 0)", [self class], NSStringFromSelector(_cmd)]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        }
        return NO;
    }
    
    // Add the regular objects. For bags, redirect it the saving method.
    NSMutableArray *nonBagObjects = [[NSMutableArray alloc]initWithCapacity:[someObjects count]];
    
    for (id object in someObjects) {
        // If it's a bag, make sure the name is unique
        if (YES == [object isKindOfClass:[NSFNanoBag class]]) {
            NSFNanoBag *bag = (NSFNanoBag *)object;
            
            // If it's a bag, process it first by gathering. If it's not dirty, there's no need to save...
            if (YES == [bag hasUnsavedChanges]) {
                NSError *error = nil;
                
                // Associate the bag to this store
                if (nil == [bag store]) {
                    [object _setStore:self];
                }
                
                if (NO == [bag _saveInStore:self error:&error]) {
                    [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                             reason:[NSString stringWithFormat:@"*** -[%@ %@]: %@", [self class], NSStringFromSelector(_cmd), [error localizedDescription]]
                                           userInfo:nil]raise];
                }
            }
        } else {
            if (NO == [(id)object conformsToProtocol:@protocol(NSFNanoObjectProtocol)]) {
                [[NSException exceptionWithName:NSFNonConformingNanoObjectProtocolException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %@]: the object does not conform to NSFNanoObjectProtocol.", [self class], NSStringFromSelector(_cmd)]
                                       userInfo:nil]raise];            
            }
            
            if (nil == [object nanoObjectKey]) {
                [[NSException exceptionWithName:NSFNanoObjectBehaviorException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %@]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], NSStringFromSelector(_cmd)]
                                       userInfo:nil]raise]; 
            }
            
            [nonBagObjects addObject:object];
        }
    }
    
    BOOL success = [self _addObjectsFromArray:nonBagObjects forceSave:NO error:outError];
    
    return success;
}

- (BOOL)removeObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError
{
    NSArray *wrapper = [[NSArray alloc]initWithObjects:theObject, nil];
    BOOL success = [self removeObjectsInArray:wrapper error:outError];
    return success;
}

- (BOOL)removeObjectsWithKeysInArray:(NSArray *)someKeys error:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    if (nil == someKeys)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: someKeys is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSUInteger count = [someKeys count];
    
    if (0 == count)
        return NO;
    
    BOOL transactionStartedHere = [self beginTransactionAndReturnError:nil];
    
    NSString *theSQLStatement = [[NSString alloc]initWithFormat:@"CREATE TEMP TABLE %@(x);", NSF_Private_ToDeleteTableKey];
    [nanoStoreEngine executeSQL:theSQLStatement];
    
    if (NULL == _insertDeleteKeysStatement) {
        theSQLStatement = [[NSString alloc]initWithFormat:@"INSERT INTO %@ VALUES (?);", NSF_Private_ToDeleteTableKey];
        BOOL success = [self _prepareSQLite3Statement:&_insertDeleteKeysStatement theSQLStatement:theSQLStatement];
        if (NO == success) {
            if (nil != outError) {
                *outError = [NSError errorWithDomain:NSFDomainKey
                                                code:NSFNanoStoreErrorKey
                                            userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: failed to prepare _insertDeleteKeysStatement.", [self class], NSStringFromSelector(_cmd)]
                                                                                 forKey:NSLocalizedFailureReasonErrorKey]];
            }
            return NO;
        }
    }
    
    for (NSString *key in someKeys) {
        int status = sqlite3_reset (_insertDeleteKeysStatement);
        if (SQLITE_OK != status) {
            break;
        }
        
        // Bind and execute the statement...
        status = sqlite3_bind_text ( _insertDeleteKeysStatement, 1, [key UTF8String], -1, SQLITE_STATIC);
        
        // Since we're operating with extended result code support, extract the bits
        // and obtain the regular result code
        // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
        
        status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
        
        if (SQLITE_OK == status) {
            [self _executeSQLite3StepUsingSQLite3Statement:_insertDeleteKeysStatement];
        }
    }
    
    _NSFLog(@"          Before removing the keys to be stored from NSFKeys...");
    theSQLStatement = [[NSString alloc]initWithFormat:@"DELETE FROM %@ WHERE %@ IN (SELECT * FROM %@);", NSFKeys, NSFKey, NSF_Private_ToDeleteTableKey];
    [nanoStoreEngine executeSQL:theSQLStatement];
    
    _NSFLog(@"          Before removing the keys to be stored from NSFValues...");
    theSQLStatement = [[NSString alloc]initWithFormat:@"DELETE FROM %@ WHERE %@ IN (SELECT * FROM %@);", NSFValues, NSFKey, NSF_Private_ToDeleteTableKey];
    [nanoStoreEngine executeSQL:theSQLStatement];
    
    _NSFLog(@"          Before DROP TABLE NSF_Private_ToDeleteTableKey...");
    theSQLStatement = [[NSString alloc]initWithFormat:@"DROP TABLE %@;", NSF_Private_ToDeleteTableKey];
    [nanoStoreEngine executeSQL:theSQLStatement];
    
    if (transactionStartedHere)
        if ([self commitTransactionAndReturnError:nil] == NO)
            _NSFLog(@"          Could not commit the transaction.");
    
    return YES;
}

- (BOOL)removeObjectsInArray:(NSArray *)someObjects error:(out NSError **)outError
{
    NSMutableArray *someKeys = [NSMutableArray array];
    
    // Extract the keys from the objects
    for (id object in someObjects) {
        if (NO == [(id)object conformsToProtocol:@protocol(NSFNanoObjectProtocol)]) {
            [[NSException exceptionWithName:NSFNonConformingNanoObjectProtocolException
                                     reason:[NSString stringWithFormat:@"*** -[%@ %@]: the object does not conform to NSFNanoObjectProtocol.", [self class], NSStringFromSelector(_cmd)]
                                   userInfo:nil]raise];  
        } else {
            NSString *objectKey = [(id)object nanoObjectKey];
            if (nil == objectKey) {
                [[NSException exceptionWithName:NSFNanoObjectBehaviorException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %@]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], NSStringFromSelector(_cmd)]
                                       userInfo:nil]raise]; 
            }
            [someKeys addObject:objectKey];
        }
    }
    
    return [self removeObjectsWithKeysInArray:someKeys error:outError];
}

#pragma mark -
#pragma mark Searching
#pragma mark -

- (NSArray *)bags
{
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFKeyedArchive, NSFObjectClass FROM NSFKeys WHERE NSFObjectClass = \"%@\"", NSStringFromClass([NSFNanoBag class])];
    
    return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil]allValues];

}

- (NSFNanoBag *)bagWithName:(NSString *)theName
{
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    
    search.attribute = NSF_Private_NSFNanoBag_Name;
    search.match = NSFEqualTo;
    search.value = theName;
    
    return [[[search searchObjectsWithReturnType:NSFReturnObjects error:nil]allObjects]lastObject];
}

- (NSArray *)bagsWithName:(NSString *)theName
{
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    
    search.attribute = NSF_Private_NSFNanoBag_Name;
    search.match = NSFEqualTo;
    search.value = theName;
    
    return [[search searchObjectsWithReturnType:NSFReturnObjects error:nil]allObjects];
}

- (NSArray *)bagsWithKeysInArray:(NSArray *)someKeys
{
    if ([someKeys count] == 0) {
        return [NSArray array];
    }
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    NSString *quotedString = [NSFNanoSearch _quoteStrings:someKeys joiningWithDelimiter:@","];
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFKeyedArchive, NSFObjectClass FROM NSFKeys WHERE NSFKey IN (%@) AND NSFObjectClass = \"%@\"", quotedString, NSStringFromClass([NSFNanoBag class])];
    
    return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil]allValues];
}

- (NSArray *)bagsContainingObjectWithKey:(NSString *)aKey
{
    if (nil == aKey) {
        return [NSArray array];
    }
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFKeyedArchive, NSFObjectClass FROM NSFKeys WHERE NSFKey IN (SELECT DISTINCT (NSFKEY) FROM NSFValues WHERE NSFValue = \"%@\") AND NSFObjectClass = \"%@\"", aKey, NSStringFromClass([NSFNanoBag class])];
    
    return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil]allValues];
}

- (NSArray *)objectsWithKeysInArray:(NSArray *)someKeys
{
    if ([someKeys count] == 0) {
        return [NSArray array];
    }
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    NSString *quotedString = [NSFNanoSearch _quoteStrings:someKeys joiningWithDelimiter:@","];
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFKeyedArchive, NSFObjectClass FROM NSFKeys WHERE NSFKey IN (%@)", quotedString];
    
    return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil]allValues];
}

- (NSArray *)allObjectClasses
{
    NSFNanoResult *results = [self _executeSQL:@"SELECT DISTINCT(NSFObjectClass) FROM NSFKeys"];
    
    return [results valuesForColumn:@"NSFKeys.NSFObjectClass"];
}

- (NSArray *)objectsOfClassNamed:(NSString *)theClassName
{
    return [self objectsOfClassNamed:theClassName usingSortDescriptors:nil];
}

- (NSArray *)objectsOfClassNamed:(NSString *)theClassName usingSortDescriptors:(NSArray *)theSortDescriptors
{
    if (nil == theClassName) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the class name cannot be nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    search.sort = theSortDescriptors;
    
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFKeyedArchive, NSFObjectClass FROM NSFKeys WHERE NSFObjectClass = \"%@\"", theClassName];
    
    if (nil == theSortDescriptors) 
        return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil] allValues];
    else
        return [search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil];
}

- (long long)countOfObjectsOfClassNamed:(NSString *)theClassName
{
    if (nil == theClassName) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the class name cannot be nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT count(*) FROM NSFKeys WHERE NSFObjectClass = \"%@\"", theClassName];
    NSFNanoResult *results = [search executeSQL:theSQLStatement];
    
    return [[results firstValue]longLongValue];
}

#pragma mark -
#pragma mark Database Optimizations and Maintenance
#pragma mark -

- (BOOL)beginTransactionAndReturnError:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    if ([self _isOurTransaction] == YES)
        return NO;
    
    [self _setIsOurTransaction:[[self nanoStoreEngine]beginTransaction]];
    
    return [self _isOurTransaction];
}

- (BOOL)commitTransactionAndReturnError:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    if ([self _isOurTransaction] == YES) {
        if ([[self nanoStoreEngine]commitTransaction] == YES) {
            [self _setIsOurTransaction:NO];
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)rollbackTransactionAndReturnError:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    if ([self _isOurTransaction] == YES) {
        [[self nanoStoreEngine]rollbackTransaction];
        [self _setIsOurTransaction:NO];
        return YES;
    }
    
    return NO;
}

#pragma mark -

// ----------------------------------------------
// Store/save unsaved objects
// ----------------------------------------------

- (BOOL)saveStoreAndReturnError:(out NSError **)outError
{
    // We are really not saving anything new, just indicating that we should commit the unsaved changes.
    if (NO == self.hasUnsavedChanges) {
        return YES;
    }
    
    return [self _addObjectsFromArray:[NSArray array] forceSave:YES error:outError];
}

- (void)discardUnsavedChanges
{
    [_addedObjects removeAllObjects];
}

// ----------------------------------------------
// Clearing the store
// ----------------------------------------------

- (BOOL)removeAllObjectsFromStoreAndReturnError:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    NSError *resultKeys = [[self _executeSQL:[NSString stringWithFormat:@"DROP TABLE %@", NSFKeys]]error];
    NSError *resultValues = [[self _executeSQL:[NSString stringWithFormat:@"DROP TABLE %@", NSFValues]]error];
    
    [self _setupCachingSchema];
    
    [self rebuildIndexesAndReturnError:nil];
    
    if ((nil != resultKeys) || (nil != resultValues)) {
        if (nil != outError) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:@"Could not remove all objects from the database."
                                                                             forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
    
    return YES;
}

// ----------------------------------------------
// Compacting the database
// ----------------------------------------------

- (BOOL)compactStoreAndReturnError:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    return [[self nanoStoreEngine]compact];
}

- (BOOL)clearIndexesAndReturnError:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    NSArray *indexes = [[self nanoStoreEngine]indexes];
    
    _NSFLog(@"Before clearIndexes...");
    NSDate *startDate = [NSDate date];
    
    for (NSString *index in indexes)
        [[self nanoStoreEngine]dropIndex:index];
    
    NSTimeInterval seconds = [[NSDate date]timeIntervalSinceDate:startDate];    
    _NSFLog(@"Done. Clearing the indexes took %.3f seconds", seconds);
    
    return YES;
}

- (BOOL)rebuildIndexesAndReturnError:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    // Force the indexes to be dropped
    [self clearIndexesAndReturnError:nil];
    
    _NSFLog(@"Before rebuildIndexes...");
    NSDate *startDate = [NSDate date];
    
    _NSFLog(@"     [[self nanoStoreEngine]createIndexForColumn: NSFKey table: NSFValues isUnique:NO]: %@", [[self nanoStoreEngine]createIndexForColumn:NSFKey table:NSFValues isUnique:NO] ? @"YES" : @"NO");
    _NSFLog(@"     [[self nanoStoreEngine]createIndexForColumn: NSFAttribute table: NSFValues isUnique:NO]: %@", [[self nanoStoreEngine]createIndexForColumn:NSFAttribute table:NSFValues isUnique:NO] ? @"YES" : @"NO");
    _NSFLog(@"     [[self nanoStoreEngine]createIndexForColumn: NSFValue table: NSFValues isUnique:NO]: %@", [[self nanoStoreEngine]createIndexForColumn:NSFValue table:NSFValues isUnique:NO] ? @"YES" : @"NO");
    
    _NSFLog(@"     [[self nanoStoreEngine]createIndexForColumn: NSFKey table: NSFKeys isUnique:YES]: %@", [[self nanoStoreEngine]createIndexForColumn:NSFKey table:NSFKeys isUnique:YES] ? @"YES" : @"NO");
    _NSFLog(@"     [[self nanoStoreEngine]createIndexForColumn: NSFCalendarDate table: NSFKeys isUnique:NO]: %@", [[self nanoStoreEngine]createIndexForColumn:NSFCalendarDate table:NSFKeys isUnique:NO] ? @"YES" : @"NO");
    _NSFLog(@"     [[self nanoStoreEngine]createIndexForColumn: NSFObjectClass table: NSFKeys isUnique:NO]: %@", [[self nanoStoreEngine]createIndexForColumn:NSFObjectClass table:NSFKeys isUnique:NO] ? @"YES" : @"NO");

    NSTimeInterval seconds = [[NSDate date]timeIntervalSinceDate:startDate];    
    _NSFLog(@"Done. Rebuilding the indexes took %.3f seconds", seconds);
    
    return YES;
}

- (BOOL)saveStoreToDirectoryAtPath:(NSString *)path compactDatabase:(BOOL)compact error:(out NSError **)outError
{
    if (nil == path)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: path is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    // Make sure we've expanded the tilde
    path = [path stringByExpandingTildeInPath];
    
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    if ([[self nanoStoreEngine]isTransactionActive]) {
        if (nil != outError) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:@"Cannot backup store. A transaction is still open."
                                                                             forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
    
    if ([[self filePath]isEqualToString:NSFMemoryDatabase] == YES) {
        return [self _backupMemoryStoreToDirectoryAtPath:path extension:nil compact:compact error:outError];
    } else {
        return [self _backupFileStoreToDirectoryAtPath:path extension:nil compact:compact error:outError];
    }
    
    return NO;
}

#pragma mark - Private Methods
#pragma mark -

/** \cond */

+ (NSFNanoStore *)_createAndOpenDebugDatabase
{
    NSFNanoStore *db =  [NSFNanoStore createStoreWithType:NSFPersistentStoreType path:[@"~/Desktop/NanoStoreDebug.sqlite" stringByExpandingTildeInPath]];
    NSError *outError = nil;
    
    if (NO == [db openWithError:&outError]) {
        [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: could not open the database. Reason: %@", [self class], NSStringFromSelector(_cmd), [outError localizedDescription]]
                               userInfo:nil]raise];
    }
    
    return db;
}

- (NSFNanoResult *)_executeSQL:(NSString *)theSQLStatement
{
    if (nil == theSQLStatement)
        return nil;
    
    return [[self nanoStoreEngine]executeSQL:theSQLStatement];
}

- (BOOL)_initializePreparedStatementsWithError:(out NSError **)outError
{
    BOOL hasInitializationSucceeded = YES;
    
    if (NULL == _storeValuesStatement) {
        NSString *theSQLStatement = [[NSString alloc]initWithFormat:@"INSERT INTO %@(%@, %@, %@, %@) VALUES (?,?,?,?);", NSFValues, NSFKey, NSFAttribute, NSFValue, NSFDatatype];
        hasInitializationSucceeded = [self _prepareSQLite3Statement:&_storeValuesStatement theSQLStatement:theSQLStatement];
        
        if (NO == hasInitializationSucceeded) {
            if (nil != outError) {
                *outError = [NSError errorWithDomain:NSFDomainKey
                                                code:NSFNanoStoreErrorKey
                                            userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: failed to prepare _storeValuesStatement.", [self class], NSStringFromSelector(_cmd)]
                                                                                 forKey:NSLocalizedFailureReasonErrorKey]];
            }
            return NO;
        }
    }
    
    if (NULL == _storeKeysStatement) {
        NSString *theSQLStatement = [[NSString alloc]initWithFormat:@"INSERT INTO %@(%@, %@, %@, %@) VALUES (?,?,?,?);", NSFKeys, NSFKey, NSFKeyedArchive, NSFCalendarDate, NSFObjectClass];
        hasInitializationSucceeded = [self _prepareSQLite3Statement:&_storeKeysStatement theSQLStatement:theSQLStatement];
        
        if (NO == hasInitializationSucceeded) {
            if (nil != outError) {
                *outError = [NSError errorWithDomain:NSFDomainKey
                                                code:NSFNanoStoreErrorKey
                                            userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: failed to prepare _storeKeysStatement.", [self class], NSStringFromSelector(_cmd)]
                                                                                 forKey:NSLocalizedFailureReasonErrorKey]];
            }
            return NO;
        }
    }
    
    return YES;
}

- (void)_releasePreparedStatements
{
    if (_insertDeleteKeysStatement != NULL) { sqlite3_finalize(_insertDeleteKeysStatement);_insertDeleteKeysStatement = NULL; }
    if (_storeValuesStatement != NULL) { sqlite3_finalize(_storeValuesStatement);_storeValuesStatement = NULL; }
    if (_storeKeysStatement != NULL) { sqlite3_finalize(_storeKeysStatement);_storeKeysStatement = NULL; }
}

- (void)_setIsOurTransaction:(BOOL)value
{
    if (_isOurTransaction != value) {
        _isOurTransaction = value;
    }
}

- (BOOL)_isOurTransaction
{
    return _isOurTransaction;
}

- (BOOL)_checkNanoStoreIsReadyAndReturnError:(out NSError **)outError
{
    if (nil == [self nanoStoreEngine]) {
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: the NSF store has not been set.", [self class], NSStringFromSelector(_cmd)]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        return NO;
    }
    
    if ([[self nanoStoreEngine]isDatabaseOpen] == NO) {
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: the store is not open.", [self class], NSStringFromSelector(_cmd)]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        return NO;
    }
    
    return YES;
}

- (BOOL)_setupCachingSchema
{
    NSString *theSQLStatement;
    BOOL success;
    NSArray *tables = [[self nanoStoreEngine]tables];
    NSString *rowUIDDatatype = NSFStringFromNanoDataType(NSFNanoTypeRowUID);
    NSString *stringDatatype = NSFStringFromNanoDataType(NSFNanoTypeString);
    NSString *dateDatatype = NSFStringFromNanoDataType(NSFNanoTypeDate);

    // Setup the Values table
    if ([tables containsObject:NSFValues] == NO) {
        theSQLStatement = [NSString stringWithFormat:@"CREATE TABLE %@(ROWID INTEGER PRIMARY KEY, %@ TEXT, %@ TEXT, %@ NONE, %@ TEXT);", NSFValues, NSFKey, NSFAttribute, NSFValue, NSFDatatype];
        success = (nil == [[[self nanoStoreEngine]executeSQL:theSQLStatement]error]);
        if (NO == success)
            return NO;
        
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFValues, NSFRowIDColumnName, rowUIDDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFValues, NSFKey, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFValues, NSFAttribute, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFValues, NSFValue, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFValues, NSFDatatype, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
    }
    
    // Setup the Plist table
    if ([tables containsObject:NSFKeys] == NO) {
        theSQLStatement = [NSString stringWithFormat:@"CREATE TABLE %@(ROWID INTEGER PRIMARY KEY, %@ TEXT, %@ BLOB, %@ TEXT, %@ TEXT);", NSFKeys, NSFKey, NSFKeyedArchive, NSFCalendarDate, NSFObjectClass];

        success = (nil == [[[self nanoStoreEngine]executeSQL:theSQLStatement]error]);
        if (NO == success)
            return NO;
        
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, NSFRowIDColumnName, rowUIDDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, NSFKey, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, NSFKeyedArchive, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, dateDatatype, dateDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];        
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, NSFObjectClass, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
    }
    
    return YES;
}

- (BOOL)_storeDictionary:(NSDictionary *)someInfo forKey:(NSString *)aKey forClassNamed:(NSString *)classType error:(out NSError **)outError
{
    if (nil == someInfo)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: someInfo is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == aKey)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: aKey is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (NULL == _storeValuesStatement)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: aStatement is NULL.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSRange range = [aKey rangeOfString:@"."];
    if (NSNotFound != range.location)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: aKey cannot contain a period ('.')", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSArray *keys = [someInfo allKeys];
    for (NSString *key in keys) {
        range = [key rangeOfString:@"."];
        if (NSNotFound != range.location)
            [[NSException exceptionWithName:NSFUnexpectedParameterException
                                     reason:[NSString stringWithFormat:@"*** -[%@ %@]: the keys of the dictionary cannot contain a period ('.')", [self class], NSStringFromSelector(_cmd)]
                                   userInfo:nil]raise];
    }
    
    const char *aKeyUTF8 = [aKey UTF8String];
    BOOL success = YES;
    
    // Flatten the dictionary
    {
        NSMutableArray *flattenedKeys = [NSMutableArray new];
        NSMutableArray *flattenedValues = [NSMutableArray new];
        
        @autoreleasepool {
            [self _flattenCollection:someInfo keys:&flattenedKeys values:&flattenedValues];
            
            NSUInteger i, count = [flattenedKeys count];
            
            success = NO;
            
            for (i = 0; i < count; i++) {
                NSString *attribute = [flattenedKeys objectAtIndex:i];
                id value = [flattenedValues objectAtIndex:i];
                
                // Reset, as required by SQLite...
                int status = sqlite3_reset (_storeValuesStatement);
                
                // Since we're operating with extended result code support, extract the bits
                // and obtain the regular result code
                // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
                
                status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
                
                if (SQLITE_OK == status) {
                    
                    // Bind and execute the statement...
                    BOOL resultBindKey = (sqlite3_bind_text (_storeValuesStatement, 1, aKeyUTF8, -1, SQLITE_STATIC) == SQLITE_OK);
                    BOOL resultBindAttribute = (sqlite3_bind_text (_storeValuesStatement, 2, [attribute UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                    
                    // Take advantage of manifest typing
                    // Branch the type of bind based on the type to be stored: NSString, NSData, NSDate or NSNumber
                    NSFNanoDatatype valueDataType = [self _NSFDatatypeOfObject:value];
                    BOOL resultBindValue = NO;
                    
                    switch (valueDataType) {
                        case NSFNanoTypeData:
                            resultBindValue = (sqlite3_bind_blob(_storeValuesStatement, 3, [value bytes], (int)[value length], NULL) == SQLITE_OK);
                            break;
                        case NSFNanoTypeString:
                        case NSFNanoTypeDate:
                            resultBindValue = (sqlite3_bind_text (_storeValuesStatement, 3, [[self _stringFromValue:value]UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                            break;
                            break;
                        case NSFNanoTypeNumber:
                            resultBindValue = (sqlite3_bind_double (_storeValuesStatement, 3, [value doubleValue]) == SQLITE_OK);
                            break;
                        case NSFNanoTypeNULL:
                            resultBindValue = (sqlite3_bind_null(_storeValuesStatement, 3) == SQLITE_OK);
                            break;
                        case NSFNanoTypeURL:
                            resultBindValue = (sqlite3_bind_text (_storeValuesStatement, 3, [[self _stringFromValue:value]UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                            break;
                        default:
                            [[NSException exceptionWithName:NSFUnexpectedParameterException
                                                     reason:[NSString stringWithFormat:@"*** -[%@ %@]: datatype %@ cannot be stored because its class type is unknown.", [self class], NSStringFromSelector(_cmd), [value class]]
                                                   userInfo:nil]raise];
                            break;
                    }
                    
                    // Store the element's datatype so we can recreate it later on when we read it back from the store...
                    NSString *valueDatatypeString = NSFStringFromNanoDataType(valueDataType);
                    BOOL resultBindDatatype = (sqlite3_bind_text (_storeValuesStatement, 4, [valueDatatypeString UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                    
                    success = (resultBindKey && resultBindAttribute && resultBindValue && resultBindDatatype);
                    if (success) {
                        [self _executeSQLite3StepUsingSQLite3Statement:_storeValuesStatement];
                    }
                }
            }
            
        }
    }
    
    if (YES == success) {
        NSData *dictBinData = [NSKeyedArchiver archivedDataWithRootObject:someInfo];
        {
            int status = sqlite3_reset (_storeKeysStatement);
            
            // Since we're operating with extended result code support, extract the bits
            // and obtain the regular result code
            // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
            
            status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
            
            // Bind and execute the statement...
            if (SQLITE_OK == status) {
                
                BOOL resultBindKey = (sqlite3_bind_text (_storeKeysStatement, 1, aKeyUTF8, -1, SQLITE_STATIC) == SQLITE_OK);
                BOOL resultBindData = (sqlite3_bind_blob(_storeKeysStatement, 2, [dictBinData bytes], (int)[dictBinData length], SQLITE_STATIC) == SQLITE_OK);
                BOOL resultBindCalendarDate = (sqlite3_bind_text (_storeKeysStatement, 3, [[NSFNanoStore _calendarDateToString:[NSDate date]]UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                BOOL resultBindClass = (sqlite3_bind_text (_storeKeysStatement, 4, [classType UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                
                success = (resultBindKey && resultBindData && resultBindCalendarDate && resultBindClass);
                if (success) {
                    [self _executeSQLite3StepUsingSQLite3Statement:_storeKeysStatement];
                }
            }
        }
    }
    
    return success;
}

- (NSFNanoDatatype)_NSFDatatypeOfObject:(id)value
{
    NSFNanoDatatype type = NSFNanoTypeUnknown;
    
    if ([value isKindOfClass:[NSString class]])
        return NSFNanoTypeString;
    else if ([value isKindOfClass:[NSNumber class]])
        return NSFNanoTypeNumber;
    else if ([value isKindOfClass:[NSDate class]])
        return NSFNanoTypeDate;
    else if ([value isKindOfClass:[NSData class]])
        return NSFNanoTypeData;
    else if ([value isKindOfClass:[NSNull class]])
        return NSFNanoTypeNULL;
    else if ([value isKindOfClass:[NSURL class]])
        return NSFNanoTypeURL;
    
    return type;
}

- (NSString *)_stringFromValue:(id)aValue
{
    if (nil != aValue) {
        if ([aValue isKindOfClass:[NSString class]]) {
            return aValue;
        } else if ([aValue isKindOfClass:[NSDate class]]) {
            return [NSFNanoStore _calendarDateToString:aValue];
        } else if ([aValue respondsToSelector:@selector(stringValue)]) {
            return [aValue stringValue];
        } else if ([aValue respondsToSelector:@selector(description)]) {
            return [aValue description];
        } else {
            [[NSException exceptionWithName:NSFUnexpectedParameterException
                                     reason:[NSString stringWithFormat:@"*** -[%@ %@]: datatype %@ doesn't respond to selector 'stringValue' or 'description'.", [self class], NSStringFromSelector(_cmd), [aValue class]]
                                   userInfo:nil]raise];
        }
    }
    
    return [[NSNull null]description];
}

+ (NSString *)_calendarDateToString:(NSDate *)aDate
{
    static NSDateFormatter *__sNSFNanoStoreDateFormatter = nil;
    if (nil == __sNSFNanoStoreDateFormatter) {
        __sNSFNanoStoreDateFormatter = [NSDateFormatter new];
        [__sNSFNanoStoreDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [__sNSFNanoStoreDateFormatter setTimeStyle:NSDateFormatterFullStyle];
        [__sNSFNanoStoreDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss:SSS"]; 
    }
    
    if (nil == aDate)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: aDate is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    return [__sNSFNanoStoreDateFormatter stringFromDate:aDate];
}

- (void)_flattenCollection:(NSDictionary *)info keys:(NSMutableArray **)flattenedKeys values:(NSMutableArray **)flattenedValues
{
    NSMutableArray *keyPath = [NSMutableArray new];
    [self _flattenCollection:info keyPath:&keyPath keys:flattenedKeys values:flattenedValues];
}

- (void)_flattenCollection:(id)someObject keyPath:(NSMutableArray **)aKeyPath keys:(NSMutableArray **)flattenedKeys values:(NSMutableArray **)flattenedValues
{
    BOOL isOfTypeCollection = ([someObject isKindOfClass:[NSDictionary class]] || [someObject isKindOfClass:[NSArray class]]);

    if (NO == isOfTypeCollection) {
        if (nil != flattenedKeys) {
            NSString *keyPath = [*aKeyPath componentsJoinedByString:@"."];
            [*flattenedKeys addObject:keyPath];
            [*flattenedValues addObject:someObject];
        }
    } else {
        if ([someObject isKindOfClass:[NSDictionary class]]) {
            for (NSString *key in someObject) {
                [*aKeyPath addObject:key];
                [self _flattenCollection:[someObject objectForKey:key] keyPath:aKeyPath keys:flattenedKeys values:flattenedValues];
                [*aKeyPath removeLastObject];
            }
        } else if ([someObject isKindOfClass:[NSArray class]]) {
            for (id anObject in someObject) {
                [self _flattenCollection:anObject keyPath:aKeyPath keys:flattenedKeys values:flattenedValues];
            }
        }
    }
}

- (BOOL)_prepareSQLite3Statement:(sqlite3_stmt **)aStatement theSQLStatement:(NSString *)aSQLQuery
{
    // Prepare SQLite's VM. It's placed here so we can speed up stores...
    sqlite3* sqliteDatabase = [[self nanoStoreEngine]sqlite];
    int status = SQLITE_OK;
    BOOL continueLooping = YES;
    const char *query = [aSQLQuery UTF8String];
    
    do {
        status = sqlite3_prepare_v2(sqliteDatabase, query, (int)strlen(query), aStatement, &query);
        
        // Since we're operating with extended result code support, extract the bits
        // and obtain the regular result code
        // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
        
        status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
        
        continueLooping = ((SQLITE_LOCKED == status) || (SQLITE_BUSY == status));
    } while (continueLooping);
    
    return (SQLITE_OK == status);
}

- (void)_executeSQLite3StepUsingSQLite3Statement:(sqlite3_stmt *)aStatement
{
    BOOL waitingForRow = YES;
    
    do {
        int status = sqlite3_step(aStatement);
        
        // Since we're operating with extended result code support, extract the bits
        // and obtain the regular result code
        // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
        
        status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
        
        switch (status) {
            case SQLITE_BUSY:
                break;
            case SQLITE_OK:
            case SQLITE_DONE:
                waitingForRow = NO;
                break;
            case SQLITE_ROW:
                waitingForRow = NO;
                break;
            default:
                waitingForRow = NO;
                break;
        }
    } while (waitingForRow);
}

- (BOOL)_addObjectsFromArray:(NSArray *)someObjects forceSave:(BOOL)forceSave error:(out NSError **)outError
{
    // Collect the objects
    [_addedObjects addObjectsFromArray:someObjects];
    
    // No need to continue if there's nothing to be saved
    NSUInteger unsavedObjectsCount = [_addedObjects count];
    if (0 == unsavedObjectsCount) {
        return YES;
    }
    
    if ((YES == forceSave) || (0 == unsavedObjectsCount % saveInterval)) {
        NSDate *startStoringDate = [NSDate date];
        
        NSDate *startRemovingDate = [NSDate date];
        _NSFLog(@"     Removing the objects to be stored...");
        NSMutableSet *keys = [NSMutableSet new];
        NSInteger i = unsavedObjectsCount;
        
        // Remove all objects non conforming with the NSFNanoObjectProtocol
        while ( i-- ) {
            id object = [_addedObjects objectAtIndex:i];
            if (NO == [object conformsToProtocol:@protocol(NSFNanoObjectProtocol)]) {
                [_addedObjects removeObjectAtIndex:i];
                i--;
                continue;
            }
            
            NSString *objectKey = [(id)object nanoObjectKey];
            if (nil == objectKey) {
                [[NSException exceptionWithName:NSFNanoObjectBehaviorException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %@]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], NSStringFromSelector(_cmd)]
                                       userInfo:nil]raise]; 
            }
            [keys addObject:objectKey];
        }
        
        // Recalculate how many elements we have left
        unsavedObjectsCount = [_addedObjects count];
        
        if (unsavedObjectsCount > 0) {
            NSError *localOutError = nil;
            if (NO == [self removeObjectsWithKeysInArray:[keys allObjects] error:&localOutError]) {
                [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %@]: %@", [self class], NSStringFromSelector(_cmd), [localOutError localizedDescription]]
                                       userInfo:nil]raise];
            }
        }
        
        NSTimeInterval secondsRemoving = [[NSDate date]timeIntervalSinceDate:startRemovingDate];    
        _NSFLog(@"     Done. Removing the objects took %.3f seconds", secondsRemoving);
        
        // Store the objects...
        BOOL transactionStartedHere = [self beginTransactionAndReturnError:nil];
        
        _NSFLog(@"     Storing %ld objects...", unsavedObjectsCount);
        
        // Reset the default save interval if needed...
        if (0 == saveInterval) {
            self.saveInterval = 1;
        }
        
        NSString *errorMessage = @"<error reason unknown>";
        
        for (id object in _addedObjects) {
            @autoreleasepool {
                // If the object was originally created by storing a class not recognized by this process, honor it and store it with the right class string.
                NSString *className = nil;
                if (YES == [object respondsToSelector:@selector(originalClassString)]) {
                    className = [object originalClassString];
                }
                
                // Otherwise, just save the class name of the object being stored
                if (nil == className) {
                    className = NSStringFromClass([object class]);
                }
                
                if (NO == [self _storeDictionary:[object nanoObjectDictionaryRepresentation] forKey:[(id)object nanoObjectKey] forClassNamed:className error:outError]) {
                    if (nil != outError) errorMessage = [*outError localizedDescription];
                    [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                             reason:[NSString stringWithFormat:@"*** -[%@ %@]: %@", [self class], NSStringFromSelector(_cmd), errorMessage]
                                           userInfo:nil]raise];
                } else {
                    SEL setStoreSelector = @selector(setStore:);
                    if (YES == [object respondsToSelector:setStoreSelector]) {
                        #pragma clang diagnostic push
                        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [object performSelector:setStoreSelector withObject:self];
                        #pragma clang diagnostic pop
                    }
                }
                
                i++;
                
                // Commit every 'saveInterval' interations...
                if ((0 == i % self.saveInterval) && transactionStartedHere) {
                    if (NO == [self commitTransactionAndReturnError:outError]) {
                        if (nil != outError) errorMessage = [*outError localizedDescription];
                        [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: %@", [self class], NSStringFromSelector(_cmd), errorMessage]
                                               userInfo:nil]raise];
                    }
                    
                    if (YES == transactionStartedHere) {
                        transactionStartedHere = [self beginTransactionAndReturnError:outError];
                        if (NO == transactionStartedHere) {
                            if (nil != outError) errorMessage = [*outError localizedDescription];
                            [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                                     reason:[NSString stringWithFormat:@"*** -[%@ %@]: %@", [self class], NSStringFromSelector(_cmd), errorMessage]
                                                   userInfo:nil]raise];
                        }
                    }
                }
            }
        }
        
        // Commit the changes
        if (transactionStartedHere) {
            if (NO == [self commitTransactionAndReturnError:outError]) {
                if (nil != outError) errorMessage = [*outError localizedDescription];
                [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %@]: %@", [self class], NSStringFromSelector(_cmd), errorMessage]
                                       userInfo:nil]raise];
            }
        }
        
        NSTimeInterval secondsStoring = [[NSDate date]timeIntervalSinceDate:startStoringDate];
        double ratio = unsavedObjectsCount/secondsStoring;
        _NSFLog(@"     Done. Storing the objects took %.3f seconds (%.0f keys/sec.)", secondsStoring, ratio);
        
        [_addedObjects removeAllObjects];
    }
    
    return YES;
}

+ (NSDictionary *)_defaultTestData
{
    NSArray *dishesInfo = [NSArray arrayWithObject:@"Cassoulet"];
    NSDictionary *citiesInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Bouillabaisse", @"Marseille",
                                dishesInfo, @"Nice",
                                @"Good", @"Rating",
                                nil, nil];
    NSDictionary *countriesInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"Barcelona", @"Spain",
                                   @"San Francisco", @"USA",
                                   citiesInfo, @"France",
                                   @"Very Good", @"Rating",
                                   nil, nil];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Tito", @"FirstName",
                          @"Ciuro", @"LastName",
                          countriesInfo, @"Countries",
                          [NSNumber numberWithUnsignedInt:(arc4random() % 32767) + 1], @"SomeNumber",
                          @"To be decided", @"Rating",
                          nil, nil];
    
    return info;
}

// ----------------------------------------------
// Backup the store to a specific location
// ----------------------------------------------

- (BOOL)_backupFileStoreToDirectoryAtPath:(NSString *)backupPath extension:(NSString *)anExtension compact:(BOOL)flag error:(out NSError **)outError
{
    NSString *filePath = [self filePath];
    if ((anExtension != nil) && (NO == [backupPath hasSuffix:anExtension]))
        backupPath = [NSString stringWithFormat:@"%@.%@", backupPath, anExtension];
    
    // Make sure we the destination path is not the same as the source!
    if (YES == [filePath isEqualToString:backupPath]) {
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:@"Cannot backup store. The source and destination directories are the same."
                                                                             forKey:NSLocalizedDescriptionKey]];
        return NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL destinationLocationIsClear = YES;
    
    if (YES == [fm fileExistsAtPath:backupPath]) {
        destinationLocationIsClear = [fm removeItemAtPath:backupPath error:nil];
        if (NO == destinationLocationIsClear) {
            if (nil != outError)
                *outError = [NSError errorWithDomain:NSFDomainKey
                                                code:NSF_Private_MacOSXErrorCodeKey
                                            userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Existing file couldn't be removed in path: %@. Backup cannot proceed.", backupPath]
                                                                                 forKey:NSLocalizedDescriptionKey]];
            return NO;
        }
    }
    
    if (flag)
        // First compact the store
        [self compactStoreAndReturnError:outError];
    
    // Try to copy the file to the destination
    if ([fm fileExistsAtPath:filePath]) {
        [fm copyItemAtPath:filePath toPath:backupPath error:outError];
    } else {
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSF_Private_MacOSXErrorCodeKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"File doesn't exist at path: %@", filePath]
                                                                             forKey:NSLocalizedDescriptionKey]];
        return NO;
    }
    
    return YES;
}

- (BOOL)_backupMemoryStoreToDirectoryAtPath:(NSString *)backupPath extension:(NSString *)anExtension compact:(BOOL)flag error:(out NSError **)outError
{
    NSString *filePath = [self filePath];
    if ((anExtension != nil) && (NO == [backupPath hasSuffix:anExtension])) {
        backupPath = [NSString stringWithFormat:@"%@.%@", backupPath, anExtension];
    }
    
    // Make sure we the destination path is not the same as the source!
    if (YES == [filePath isEqualToString:backupPath]) {
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:@"Cannot backup store. The source and destination directories are the same."
                                                                             forKey:NSLocalizedDescriptionKey]];
        return NO;
    }
    
    if (flag) {
        // First compact the store
        [self compactStoreAndReturnError:outError];
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL destinationLocationIsClear = YES;
    
    if (YES == [fm fileExistsAtPath:backupPath]) {
        destinationLocationIsClear = [fm removeItemAtPath:backupPath error:nil];
        if (NO == destinationLocationIsClear) {
            if (nil != outError)
                *outError = [NSError errorWithDomain:NSFDomainKey
                                                code:NSF_Private_MacOSXErrorCodeKey
                                            userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Existing file couldn't be removed in path: %@. Backup cannot proceed.", backupPath]
                                                                                 forKey:NSLocalizedDescriptionKey]];
            return NO;
        }
    }
    
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSFNanoEngine stringWithUUID]];
    
    NSFNanoStore *fileDB = [NSFNanoStore createStoreWithType:NSFPersistentStoreType path:tempPath];
    if (NO == [fileDB openWithError:outError])
        return NO;
    
    // Attach the file-based database to the memory-based one
    NSString *theSQLStatement = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS fileDB", [fileDB filePath]];
    [self _executeSQL:theSQLStatement];
    
    // Transfer the NSFKeys table
    NSString *columns = [[[self nanoStoreEngine]columnsForTable:NSFKeys]componentsJoinedByString:@", "];
    theSQLStatement = [NSString stringWithFormat:@"INSERT INTO fileDB.%@ (%@) SELECT * FROM main.%@", NSFKeys, columns, NSFKeys];
    [self _executeSQL:theSQLStatement];
    
    // Transfer the NSFValues table
    columns = [[[self nanoStoreEngine]columnsForTable:NSFValues]componentsJoinedByString:@", "];
    theSQLStatement = [NSString stringWithFormat:@"INSERT INTO fileDB.%@ (%@) SELECT * FROM main.%@", NSFValues, columns, NSFValues];
    [self _executeSQL:theSQLStatement];
    
    // Safely detach the file-based database
    [self _executeSQL:@"DETACH DATABASE fileDB"];
    
    // We can now close the database
    [fileDB closeWithError:outError];
    
    // Move the file to the specified destination
    return [fm moveItemAtPath:tempPath toPath:backupPath error:outError];
}

/** \endcond */

@end