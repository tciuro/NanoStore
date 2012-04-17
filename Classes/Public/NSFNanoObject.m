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

+ (NSFNanoObject*)nanoObject
{
    NSString *theKey = [NSFNanoEngine stringWithUUID];
    return [[self alloc]initNanoObjectFromDictionaryRepresentation:nil forKey:theKey store:nil];
}

+ (NSFNanoObject*)nanoObjectWithDictionary:(NSDictionary *)aDictionary
{
    NSString *theKey = [NSFNanoEngine stringWithUUID];
    return [[self alloc]initNanoObjectFromDictionaryRepresentation:aDictionary forKey:theKey store:nil];
}

- (id)initFromDictionaryRepresentation:(NSDictionary *)aDictionary
{
    NSString *theKey = [NSFNanoEngine stringWithUUID];
    return [self initNanoObjectFromDictionaryRepresentation:aDictionary forKey:theKey store:nil];
}

- (NSString*)description
{
    NSMutableString *description = [NSMutableString string];
    
    [description appendString:@"\n"];
    [description appendString:[NSString stringWithFormat:@"NanoObject address : 0x%x\n", self]];
    [description appendString:[NSString stringWithFormat:@"Original class     : %@\n", (nil != originalClassString) ? originalClassString : NSStringFromClass ([self class])]];
    [description appendString:[NSString stringWithFormat:@"Key                : %@\n", key]];
    [description appendString:[NSString stringWithFormat:@"Info               : %ld key/value pairs\n", [info count]]];
    
    return description;
}

- (void)setObject:(id)anObject forKey:(NSString *)aKey
{
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
        key = nil;
        info = [NSMutableDictionary new];
        originalClassString = nil;
    }
    
    return self;
}

#pragma mark -

- (id)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)aDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)aStore
{
    // We allow a nil dictionary because: 1) it's interpreted as empty and 2) reduces memory consumption on the caller if no data is being passed.
    
    if (nil == aKey)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: aKey is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    if ((self = [self init])) {
        [info addEntriesFromDictionary:aDictionary];
        key = [aKey copy];
    }
    
    return self;
}

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
