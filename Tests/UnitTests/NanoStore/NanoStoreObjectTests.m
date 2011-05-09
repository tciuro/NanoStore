//
//  NanoStoreObjectTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 10/14/10.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

#import "NanoStore.h"
#import "NanoStoreObjectTests.h"
#import "NSFNanoStore_Private.h"

@implementation NanoStoreObjectTests

- (void)setUp
{
    [super setUp];
    
    _defaultTestInfo = [[NSFNanoStore _defaultTestData]retain];
    
    NSFSetIsDebugOn (NO);
}

- (void)tearDown
{
    [_defaultTestInfo release];
    
    NSFSetIsDebugOn (NO);
    
    [super tearDown];
}

#pragma mark -

- (void)testObjectEmptyNanoObject
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObject];
    NSString *objectKey = [nanoObject nanoObjectKey];
    STAssertTrue (([objectKey length] > 0) && (nil != nanoObject), @"Expected the NanoObject to be valid.");
}

- (void)testObjectForUUID
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSString *objectKey = [nanoObject nanoObjectKey];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
    
    objectKey = [nanoObject key];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
    
    nanoObject = [[[NSFNanoObject alloc]initFromDictionaryRepresentation:_defaultTestInfo]autorelease];
    objectKey = [nanoObject nanoObjectKey];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
    
    objectKey = [nanoObject key];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
}

- (void)testObjectWithRegularKey
{
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSString *retrievedKey = [object nanoObjectKey];
    
    STAssertTrue ((nil != object) && ([retrievedKey length] > 0), @"Expected a valid object key.");
}

- (void)testObjectWithEmptyDictionary
{
    NSFNanoObject *object = nil;
    @try {
        object = [NSFNanoObject nanoObjectWithDictionary:[NSDictionary dictionary]];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testObjectWithRegularDictionary
{
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSDictionary *retrievedInfo = [object dictionaryRepresentation];
    
    STAssertTrue ((nil != object) && [retrievedInfo isEqualToDictionary:_defaultTestInfo], @"Expected: output dictionary == input dictionary.");
}

#pragma mark -

- (void)testObjectSetObjectForKeyNonEmptyObject
{
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [object setObject:@"bar" forKey:@"foo"];
    NSDictionary *info = object.info;

    STAssertTrue ((nil != info) && ([info count] == 6) && ([[info objectForKey:@"foo"]isEqualToString:@"bar"]), @"Expected setObject:forKey: to work.");
}

- (void)testObjectSetObjectForKeyEmptyObject
{
    NSFNanoObject *object = [NSFNanoObject nanoObject];
    [object setObject:@"bar" forKey:@"foo"];
    NSDictionary *info = object.info;
    
    STAssertTrue ((nil != info) && ([info count] == 1) && ([[info objectForKey:@"foo"]isEqualToString:@"bar"]), @"Expected setObject:forKey: to work.");
}

- (void)testObjectRemoveObjectForKeyNonEmptyObject
{
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [object setObject:@"bar" forKey:@"foo"];
    [object removeObjectForKey:@"foo"];
    NSDictionary *info = object.info;
    
    STAssertTrue ((nil != info) && ([info count] == 5) && (nil == [info objectForKey:@"foo"]), @"Expected removeObjectForKey: to work.");
}

- (void)testObjectRemoveObjectForKeyEmptyObject
{
    NSFNanoObject *object = [NSFNanoObject nanoObject];
    [object setObject:@"bar" forKey:@"foo"];
    [object removeObjectForKey:@"foo"];
    NSDictionary *info = object.info;
    
    STAssertTrue ((nil != info) && ([info count] == 0) && (nil == [info objectForKey:@"foo"]), @"Expected removeObjectForKey: to work.");
}

#pragma mark -

- (void)testBagCopyNanoObject
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *copiedObject = [[object copy]autorelease];
    
    STAssertTrue ((YES == [object isEqualToNanoObject:copiedObject]), @"Equality test should have succeeded.");
}

@end
