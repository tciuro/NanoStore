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
#import "NSFNanoGlobals.h"
#import "NSFNanoGlobals_Private.h"
#import "NSFOrderedDictionary.h"

@interface NSFNanoObject ()
/** \cond */
@property (nonatomic, weak, readwrite) NSFNanoStore *store;
@property (nonatomic, copy, readwrite) NSString *key;
/** \endcond */
@end

@implementation NSFNanoObject
{
    NSMutableDictionary *_info;
}

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
            _key = aKey;
        }
        
        // Keep the dictionary if needed
        if (nil != aDictionary) {
            _info = [NSMutableDictionary new];
            [_info addEntriesFromDictionary:aDictionary];
        }
        
        _store = aStore;
    }
    
    return self;
}

- (void)setStore:(NSFNanoStore *)store
{
    _store = store;
}

- (NSString *)description
{
    return [self JSONDescription];
}

- (NSDictionary *)dictionaryDescription
{
    NSFOrderedDictionary *values = [NSFOrderedDictionary new];
    
    values[@"NanoObject address"] = [NSString stringWithFormat:@"%p", self];
    values[@"Original class"] = (nil != _originalClassString) ? _originalClassString : NSStringFromClass ([self class]);
    values[@"Key"] = _key;
    values[@"Property count"] = @([_info count]);
    values[@"Contents"] = _info;
    
    return values;
}

- (NSString *)JSONDescription
{
    NSDictionary *values = [self dictionaryDescription];
    
    NSError *outError = nil;
    NSString *description = [NSFNanoObject _NSObjectToJSONString:values error:&outError];
    
    return description;
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary
{
    // Allocate the dictionary if needed
    if (nil == _info) {
        _info = [NSMutableDictionary new];
    }
    
    [_info addEntriesFromDictionary:otherDictionary];
}

- (void)setObject:(id)anObject forKey:(NSString *)aKey
{
    // Allocate the dictionary if needed
    if (nil == _info) {
        _info = [NSMutableDictionary new];
    }
    
    [_info setObject:anObject forKey:aKey];
}

- (id)objectForKey:(NSString *)aKey
{
    return [_info objectForKey:aKey];
}

- (void)removeObjectForKey:(NSString *)aKey
{
    [_info removeObjectForKey:aKey];
}

- (void)removeAllObjects
{
    [_info removeAllObjects];
}

- (void)removeObjectsForKeys:(NSArray *)keyArray
{
    [_info removeObjectsForKeys:keyArray];
}

- (BOOL)isEqualToNanoObject:(NSFNanoObject *)otherNanoObject
{
    if (self == otherNanoObject) {
        return YES;
    }
    
    BOOL success = YES;
    
    if (_originalClassString != otherNanoObject.originalClassString) {
        if (NO == [_originalClassString isEqualToString:otherNanoObject.originalClassString]) {
            success = NO;
        }
    }
    
    if (YES == success) {
        success = [_info isEqualToDictionary:otherNanoObject.info];
    }
    
    return success;
}

- (BOOL)saveStoreAndReturnError:(out NSError **)outError
{
    [_store addObject:self error:outError];
    
    return [_store saveStoreAndReturnError:outError];
}

- (NSDictionary *)dictionaryRepresentation
{
    return self.info;
}

/** \cond */

- (id)init
{
    if ((self = [super init])) {
        _key = [NSFNanoEngine stringWithUUID];
        _info = nil;
        _originalClassString = nil;
        _store = nil;
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
    return _info;
}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (void)_setOriginalClassString:(NSString *)theClassString
{
    if (_originalClassString != theClassString) {
        _originalClassString = theClassString;
    }
}

+ (NSString *)_NSObjectToJSONString:(id)object error:(NSError **)error
{
    // Make sure we have a safe object
    object = [NSFNanoObject _safeObjectFromObject:object];
    
    NSError *tempError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&tempError];
    if (nil == tempError) {
        NSString *JSONInfo = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
        return JSONInfo;
    }
    
    if (*error) {
        *error = tempError;
    }
    
    return [tempError localizedDescription];
}

+ (id)_safeObjectFromObject:(id)object
{
    if ([object isKindOfClass:[NSArray class]]) {
        return [NSFNanoObject _safeArrayFromArray:object];
    }
    
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [NSFNanoObject _safeDictionaryFromDictionary:object];
    }
    
	NSArray *validClasses = @[ [NSString class], [NSNumber class], [NSNull class] ];
	for (Class c in validClasses) {
		if ([object isKindOfClass:c])
			return object;
	}
    
	if ([object isKindOfClass:[NSDate class]]) {
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
		[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		NSString *ISOString = [formatter stringFromDate:object];
		return ISOString;
	}
    
	return [object description];
}

+ (NSDictionary *)_safeDictionaryFromDictionary:(NSDictionary *)dictionary
{
	NSMutableDictionary *cleanDictionary = [NSMutableDictionary dictionary];
    
	for (NSString *theKey in [dictionary allKeys]) {
		id object = [dictionary objectForKey:theKey];
        
		if ([object isKindOfClass:[NSDictionary class]])
			[cleanDictionary setObject:[NSFNanoObject _safeDictionaryFromDictionary:object] forKey:theKey];
        
		else if ([object isKindOfClass:[NSArray class]])
			[cleanDictionary setObject:[NSFNanoObject _safeArrayFromArray:object] forKey:theKey];
        
		else
			[cleanDictionary setObject:[NSFNanoObject _safeObjectFromObject:object] forKey:theKey];
	}
    
	return cleanDictionary;
}

+ (NSArray *)_safeArrayFromArray:(NSArray *)array
{
	NSMutableArray *cleanArray = [NSMutableArray array];
    
	for (id object in array) {
		if ([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSSet class]])
			[cleanArray addObject:[NSFNanoObject _safeArrayFromArray:object]];
        
		else if ([object isKindOfClass:[NSDictionary class]])
			[cleanArray addObject:[NSFNanoObject _safeDictionaryFromDictionary:object]];
        
		else
			[cleanArray addObject:[NSFNanoObject _safeObjectFromObject:object]];
	}
    
	return cleanArray;
}

/** \endcond */

@end
