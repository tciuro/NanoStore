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

#include <stdlib.h>

@implementation NSFNanoStore

@synthesize nanoStoreEngine;
@synthesize nanoEngineProcessingMode;
@synthesize saveInterval;

// ----------------------------------------------
// Initialization / Cleanup
// ----------------------------------------------

+ (NSFNanoStore *)createStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath
{
    return [[[self alloc]initStoreWithType:theType path:thePath]autorelease];
}

+ (NSFNanoStore *)createAndOpenStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath error:(out NSError **)outError
{
    NSFNanoStore *nanoStore = [[[self alloc]initStoreWithType:theType path:thePath]autorelease];
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
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: the path cannot be nil.", [self class], _cmd]
                               userInfo:nil]raise];
    }
    
    if ((self = [super init])) {
        nanoStoreEngine = [[NSFNanoEngine alloc]initWithPath:[thePath stringByExpandingTildeInPath]];
        if (nil == nanoStoreEngine) {
            _NSFLog([NSString stringWithFormat:@"*** -[%@ %s]: [NSFNanoEngine initWithPath:] failed: %@", [self class], _cmd, thePath]);
            [self closeWithError:nil];
            [self release];
            return nil;
        }
        
        nanoEngineProcessingMode = NSFEngineProcessingDefaultMode;
        
        _isOurTransaction = NO;
        saveInterval = 1;
        
        _storeValuesStatement = NULL;
        _storeKeysStatement = NULL;
        
        addedObjects = [[NSMutableArray alloc]initWithCapacity:saveInterval];
    }
    
    return self;
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
        NSString *message = [NSString stringWithFormat:@"*** -[%@ %s]: open database failed: %@", [self class], _cmd, [self filePath]];
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
        NSString *message = [NSString stringWithFormat:@"*** -[%@ %s]: the schema could not be created when opening database: %@", [self class], _cmd, [self filePath]];
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
        NSString *message = [NSString stringWithFormat:@"*** -[%@ %s]: the SQL statements could not be prepared when opening database: %@", [self class], _cmd, [self filePath]];
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

- (NSString*)description
{
    return [self _nestedDescriptionWithPrefixedSpace:@""];
}

- (BOOL)hasUnsavedChanges
{
    return ([addedObjects count] > 0);
}

#pragma mark -

- (BOOL)addObject:(id <NSFNanoObjectProtocol>)object error:(out NSError **)outError
{
    NSArray *wrapper = [[NSArray alloc]initWithObjects:object, nil];
    BOOL success = [self addObjectsFromArray:wrapper error:outError];
    [wrapper release];
    return success;
}

- (BOOL)addObjectsFromArray:(NSArray *)someObjects error:(out NSError **)outError
{
    if (nil == someObjects) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: someObjects is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    }
    
    if ([someObjects count] == 0) {
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %s]: ([someObjects count] == 0)", [self class], _cmd]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        return NO;
    }
    
    // Add the regular objects. For bags, redirect it the saving method.
    NSMutableArray *nonBagObjects = [[NSMutableArray alloc]initWithCapacity:[someObjects count]];
    
    for (id object in someObjects) {
        // If it's a bag, make sure the name is unique
        if (YES == [object isKindOfClass:[NSFNanoBag class]]) {
            NSFNanoBag *bag = (NSFNanoBag *)object;
            NSString *bagName = bag.name;
            if (bagName.length > 0) {
                NSFNanoBag *bagWithSameName = [self bagWithName:bagName];
                if (nil != bagWithSameName) {
                    if (nil != outError) {
                        *outError = [NSError errorWithDomain:NSFDomainKey
                                                        code:NSFNanoStoreErrorKey
                                                    userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %s]: a bag named '%@' already exists.", [self class], _cmd, bagName]
                                                                                         forKey:NSLocalizedFailureReasonErrorKey]];
                        
                        // Cleanup before we return
                        [nonBagObjects release];
                        
                        return NO;
                    }
                }
            }
            
            
            // If it's a bag, process it first by gathering. If it's not dirty, there's no need to save...
            if (YES == [object hasUnsavedChanges]) {
                NSError *error = nil;
                
                // Associate the bag to this store
                if (nil == [object store]) {
                    [object _setStore:self];
                }
                
                if (NO == [object _saveInStore:self error:&error]) {
                    [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                             reason:[NSString stringWithFormat:@"*** -[%@ %s]: %@", [self class], _cmd, [error localizedDescription]]
                                           userInfo:nil]raise];
                }
            }
        } else {
            if (NO == [(id)object conformsToProtocol:@protocol(NSFNanoObjectProtocol)]) {
                [[NSException exceptionWithName:NSFNonConformingNanoObjectProtocolException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %s]: the object does not conform to NSFNanoObjectProtocol.", [self class], _cmd]
                                       userInfo:nil]raise];            
            }
            
            if (nil == [object nanoObjectKey]) {
                [[NSException exceptionWithName:NSFNanoObjectBehaviorException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %s]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], _cmd]
                                       userInfo:nil]raise]; 
            }
            
            [nonBagObjects addObject:object];
        }
    }
    
    BOOL success = [self _addObjectsFromArray:nonBagObjects forceSave:NO error:outError];
    
    [nonBagObjects release];
    
    return success;
}

