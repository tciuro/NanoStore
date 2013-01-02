/*
     NSFNanoBag.m
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

#import "NSFNanoBag.h"
#import "NSFNanoBag_Private.h"
#import "NSFNanoGlobals.h"
#import "NSFNanoGlobals_Private.h"
#import "NSFNanoStore_Private.h"
#import "NSFNanoSearch_Private.h"
#import "NSFOrderedDictionary.h"
#import "NSFNanoObject_Private.h"

@implementation NSFNanoBag
{
    /** \cond */
    NSMutableDictionary *_savedObjects;
    NSMutableDictionary *_unsavedObjects;
    NSMutableDictionary *_removedObjects;
    /** \endcond */
}

+ (NSFNanoBag*)bag
{
    return [[self alloc]initBagWithName:nil andObjects:[NSArray array]];
}

+ (NSFNanoBag*)bagWithObjects:(NSArray *)someObjects
{
    return [[self alloc]initBagWithName:nil andObjects:someObjects];
}

+ bagWithName:(NSString *)theName
{
    return [[self alloc]initBagWithName:theName andObjects:[NSArray array]];
}

+ bagWithName:(NSString *)theName andObjects:(NSArray *)someObjects
{
    return [[self alloc]initBagWithName:theName andObjects:someObjects];
}

- (id)initBagWithName:(NSString *)theName andObjects:(NSArray *)someObjects
{
    if (nil == someObjects) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: 'someObjects' cannot be nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    if ((self = [self init])) {
        [self addObjectsFromArray:someObjects error:nil];
        
        _name = theName;
        _hasUnsavedChanges = YES;
    }
    
    return self;
}

/** \cond */

