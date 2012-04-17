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

@implementation NSFNanoBag
{
@protected
    /** \cond */
    NSMutableDictionary     *savedObjects;
    NSMutableDictionary     *unsavedObjects;
    NSMutableDictionary     *removedObjects;
    /** \endcond */
}

@synthesize store, name, key, savedObjects, unsavedObjects, removedObjects, hasUnsavedChanges;

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
    if ((self = [self init])) {
        NSError *outError = nil;
        if (NO == [self addObjectsFromArray:someObjects error:&outError]) {
            NSLog(@"%@", [NSString stringWithFormat:@"*** -[%@ %s]: a problem occurred while initializing the NanoBag, leaving it in an inconsistent state. Reason: %@.", [self class], _cmd, [outError localizedDescription]]);
        }
        
        name = [theName copy];
        hasUnsavedChanges = YES;
    }
    
    return self;
}

/** \cond */

- (id)init
{
    if ((self = [super init])) {
        key = [NSFNanoEngine stringWithUUID];
        savedObjects = [NSMutableDictionary new];
        unsavedObjects = [NSMutableDictionary new];
        removedObjects = [NSMutableDictionary new];
        
        hasUnsavedChanges = NO;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    NSFNanoBag *copy = [[[self class]allocWithZone:zone]initNanoObjectFromDictionaryRepresentation:[self dictionaryRepresentation] forKey:[NSFNanoEngine stringWithUUID] store:store];
    return copy;
}


- (id)rootObject
{
    return self;
}

#pragma mark -

- (void)setName:(NSString *)aName
{
    name = [aName copy];
    hasUnsavedChanges = YES;
}

/** \endcond */

- (NSString *)name
{
    return name;
}

- (NSUInteger)count
{
    return savedObjects.count + unsavedObjects.count;
}

- (NSString*)description
{
    NSMutableString *description = [NSMutableString string];
    
    [description appendString:@"\n"];
    [description appendString:[NSString stringWithFormat:@"NanoBag address      : 0x%x\n", self]];
    [description appendString:[NSString stringWithFormat:@"Name                 : %@\n", (nil != name) ? name : @"<untitled>"]];
    [description appendString:[NSString stringWithFormat:@"Document store       : 0x%x\n", store]];
    [description appendString:[NSString stringWithFormat:@"Has unsaved changes? : %@\n", (hasUnsavedChanges ? @"YES" : @"NO")]];
    [description appendString:[NSString stringWithFormat:@"Saved objects        : %ld key/value pairs\n", [savedObjects count]]];
    [description appendString:[NSString stringWithFormat:@"Unsaved objects      : %ld key/value pairs\n", [unsavedObjects count]]];
    [description appendString:[NSString stringWithFormat:@"Removed objects      : %ld key/value pairs\n", [removedObjects count]]];

    return description;
}

- (BOOL)isEqualToNanoBag:(NSFNanoBag *)otherNanoBag
{
    if (self == otherNanoBag) {
        return YES;
    }
    
    BOOL success = YES;
    
    NSArray *sortedArraySelf = [[[self savedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray *sortedArrayOther = [[[otherNanoBag savedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    if (NO == [sortedArraySelf isEqualToArray:sortedArrayOther]) {
        success = NO;
    } else {
        sortedArraySelf = [[[self unsavedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        sortedArrayOther = [[[otherNanoBag unsavedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        if (NO == [sortedArraySelf isEqualToArray:sortedArrayOther]) {
            success = NO;
        } else {
            sortedArraySelf = [[[self removedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            sortedArrayOther = [[[otherNanoBag removedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            if (NO == [sortedArraySelf isEqualToArray:sortedArrayOther]) {
                success = NO;
            }
        }
    }

    return success;
}

- (NSDictionary *)dictionaryRepresentation
{
    // Iterate the objects collecting the object keys
    NSMutableArray *objectKeys = [NSMutableArray new];
    for (NSString *objectKey in self.savedObjects) {
        [objectKeys addObject:objectKey];
    }
    for (NSString *objectKey in self.unsavedObjects) {
        [objectKeys addObject:objectKey];
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    if (nil != name) {
        [info setObject:name forKey:NSF_Private_NSFNanoBag_Name];
    }
    [info setObject:self.key forKey:NSF_Private_NSFNanoBag_NSFKey];
    [info setObject:objectKeys forKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    return info;
}

#pragma mark -

- (BOOL)addObject:(id <NSFNanoObjectProtocol>)object error:(out NSError **)outError
{
    if (NO == [(id)object conformsToProtocol:@protocol(NSFNanoObjectProtocol)]) {
        [[NSException exceptionWithName:NSFNonConformingNanoObjectProtocolException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: the object does not conform to NSFNanoObjectProtocol.", [self class], _cmd]
                               userInfo:nil]raise];            
    }
    
    NSString *objectKey = [(id)object nanoObjectKey];
    NSDictionary *info = [(id)object dictionaryRepresentation];
    
    if (objectKey && info) {
        [savedObjects removeObjectForKey:objectKey];
        [unsavedObjects setObject:object forKey:objectKey];
        [removedObjects removeObjectForKey:objectKey];
        hasUnsavedChanges = YES;
    } else {
        NSString *message = nil;
        if (nil == objectKey)
            message = [NSString stringWithFormat:@"*** -[%@ %s]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], _cmd];
        else
            message = [NSString stringWithFormat:@"*** -[%@ %s]: unexpected NSFNanoObject behavior. Reason: the object's dictionary is nil.", [self class], _cmd];  
        
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
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %s]: the object cannot be added because the list provided is nil.", [self class], _cmd]
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
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: the object does not conform to NSFNanoObjectProtocol.", [self class], _cmd]
                               userInfo:nil]raise];    
    }
    
    [self removeObjectWithKey:[(id)object nanoObjectKey]];
}

- (void)removeAllObjects
{
    NSMutableDictionary *objects = [[NSMutableDictionary alloc]initWithCapacity:(savedObjects.count + removedObjects.count)];
    
    // Save the object and its key
    for (id object in savedObjects) {
        [objects setObject:object forKey:[object performSelector:@selector(key)]];
    }
    
    // Save the previously removed objects (if any)
    [objects addEntriesFromDictionary:removedObjects];
    
    [savedObjects removeAllObjects];
    [unsavedObjects removeAllObjects];
    [removedObjects setDictionary:objects];
    hasUnsavedChanges = YES;
    
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
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: unexpected NSFNanoObject behavior. Reason: the object's key is nil.", [self class], _cmd]
                               userInfo:nil]raise]; 
    }
    
    // Is the object an existing one?
    id object = [savedObjects objectForKey:objectKey];
    if (nil != object) {
        [savedObjects removeObjectForKey:objectKey];
    } else {
        // Is the object still unsaved?
        object = [unsavedObjects objectForKey:objectKey];
        if (nil != object) {
            [unsavedObjects removeObjectForKey:objectKey];
        }
    }
    
    if (nil == object) {
        // The object doesn't exist, so there is no need to mark the bag as dirty
    } else {
        [removedObjects setObject:object forKey:objectKey];
        hasUnsavedChanges = YES;
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
    
    if (nil == store) {
        if (nil != outError) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %s]: unable to save the bag. Reason: the store has not been set.", [self class], _cmd]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        }
        return NO;
    }
    
    return [self _saveInStore:store error:outError];
}

#pragma mark -

- (void)deflateBag
{
    NSArray *savedObjectsCopy = [[NSArray alloc]initWithArray:[savedObjects allKeys]];
    
    for (id saveObjectKey in savedObjectsCopy) {
        [savedObjects setObject:[NSNull null] forKey:saveObjectKey];
    }
    
}

- (void)inflateBag
{
    NSArray *objectKeys = [savedObjects allKeys];
    [self _inflateObjectsWithKeys:objectKeys];
}

- (BOOL)reloadBagWithError:(out NSError **)outError
{
    // If the bag is not associated to a document store, there is no need to continue
    if (nil == store) {
        return YES;
    }
    
    // Refresh the bag to match the contents stored on the database
    [self _inflateObjectsWithKeys:[NSArray arrayWithObject:key]];
    NSFNanoBag *savedBag = [savedObjects objectForKey:key];
    if (nil != savedBag) {
        [savedObjects removeAllObjects];
        [savedObjects addEntriesFromDictionary:savedBag.savedObjects];
        for (NSString *objectKey in unsavedObjects) {
            [savedObjects removeObjectForKey:objectKey];
        }
    } else {
        if (nil != outError) {
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %s]: the bag could not be refreshed.", [self class], _cmd]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        }
        return NO;
    }
    
    return YES;
}

- (BOOL)undoChangesWithError:(out NSError **)outError
{
    [savedObjects removeAllObjects];
    [unsavedObjects removeAllObjects];
    [removedObjects removeAllObjects];
    
    hasUnsavedChanges = NO;
    
    return [self reloadBagWithError:outError];
}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

/** \cond */

- (id)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)dictionary forKey:(NSString *)aKey store:(NSFNanoStore *)aStore
{
    if ((self = [self init])) {
        name = [[dictionary objectForKey:NSF_Private_NSFNanoBag_Name]copy];
        store = aStore;
        key = aKey;
        savedObjects = [NSMutableDictionary new];
        unsavedObjects = [NSMutableDictionary new];
        removedObjects = [NSMutableDictionary new];
        
        NSArray *objectKeys = [dictionary objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
        
        [self _inflateObjectsWithKeys:objectKeys];
        
        hasUnsavedChanges = NO;
    }
    
    return self;
}

- (NSDictionary *)nanoObjectDictionaryRepresentation
{
    return [self dictionaryRepresentation];
}

- (NSString *)nanoObjectKey
{
    return key;
}

- (void)_setStore:(NSFNanoStore *)aStore
{
    store = aStore;
}

- (BOOL)_saveInStore:(NSFNanoStore *)someStore error:(out NSError **)outError
{
    // Save the unsaved objects first...
    NSArray *contentsToBeSaved = [unsavedObjects allValues];
    if ([contentsToBeSaved count] > 0) {
        [someStore _addObjectsFromArray:contentsToBeSaved forceSave:YES error:outError];
    }
    
    // Move the existing objects to the unsaved list, in order to save the bag
    [unsavedObjects addEntriesFromDictionary:savedObjects];
    [savedObjects removeAllObjects];
    [removedObjects removeAllObjects];
    
    // Save the unsaved bag...
    BOOL success = [someStore _addObjectsFromArray:[NSArray arrayWithObject:self] forceSave:YES error:outError];
    
    if (YES == success) {
        [unsavedObjects removeAllObjects];
        success = [self reloadBagWithError:outError];
        if (YES == success) {
            hasUnsavedChanges = NO;
        }
        return success;
    }
    
    return success;
}

- (void)_inflateObjectsWithKeys:(NSArray *)someKeys
{
    if ([someKeys count] != 0) {
        NSFNanoSearch *search = [NSFNanoSearch searchWithStore:store];
        NSString *quotedString = [NSFNanoSearch _quoteStrings:someKeys joiningWithDelimiter:@","];
        NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT NSFKey, NSFPlist, NSFObjectClass FROM NSFKeys WHERE NSFKey IN (%@)", quotedString];
        
        NSDictionary *results = [search executeSQL:theSQLStatement returnType:NSFReturnObjects error:nil];
        
        if (nil != results) {
            [savedObjects addEntriesFromDictionary:results];
        }
    }
}

/** \endcond */

@end