- (BOOL)removeObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError
{
    NSArray *wrapper = [[NSArray alloc]initWithObjects:theObject, nil];
    BOOL success = [self removeObjectsInArray:wrapper error:outError];
    [wrapper release];
    return success;
}

- (BOOL)removeObjectsWithKeysInArray:(NSArray *)someKeys error:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    if (nil == someKeys)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: someKeys is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    NSUInteger count = [someKeys count];
    
    if (0 == count)
        return NO;
    
    BOOL transactionStartedHere = [self beginTransactionAndReturnError:nil];
    
    NSString *theSQLStatement = [[NSString alloc]initWithFormat:@"CREATE TEMP TABLE %@(x);", NSF_Private_ToDeleteTableKey];
    [nanoStoreEngine executeSQL:theSQLStatement];
    [theSQLStatement release];
    
    sqlite3_stmt *statement;
    theSQLStatement = [[NSString alloc]initWithFormat:@"INSERT INTO %@ VALUES (?);", NSF_Private_ToDeleteTableKey];
    BOOL success = [self _prepareSQLite3Statement:&statement theSQLStatement:theSQLStatement];
    [theSQLStatement release];
    
    if (success) {
        for (NSString *key in someKeys) {
            int status = sqlite3_reset (statement);
            if (SQLITE_OK != status) {
                break;
            }
            
            // Bind and execute the statement...
            status = sqlite3_bind_text ( statement, 1, [key UTF8String], -1, SQLITE_STATIC);
            
            // Since we're operating with extended result code support, extract the bits
            // and obtain the regular result code
            // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
            
            status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
            
            if (SQLITE_OK == status) {
                [self _executeSQLite3StepUsingSQLite3Statement:statement];
            }
        }
        sqlite3_finalize(statement);
    }
    
    _NSFLog(@"          Before removing the keys to be stored from NSFKeys...");
    theSQLStatement = [[NSString alloc]initWithFormat:@"DELETE FROM %@ WHERE %@ IN (SELECT * FROM %@);", NSFKeys, NSFKey, NSF_Private_ToDeleteTableKey];
    [nanoStoreEngine executeSQL:theSQLStatement];
    [theSQLStatement release];
    
    _NSFLog(@"          Before removing the keys to be stored from NSFValues...");
    theSQLStatement = [[NSString alloc]initWithFormat:@"DELETE FROM %@ WHERE %@ IN (SELECT * FROM %@);", NSFValues, NSFKey, NSF_Private_ToDeleteTableKey];
    [nanoStoreEngine executeSQL:theSQLStatement];
    [theSQLStatement release];
    
    _NSFLog(@"          Before DROP TABLE NSF_Private_ToDeleteTableKey...");
    theSQLStatement = [[NSString alloc]initWithFormat:@"DROP TABLE %@;", NSF_Private_ToDeleteTableKey];
    [nanoStoreEngine executeSQL:theSQLStatement];
    [theSQLStatement release];
    
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
                                     reason:[NSString stringWithFormat:@"*** -[%@ %s]: the object does not conform to NSFNanoObjectProtocol.", [self class], _cmd]
                                   userInfo:nil]raise];  
        } else {
            NSString *objectKey = [(id)object nanoObjectKey];
            if (nil == objectKey) {
                [[NSException exceptionWithName:NSFNanoObjectBehaviorException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %s]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], _cmd]
                                       userInfo:nil]raise]; 
            }
            [someKeys addObject:objectKey];
        }
    }
    
    return [self removeObjectsWithKeysInArray:someKeys error:outError];
}