- (id)init
{
    if ((self = [super init])) {
        _store = nil;
        _key = [NSFNanoEngine stringWithUUID];
        _name = nil;
        _savedObjects = [NSMutableDictionary new];
        _unsavedObjects = [NSMutableDictionary new];
        _removedObjects = [NSMutableDictionary new];
        _hasUnsavedChanges = NO;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NSFNanoBag *copy = [[[self class]allocWithZone:zone]initNanoObjectFromDictionaryRepresentation:[self dictionaryRepresentation] forKey:[NSFNanoEngine stringWithUUID] store:_store];
    return copy;
}


- (id)rootObject
{
    return self;
}

#pragma mark -

- (void)setName:(NSString *)aName
{
    _name = aName;
    _hasUnsavedChanges = YES;
}

/** \endcond */

- (NSUInteger)count
{
    return _savedObjects.count + _unsavedObjects.count;
}

- (NSString *)description
{
    return [self JSONDescription];
}

- (NSDictionary *)dictionaryDescription
{
    NSFOrderedDictionary *values = [NSFOrderedDictionary new];
    
    values[@"NanoBag address"] = [NSString stringWithFormat:@"%p", self];
    values[@"Key"] = _key;
    values[@"Name"] = (nil != _name) ? _name : @"<untitled>";
    values[@"Document store"] = ([_store dictionaryDescription] ? [_store dictionaryDescription] : @"<nil>");
    values[@"Has unsaved changes?"] = (_hasUnsavedChanges ? @"YES" : @"NO");
    values[@"Saved objects"] = @([_savedObjects count]);
    values[@"Unsaved objects"] = @([_unsavedObjects count]);
    values[@"Removed objects"] = @([_removedObjects count]);
    
    return values;
}

- (NSString *)JSONDescription
{
    NSDictionary *values = [self dictionaryDescription];
    
    NSError *outError = nil;
    NSString *description = [NSFNanoObject _NSObjectToJSONString:values error:&outError];
    
    return description;
}

- (NSDictionary *)dictionaryRepresentation
{
    // Iterate the objects collecting the object keys
    NSMutableArray *objectKeys = [NSMutableArray new];
    for (NSString *objectKey in _savedObjects) {
        [objectKeys addObject:objectKey];
    }
    for (NSString *objectKey in _unsavedObjects) {
        [objectKeys addObject:objectKey];
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    if (nil != _name) {
        [info setObject:_name forKey:NSF_Private_NSFNanoBag_Name];
    }
    [info setObject:self.key forKey:NSF_Private_NSFNanoBag_NSFKey];
    [info setObject:objectKeys forKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    return info;
}

- (BOOL)isEqualToNanoBag:(NSFNanoBag *)otherNanoBag
{
    if (self == otherNanoBag) {
        return YES;
    }
    
    BOOL success = YES;
    
    NSArray *sortedArraySelf = [[_savedObjects allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray *sortedArrayOther = [[[otherNanoBag savedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    if (NO == [sortedArraySelf isEqualToArray:sortedArrayOther]) {
        success = NO;
    } else {
        sortedArraySelf = [[_unsavedObjects allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        sortedArrayOther = [[[otherNanoBag unsavedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        if (NO == [sortedArraySelf isEqualToArray:sortedArrayOther]) {
            success = NO;
        } else {
            sortedArraySelf = [[_removedObjects allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            sortedArrayOther = [[[otherNanoBag removedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            if (NO == [sortedArraySelf isEqualToArray:sortedArrayOther]) {
                success = NO;
            }
        }
    }

    return success;
}

#pragma mark -

- (BOOL)addObject:(id <NSFNanoObjectProtocol>)object error:(out NSError **)outError
{
    if (NO == [(id)object conformsToProtocol:@protocol(NSFNanoObjectProtocol)]) {
        [[NSException exceptionWithName:NSFNonConformingNanoObjectProtocolException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the object does not conform to NSFNanoObjectProtocol.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];            
    }
    
    NSString *objectKey = [(id)object nanoObjectKey];
    NSDictionary *info = [(id)object dictionaryRepresentation];
    
    if (objectKey && info) {
        [_savedObjects removeObjectForKey:objectKey];
        [_unsavedObjects setObject:object forKey:objectKey];
        [_removedObjects removeObjectForKey:objectKey];
        _hasUnsavedChanges = YES;
    } else {
        NSString *message = nil;
        if (nil == objectKey)
            message = [NSString stringWithFormat:@"*** -[%@ %@]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], NSStringFromSelector(_cmd)];
        else
            message = [NSString stringWithFormat:@"*** -[%@ %@]: unexpected NSFNanoObject behavior. Reason: the object's dictionary is nil.", [self class], NSStringFromSelector(_cmd)];  
        
        [[NSException exceptionWithName:NSFNanoObjectBehaviorException reason:message userInfo:nil]raise];  
    }
    
    return YES;
}

- (BOOL)addObjectsFromArray:(NSArray *)someObjects error:(out NSError **)outError
{
    if (nil == someObjects) {
        if (nil != outError) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: the object cannot be added because the list provided is nil.", [self class], NSStringFromSelector(_cmd)]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        }
        return NO;
    }
    
    BOOL success = YES;
    
    for (id object in someObjects) {
        if (NO == [self addObject:object error:outError]) {
            success = NO;
        }
    }
    
    return success;
}

- (void)removeObject:(id <NSFNanoObjectProtocol>)object
{
    if (NO == [(id)object conformsToProtocol:@protocol(NSFNanoObjectProtocol)]) {
        [[NSException exceptionWithName:NSFNonConformingNanoObjectProtocolException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the object does not conform to NSFNanoObjectProtocol.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];    
    }
    
    [self removeObjectWithKey:[(id)object nanoObjectKey]];
}

- (void)removeAllObjects
{
    NSMutableDictionary *objects = [[NSMutableDictionary alloc]initWithCapacity:(_savedObjects.count + _removedObjects.count)];
    
    // Save the object and its key
    for (id object in _savedObjects) {
        [objects setObject:object forKey:[object performSelector:@selector(key)]];
    }
    
    // Save the previously removed objects (if any)
    [objects addEntriesFromDictionary:_removedObjects];
    
    [_savedObjects removeAllObjects];
    [_unsavedObjects removeAllObjects];
    [_removedObjects setDictionary:objects];
    _hasUnsavedChanges = YES;
}

- (void)removeObjectsInArray:(NSArray *)someObjects
{
    for (id object in someObjects) {
        [self removeObject:object];
    }
}

- (void)removeObjectWithKey:(NSString *)objectKey
{
    if (nil == objectKey) {
        [[NSException exceptionWithName:NSFNanoObjectBehaviorException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise]; 
    }
    
    // Is the object an existing one?
    id object = [_savedObjects objectForKey:objectKey];
    if (nil != object) {
        [_savedObjects removeObjectForKey:objectKey];
    } else {
        // Is the object still unsaved?
        object = [_unsavedObjects objectForKey:objectKey];
        if (nil != object) {
            [_unsavedObjects removeObjectForKey:objectKey];
        }
    }
    
    if (nil == object) {
        // The object doesn't exist, so there is no need to mark the bag as dirty
    } else {
        [_removedObjects setObject:object forKey:objectKey];
        _hasUnsavedChanges = YES;
    }
}

- (void)removeObjectsWithKeysInArray:(NSArray *)someKeys
{
    for (NSString *objectKey in someKeys) {
        [self removeObjectWithKey:objectKey];
    }
}

- (BOOL)saveAndReturnError:(out NSError **)outError
{
    if (NO == self.hasUnsavedChanges) {
        return YES;
    }
    
    if (nil == _store) {
        if (nil != outError) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: unable to save the bag. Reason: the store has not been set.", [self class], NSStringFromSelector(_cmd)]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        }
        return NO;
    }
    
    return [self _saveInStore:_store error:outError];
}

#pragma mark -

- (void)deflateBag
{
    NSArray *savedObjectsCopy = [[NSArray alloc]initWithArray:[_savedObjects allKeys]];
    
    for (id saveObjectKey in savedObjectsCopy) {
        [_savedObjects setObject:[NSNull null] forKey:saveObjectKey];
    }
    
}

- (void)inflateBag
{
    NSArray *objectKeys = [_savedObjects allKeys];
    [self _inflateObjectsWithKeys:objectKeys];
}

- (BOOL)reloadBagWithError:(out NSError **)outError
{
    // If the bag is not associated to a document store, there is no need to continue
    if (nil == _store) {
        return YES;
    }
    
    // Refresh the bag to match the contents stored on the database
    [self _inflateObjectsWithKeys:[NSArray arrayWithObject:_key]];
    NSFNanoBag *savedBag = [_savedObjects objectForKey:_key];
    if (nil != savedBag) {
        [_savedObjects removeAllObjects];
        [_savedObjects addEntriesFromDictionary:savedBag.savedObjects];
        for (NSString *objectKey in _unsavedObjects) {
            [_savedObjects removeObjectForKey:objectKey];
        }
    } else {
        if (nil != outError) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: the bag could not be refreshed.", [self class], NSStringFromSelector(_cmd)]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)undoChangesWithError:(out NSError **)outError
{
    [_savedObjects removeAllObjects];
    [_unsavedObjects removeAllObjects];
    [_removedObjects removeAllObjects];
    
    _hasUnsavedChanges = NO;
    
    return [self reloadBagWithError:outError];
}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

/** \cond */

- (id)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)dictionary forKey:(NSString *)aKey store:(NSFNanoStore *)aStore
{
    if ((self = [self init])) {
        _name = [dictionary objectForKey:NSF_Private_NSFNanoBag_Name];
        _store = aStore;
        _key = aKey;
        _savedObjects = [NSMutableDictionary new];
        _unsavedObjects = [NSMutableDictionary new];
        _removedObjects = [NSMutableDictionary new];
        
        NSArray *objectKeys = [dictionary objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
        
        [self _inflateObjectsWithKeys:objectKeys];
        
        _hasUnsavedChanges = NO;
    }
    
    return self;
}

- (NSDictionary *)nanoObjectDictionaryRepresentation
{
    return [self dictionaryRepresentation];
}

- (NSString *)nanoObjectKey
{
    return _key;
}

- (void)_setStore:(NSFNanoStore *)aStore
{
    _store = aStore;
}

- (BOOL)_saveInStore:(NSFNanoStore *)someStore error:(out NSError **)outError
{
    // Save the unsaved objects first...
    NSArray *contentsToBeSaved = [_unsavedObjects allValues];
    if ([contentsToBeSaved count] > 0) {
        [someStore _addObjectsFromArray:contentsToBeSaved forceSave:YES error:outError];
    }
    
    // Move the existing objects to the unsaved list, in order to save the bag
    [_unsavedObjects addEntriesFromDictionary:_savedObjects];
    [_savedObjects removeAllObjects];
    [_removedObjects removeAllObjects];
    
    // Save the unsaved bag...
    BOOL success = [someStore _addObjectsFromArray:[NSArray arrayWithObject:self] forceSave:YES error:outError];
    
    if (YES == success) {
        [_unsavedObjects removeAllObjects];
        success = [self reloadBagWithError:outError];
        if (YES == success) {
            _hasUnsavedChanges = NO;
        }
        return success;
    }
    
    return success;
}

- (void)_inflateObjectsWithKeys:(NSArray *)someKeys
{
    if ([someKeys count] != 0) {
        NSFNanoSearch *search = [NSFNanoSearch searchWithStore:_store];
        NSString *quotedString = [NSFNanoSearch _quoteStrings:someKeys joiningWithDelimiter:@","];
        NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFKeyedArchive, NSFObjectClass FROM NSFKeys WHERE NSFKey IN (%@)", quotedString];
        
        NSDictionary *results = [search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil];
        
        if (nil != results) {
            [_savedObjects addEntriesFromDictionary:results];
        }
    }
}

/** \endcond */

@end