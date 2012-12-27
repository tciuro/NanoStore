/*
     NSFNanoObject.m
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

#import "NSFNanoObject.h"
#import "NSFNanoObject_Private.h"
#import "NSFNanoGlobals_Private.h"

@implementation NSFNanoObject
{
    NSMutableDictionary *info;
}

@synthesize info, key, originalClassString;

+ (NSFNanoObject *)nanoObject
{
    return [[self alloc]initNanoObjectFromDictionaryRepresentation:nil forKey:nil store:nil];
}

+ (NSFNanoObject *)nanoObjectWithDictionary:(NSDictionary *)aDictionary
{
    return [[self alloc]initNanoObjectFromDictionaryRepresentation:aDictionary forKey:nil store:nil];
}

+ (NSFNanoObject*)nanoObjectWithDictionary:(NSDictionary *)theDictionary key:(NSString *)theKey
{
    return [[self alloc]initNanoObjectFromDictionaryRepresentation:theDictionary forKey:theKey store:nil];
}

- (id)initFromDictionaryRepresentation:(NSDictionary *)aDictionary
{
    return [self initNanoObjectFromDictionaryRepresentation:aDictionary forKey:nil store:nil];
}

- (id)initFromDictionaryRepresentation:(NSDictionary *)aDictionary key:(NSString *)theKey
{
    return [self initNanoObjectFromDictionaryRepresentation:aDictionary forKey:theKey store:nil];
}

- (id)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)aDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)aStore
{
    // We allow a nil dictionary because: 1) it's interpreted as empty and 2) reduces memory consumption on the caller if no data is being passed.
    
    if ((self = [self init])) {
        // If we have supplied a key, honor it and overwrite the original one
        if (nil != aKey) {
            key = [aKey copy];
        }
        
        // Keep the dictionary if needed
        if (nil != aDictionary) {
            info = [NSMutableDictionary new];
            [info addEntriesFromDictionary:aDictionary];
        }
    }
    
    return self;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString string];
    
    [description appendString:@"\n"];
    [description appendString:[NSString stringWithFormat:@"NanoObject address : %p\n", self]];
    [description appendString:[NSString stringWithFormat:@"Original class     : %@\n", (nil != originalClassString) ? originalClassString : NSStringFromClass ([self class])]];
    [description appendString:[NSString stringWithFormat:@"Key                : %@\n", key]];
    [description appendString:[NSString stringWithFormat:@"Info               : %ld key/value pairs\n", [info count]]];

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:&error];
    if (nil == error) {
        NSString *JSONInfo = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        [description appendString:[NSString stringWithFormat:@"%@\n", JSONInfo]];
    } else {
        [description appendString:[NSString stringWithFormat:@"Contents:          : <unable to display the contents>\n"]];
    }
    
    return description;
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary
{
    // Allocate the dictionary if needed
    if (nil == info) {
        info = [NSMutableDictionary new];
    }
    
    [info addEntriesFromDictionary:otherDictionary];
}

- (void)setObject:(id)anObject forKey:(NSString *)aKey
{
    // Allocate the dictionary if needed
    if (nil == info) {
        info = [NSMutableDictionary new];
    }
    
    [info setObject:anObject forKey:aKey];
}

- (id)objectForKey:(NSString *)aKey
{
    return [info objectForKey:aKey];
}

- (void)removeObjectForKey:(NSString *)aKey
{
    [info removeObjectForKey:aKey];
}

- (void)removeAllObjects
{
    [info removeAllObjects];
}

- (void)removeObjectsForKeys:(NSArray *)keyArray
{
    [info removeObjectsForKeys:keyArray];
}

- (BOOL)isEqualToNanoObject:(NSFNanoObject *)otherNanoObject
{
    if (self == otherNanoObject) {
        return YES;
    }
    
    BOOL success = YES;
    
    if (originalClassString != otherNanoObject.originalClassString) {
        if (NO == [originalClassString isEqualToString:otherNanoObject.originalClassString]) {
            success = NO;
        }
    }
    
    if (YES == success) {
        success = [info isEqualToDictionary:otherNanoObject.info];
    }
    
    return success;
}

- (NSDictionary *)dictionaryRepresentation
{
    return self.info;
}

/** \cond */

- (id)init
{
    if ((self = [super init])) {
        key = [[NSFNanoEngine stringWithUUID]copy];
        info = nil;
        originalClassString = nil;
    }
    
    return self;
}

#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
    NSFNanoObject *copy = [[[self class]allocWithZone:zone]initNanoObjectFromDictionaryRepresentation:[self dictionaryRepresentation] forKey:[NSFNanoEngine stringWithUUID] store:nil];
    return copy;
}


- (NSDictionary *)nanoObjectDictionaryRepresentation
{
    return [self dictionaryRepresentation];
}

- (NSString *)nanoObjectKey
{
    return self.key;
}

- (id)rootObject
{
    return info;
}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (void)_setOriginalClassString:(NSString *)theClassString
{
    if (originalClassString != theClassString) {
        originalClassString = theClassString;
    }
}

/** \endcond */

@end