#pragma mark Searching

- (NSArray *)bags
{
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFPlist, NSFObjectClass FROM NSFKeys WHERE NSFObjectClass = \"%@\"", NSStringFromClass([NSFNanoBag class])];
    
    return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil]allValues];

}

- (NSFNanoBag *)bagWithName:(NSString *)theName
{
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    
    search.attribute = NSF_Private_NSFNanoBag_Name;
    search.match = NSFEqualTo;
    search.value = theName;
    
    // Returns a dictionary with the UUID of the object (key) and the NanoObject (value).
    return [[[search searchObjectsWithReturnType:NSFReturnObjects error:nil]allObjects]lastObject];
}

- (NSArray *)bagsWithKeysInArray:(NSArray *)someKeys
{
    if ([someKeys count] == 0) {
        return [NSArray array];
    }
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    NSString *quotedString = [NSFNanoSearch _quoteStrings:someKeys joiningWithDelimiter:@","];
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFPlist, NSFObjectClass FROM NSFKeys WHERE NSFKey IN (%@) AND NSFObjectClass = \"%@\"", quotedString, NSStringFromClass([NSFNanoBag class])];
    
    return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil]allValues];
}

- (NSArray *)bagsContainingObjectWithKey:(NSString *)aKey
{
    if (nil == aKey) {
        return [NSArray array];
    }
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFPlist, NSFObjectClass FROM NSFKeys WHERE NSFKey IN (SELECT DISTINCT (NSFKEY) FROM NSFValues WHERE NSFValue = \"%@\") AND NSFObjectClass = \"%@\"", aKey, NSStringFromClass([NSFNanoBag class])];
    
    return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil]allValues];
}

- (NSArray *)objectsWithKeysInArray:(NSArray *)someKeys
{
    if ([someKeys count] == 0) {
        return [NSArray array];
    }
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    NSString *quotedString = [NSFNanoSearch _quoteStrings:someKeys joiningWithDelimiter:@","];
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFPlist, NSFObjectClass FROM NSFKeys WHERE NSFKey IN (%@)", quotedString];
    
    return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil]allValues];
}

- (NSArray *)allObjectClasses
{
    NSFNanoResult *results = [self executeSQL:@"SELECT DISTINCT(NSFObjectClass) FROM NSFKeys"];
    
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
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: the class name cannot be nil.", [self class], _cmd]
                               userInfo:nil]raise];
    }
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:self];
    search.sort = theSortDescriptors;
    
    NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFPlist, NSFObjectClass FROM NSFKeys WHERE NSFObjectClass = \"%@\"", theClassName];
    
    if (nil == theSortDescriptors) 
        return [[search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil] allValues];
    else
        return [search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil];
}

#pragma mark Database Optimizations and Maintenance

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
    [addedObjects removeAllObjects];
}

// ----------------------------------------------
// Clearing the store
// ----------------------------------------------

- (BOOL)removeAllObjectsFromStoreAndReturnError:(out NSError **)outError
{
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    NSError *resultKeys = [[self executeSQL:[NSString stringWithFormat:@"DROP TABLE %@", NSFKeys]]error];
    NSError *resultValues = [[self executeSQL:[NSString stringWithFormat:@"DROP TABLE %@", NSFValues]]error];
    
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
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: path is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    // Make sure we've expanded the tilde
    path = [path stringByExpandingTildeInPath];
    
    if ([self _checkNanoStoreIsReadyAndReturnError:outError] == NO)
        return NO;
    
    if ([[self nanoStoreEngine]isTransactionActive]) {
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:@"Cannot backup store. A transaction is still open."
                                                                             forKey:NSLocalizedDescriptionKey]];
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

/** \cond */

+ (NSFNanoStore *)debug
{
    return [NSFNanoStore createStoreWithType:NSFPersistentStoreType path:[@"~/Desktop/NanoStoreDebug.db" stringByExpandingTildeInPath]];
}

- (void)dealloc
{
    [self closeWithError:nil];
    
    [nanoStoreEngine release];
    [addedObjects release];
    
    [super dealloc];
}

- (NSFNanoResult *)executeSQL:(NSString *)theSQLStatement
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
        [theSQLStatement release];
        
        if ((nil != outError) && (NO == hasInitializationSucceeded)) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %s]: failed to prepare _storeValuesStatement.", [self class], _cmd]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        }
    }
    
    if ((NULL == _storeKeysStatement) && (YES == hasInitializationSucceeded)) {
        NSString *theSQLStatement = [[NSString alloc]initWithFormat:@"INSERT INTO %@(%@, %@, %@, %@) VALUES (?,?,?,?);", NSFKeys, NSFKey, NSFPlist, NSFCalendarDate, NSFObjectClass];
        hasInitializationSucceeded = [self _prepareSQLite3Statement:&_storeKeysStatement theSQLStatement:theSQLStatement];
        [theSQLStatement release];
        
        if ((nil != outError) && (NO == hasInitializationSucceeded)) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %s]: failed to prepare _storeKeysStatement.", [self class], _cmd]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        }
    }
    
    return hasInitializationSucceeded;
}

- (void)_releasePreparedStatements
{
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

- (NSString*)_nestedDescriptionWithPrefixedSpace:(NSString *)prefixedSpace
{
    if (nil == prefixedSpace) {
        prefixedSpace = @"";
    }
    
    NSMutableString *description = [NSMutableString string];
    [description appendString:@"\n"];
    [description appendString:[NSString stringWithFormat:@"%@NanoStore address      : 0x%x\n", prefixedSpace, self]];
    [description appendString:[NSString stringWithFormat:@"%@Is our transaction?    : %@\n", prefixedSpace, (_isOurTransaction ? @"Yes" : @"No")]];
    [description appendString:[NSString stringWithFormat:@"%@Save interval           : %ld\n", prefixedSpace, (saveInterval == 0 ? 1 : saveInterval)]];
    [description appendString:[NSString stringWithFormat:@"%@Engine                 : %@\n", prefixedSpace, [nanoStoreEngine NSFP_nestedDescriptionWithPrefixedSpace:@"          "]]];
    
    return description;
}

- (BOOL)_checkNanoStoreIsReadyAndReturnError:(out NSError **)outError
{
    if (nil == [self nanoStoreEngine]) {
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %s]: the NSF store has not been set.", [self class], _cmd]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        return NO;
    }
    
    if ([[self nanoStoreEngine]isDatabaseOpen] == NO) {
        if (nil != outError)
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %s]: the store is not open.", [self class], _cmd]
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
        theSQLStatement = [NSString stringWithFormat:@"CREATE TABLE %@(ROWID INTEGER PRIMARY KEY, %@ TEXT, %@ TEXT, %@ TEXT, %@ TEXT);", NSFKeys, NSFKey, NSFPlist, NSFCalendarDate, NSFObjectClass];
        success = (nil == [[[self nanoStoreEngine]executeSQL:theSQLStatement]error]);
        if (NO == success)
            return NO;
        
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, NSFRowIDColumnName, rowUIDDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, NSFKey, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, NSFPlist, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, dateDatatype, dateDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];        
        [[self nanoStoreEngine]NSFP_insertStringValues:[NSArray arrayWithObjects:NSFKeys, NSFObjectClass, stringDatatype, nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable];
    }
    
    return YES;
}

- (BOOL)_storeDictionary:(NSDictionary *)someInfo forKey:(NSString *)aKey forClassNamed:(NSString *)className usingSQLite3Statement:(sqlite3_stmt *)storeValuesStatement error:(out NSError **)outError
{
    if (nil == someInfo)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: someInfo is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    if (nil == aKey)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: aKey is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    if (nil == storeValuesStatement)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: aStatement is NULL.", [self class], _cmd]
                               userInfo:nil]raise];
    
    NSRange range = [aKey rangeOfString:@"."];
    if (NSNotFound != range.location)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: aKey cannot contain a period ('.')", [self class], _cmd]
                               userInfo:nil]raise];
    
    NSArray *keys = [someInfo allKeys];
    for (NSString *key in keys) {
        range = [key rangeOfString:@"."];
        if (NSNotFound != range.location)
            [[NSException exceptionWithName:NSFUnexpectedParameterException
                                     reason:[NSString stringWithFormat:@"*** -[%@ %s]: the keys of the dictionary cannot contain a period ('.')", [self class], _cmd]
                                   userInfo:nil]raise];
    }
    
    const char *aKeyUTF8 = [aKey UTF8String];
    BOOL success = YES;
    
    // Flatten the dictionary
    {
        NSString *keyPath = [[NSString alloc]initWithString:aKey];
        NSMutableArray *flattenedKeys = [NSMutableArray new];
        NSMutableArray *flattenedValues = [NSMutableArray new];
        
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        [self _flattenCollection:someInfo keys:&flattenedKeys values:&flattenedValues];
        
        NSUInteger i, count = [flattenedKeys count];
        
        success = NO;
        
        for (i = 0; i < count; i++) {
            NSString *attribute = [flattenedKeys objectAtIndex:i];
            id value = [flattenedValues objectAtIndex:i];
            
            // Reset, as required by SQLite...
            int status = sqlite3_reset (storeValuesStatement);
            
            // Since we're operating with extended result code support, extract the bits
            // and obtain the regular result code
            // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
            
            status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
            
            if (SQLITE_OK == status) {
                
                // Bind and execute the statement...
                BOOL resultBindKey = (sqlite3_bind_text (storeValuesStatement, 1, aKeyUTF8, -1, SQLITE_STATIC) == SQLITE_OK);
                BOOL resultBindAttribute = (sqlite3_bind_text (storeValuesStatement, 2, [attribute UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                
                // Take advantage of manifest typing
                // Branch the type of bind based on the type to be stored: NSString, NSData, NSDate or NSNumber
                NSFNanoDatatype valueDataType = [self _NSFDatatypeOfObject:value];
                BOOL resultBindValue = NO;
                
                switch (valueDataType) {
                    case NSFNanoTypeData:
                        resultBindValue = (sqlite3_bind_blob(storeValuesStatement, 3, [value bytes], [value length], NULL) == SQLITE_OK);
                        break;
                    case NSFNanoTypeString:
                    case NSFNanoTypeDate:
                        resultBindValue = (sqlite3_bind_text (storeValuesStatement, 3, [[self _stringFromValue:value]UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                        break;
                        break;
                    case NSFNanoTypeNumber:
                        resultBindValue = (sqlite3_bind_double (storeValuesStatement, 3, [value doubleValue]) == SQLITE_OK);
                        break;
                    default:
                        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: datatype %@ cannot be stored because its class type is unknown.", [self class], _cmd, [value class]]
                                               userInfo:nil]raise];
                        break;
                }
                
                // Store the element's datatype so we can recreate it later on when we read it back from the store...
                NSString *valueDatatypeString = NSFStringFromNanoDataType(valueDataType);
                BOOL resultBindDatatype = (sqlite3_bind_text (storeValuesStatement, 4, [valueDatatypeString UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                
                success = (resultBindKey && resultBindAttribute && resultBindValue && resultBindDatatype);
                if (success) {
                    [self _executeSQLite3StepUsingSQLite3Statement:storeValuesStatement];
                }
            }
        }
        
        [pool drain];
        
        // Cleanup
        [keyPath autorelease];
        [flattenedKeys autorelease];
        [flattenedValues autorelease];
    }
    
    if (YES == success) {
        // Save the Key and its Plist (if it applies)
        NSString *dictXML = nil;
        NSString *errorString = nil;
        
        NSData *dictData = [NSPropertyListSerialization dataFromPropertyList:someInfo format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorString];
        if (nil != errorString) {
            NSLog(@"     Dictionary: %@", someInfo);
            NSLog(@"*** -[%@ %@]: [NSPropertyListSerialization dataFromPropertyList] failure. %@", [self class], NSStringFromSelector(_cmd), errorString);
            NSLog(@"     Dictionary info: %@", someInfo);
            success = NO;
        } else {
            if ([dictData length] > 0)
                dictXML = [[[NSString alloc]initWithBytes:[dictData bytes]length:[dictData length]encoding:NSUTF8StringEncoding]autorelease];
            else
                dictXML = @"";
            
            if (nil == dictXML) {
                if (nil != outError)
                    *outError = [NSError errorWithDomain:NSFDomainKey
                                                    code:NSF_Private_InvalidParameterDataCodeKey
                                                userInfo:[NSDictionary dictionaryWithObject:@"Couldn't serialize the object: %@"
                                                                                     forKey:NSLocalizedDescriptionKey]];
                success = NO;
            } else {
                // Reset, as required by SQLite...
                int status = sqlite3_reset (_storeKeysStatement);
                
                // Since we're operating with extended result code support, extract the bits
                // and obtain the regular result code
                // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
                
                status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
                
                // Bind and execute the statement...
                if (SQLITE_OK == status) {
                    
                    BOOL resultBindKey = (sqlite3_bind_text (_storeKeysStatement, 1, aKeyUTF8, -1, SQLITE_STATIC) == SQLITE_OK);
                    BOOL resultBindPlist = (sqlite3_bind_text (_storeKeysStatement, 2, [dictXML UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                    BOOL resultBindCalendarDate = (sqlite3_bind_text (_storeKeysStatement, 3, [[NSFNanoStore _calendarDateToString:[NSDate date]]UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                    BOOL resultBindClass = (sqlite3_bind_text (_storeKeysStatement, 4, [className UTF8String], -1, SQLITE_STATIC) == SQLITE_OK);
                    
                    success = (resultBindKey && resultBindPlist && resultBindCalendarDate && resultBindClass);
                    if (success) {
                        [self _executeSQLite3StepUsingSQLite3Statement:_storeKeysStatement];
                    }
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
                                     reason:[NSString stringWithFormat:@"*** -[%@ %s]: datatype %@ doesn't respond to selector 'stringValue' or 'description'.", [self class], _cmd, [aValue class]]
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
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: aDate is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    return [__sNSFNanoStoreDateFormatter stringFromDate:aDate];
}

- (void)_flattenCollection:(NSDictionary *)info keys:(NSMutableArray **)flattenedKeys values:(NSMutableArray **)flattenedValues
{
    NSMutableArray *keyPath = [NSMutableArray new];
    [self _flattenCollection:info keyPath:&keyPath keys:flattenedKeys values:flattenedValues];
    [keyPath release];
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
    [addedObjects addObjectsFromArray:someObjects];
    
    // No need to continue if there's nothing to be saved
    NSUInteger unsavedObjectsCount = [addedObjects count];
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
            id object = [addedObjects objectAtIndex:i];
            if (NO == [object conformsToProtocol:@protocol(NSFNanoObjectProtocol)]) {
                [addedObjects removeObjectAtIndex:i];
                i--;
                continue;
            }
            
            NSString *objectKey = [(id)object nanoObjectKey];
            if (nil == objectKey) {
                [[NSException exceptionWithName:NSFNanoObjectBehaviorException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %s]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], _cmd]
                                       userInfo:nil]raise]; 
            }
            [keys addObject:objectKey];
        }
        
        // Recalculate how many elements we have left
        unsavedObjectsCount = [addedObjects count];
        
        if (unsavedObjectsCount > 0) {
            if (NO == [self removeObjectsWithKeysInArray:[keys allObjects] error:outError]) {
                [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %s]: %@", [self class], _cmd, [*outError localizedDescription]]
                                       userInfo:nil]raise];
            }
        }
        
        [keys release];
        NSTimeInterval secondsRemoving = [[NSDate date]timeIntervalSinceDate:startRemovingDate];    
        _NSFLog(@"     Done. Removing the objects took %.3f seconds", secondsRemoving);
        
        // Store the objects...
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        BOOL transactionStartedHere = [self beginTransactionAndReturnError:nil];
        
        _NSFLog(@"     Storing %ld objects...", unsavedObjectsCount);
        
        // Reset the default save interval if needed...
        if (0 == saveInterval) {
            self.saveInterval = 1;
        }
        
        for (id object in addedObjects) {
            // If the object was originally created by storing a class not recognized by this process, honor it and store it with the right class string.
            NSString *className = nil;
            if (YES == [object respondsToSelector:@selector(originalClassString)]) {
                className = [object originalClassString];
            }
            
            // Otherwise, just save the class name of the object being stored
            if (nil == className) {
                className = NSStringFromClass([object class]);
            }
            
            if (NO == [self _storeDictionary:[object dictionaryRepresentation] forKey:[(id)object nanoObjectKey] forClassNamed:className usingSQLite3Statement:_storeValuesStatement error:outError]) {
                [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %s]: %@", [self class], _cmd, [*outError localizedDescription]]
                                       userInfo:nil]raise];
            }
            
            i++;
            
            // Commit every 'saveInterval' interations...
            if ((0 == i % self.saveInterval) && transactionStartedHere) {
                if (NO == [self commitTransactionAndReturnError:outError]) {
                    [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                             reason:[NSString stringWithFormat:@"*** -[%@ %s]: %@", [self class], _cmd, [*outError localizedDescription]]
                                           userInfo:nil]raise];
                }
                
                if (YES == transactionStartedHere) {
                    transactionStartedHere = [self beginTransactionAndReturnError:outError];
                    if (NO == transactionStartedHere) {
                        [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: %@", [self class], _cmd, [*outError localizedDescription]]
                                               userInfo:nil]raise];
                    }
                }
            }
            
            // Cleanup memory after 'saveInterval' iterations
            if (0 == i % 1000) {
                [pool drain];
                pool = [NSAutoreleasePool new];
            }
            
        }
        
        // Commit the changes
        if (transactionStartedHere) {
            if (NO == [self commitTransactionAndReturnError:outError]) {
                [[NSException exceptionWithName:NSFNanoStoreUnableToManipulateStoreException
                                         reason:[NSString stringWithFormat:@"*** -[%@ %s]: %@", [self class], _cmd, [*outError localizedDescription]]
                                       userInfo:nil]raise];
            }
        }
        
        // Cleanup
        [pool drain];
        
        NSTimeInterval secondsStoring = [[NSDate date]timeIntervalSinceDate:startStoringDate];
        double ratio = unsavedObjectsCount/secondsStoring;
        _NSFLog(@"     Done. Storing the objects took %.3f seconds (%.0f keys/sec.)", secondsStoring, ratio);
        
        [addedObjects removeAllObjects];
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
    [self executeSQL:theSQLStatement];
    
    // Transfer the NSFKeys table
    NSString *columns = [[[self nanoStoreEngine]columnsForTable:NSFKeys]componentsJoinedByString:@", "];
    theSQLStatement = [NSString stringWithFormat:@"INSERT INTO fileDB.%@ (%@) SELECT * FROM main.%@", NSFKeys, columns, NSFKeys];
    [self executeSQL:theSQLStatement];
    
    // Transfer the NSFValues table
    columns = [[[self nanoStoreEngine]columnsForTable:NSFValues]componentsJoinedByString:@", "];
    theSQLStatement = [NSString stringWithFormat:@"INSERT INTO fileDB.%@ (%@) SELECT * FROM main.%@", NSFValues, columns, NSFValues];
    [self executeSQL:theSQLStatement];
    
    // Safely detach the file-based database
    [self executeSQL:@"DETACH DATABASE fileDB"];
    
    // We can now close the database
    [fileDB closeWithError:outError];
    
    // Move the file to the specified destination
    return [fm moveItemAtPath:tempPath toPath:backupPath error:outError];
}

/** \endcond */

@end