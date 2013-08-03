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
    
    _defaultTestInfo = [NSFNanoStore _defaultTestData];
    
    NSFSetIsDebugOn (NO);
}

- (void)tearDown
{
    
    NSFSetIsDebugOn (NO);
    
    [super tearDown];
}

#pragma mark -

- (void)testObjectEmptyNanoObject
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObject];
    NSString *key = nanoObject.key;
    STAssertTrue (([key length] > 0), @"Expected key to be valid.");
    NSDictionary *info = nanoObject.info;
    STAssertTrue ((nil == info) && ([info count] == 0), @"Expected info to be valid.");
    NSString *originalClassString = nanoObject.originalClassString;
    STAssertTrue ((nil == originalClassString), @"Expected originalClassString to be valid.");
}

- (void)testObjectForUUID
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSString *objectKey = [nanoObject nanoObjectKey];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected key to be valid.");
    
    objectKey = [nanoObject key];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
    
    nanoObject = [[NSFNanoObject alloc]initFromDictionaryRepresentation:_defaultTestInfo];
    objectKey = [nanoObject nanoObjectKey];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
    
    objectKey = [nanoObject key];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
}

- (void)testSetObjectForKey
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSString *key = nanoObject.key;
    STAssertTrue (([key length] > 0), @"Expected key to be valid.");
    [nanoObject setObject:@"bar" forKey:@"foo"];
    NSString *value = [nanoObject objectForKey:@"foo"];
    STAssertTrue (([value isEqualToString:@"bar"]), @"Expected setObject:forKey: to succeed.");
}

- (void)testHonorExternalKey
{
    NSString *externalKey = @"fooBar";
    NSFNanoObject *nanoObject = [[NSFNanoObject alloc]initNanoObjectFromDictionaryRepresentation:_defaultTestInfo forKey:externalKey store:nil];
    NSString *key = nanoObject.key;
    STAssertTrue (([key isEqualToString:externalKey]), @"Expected the external key to prevail.");
}

- (void)testHonorExternalKey2
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo key:@"fooBar"];
    NSString *key = nanoObject.key;
    STAssertTrue (([key isEqualToString:@"fooBar"]), @"Expected the external key to prevail.");
}

- (void)testAddEntriesFromDictionary
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObject];
    NSString *key = nanoObject.key;
    STAssertTrue (([key length] > 0), @"Expected key to be valid.");
    [nanoObject addEntriesFromDictionary:_defaultTestInfo];
    NSDictionary *info = nanoObject.info;
    STAssertTrue ((nil != info) && ([info count] > 0), @"Expected info to be valid.");
    STAssertTrue ([info isEqualToDictionary:_defaultTestInfo], @"Expected info to be equal to _defaultTestInfo.");
}

- (void)testAddEntriesFromDictionary2
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo key:@"fooBar"];
    NSDictionary *info = nanoObject.info;
    STAssertTrue ((nil != info) && ([info count] > 0), @"Expected info to be valid.");
    STAssertTrue ([info isEqualToDictionary:_defaultTestInfo], @"Expected info to be equal to _defaultTestInfo.");
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

    STAssertTrue ((nil != info) && ([info count] == 8) && ([[info objectForKey:@"foo"]isEqualToString:@"bar"]), @"Expected setObject:forKey: to work.");
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
    
    STAssertTrue ((nil != info) && ([info count] == 7) && (nil == [info objectForKey:@"foo"]), @"Expected removeObjectForKey: to work.");
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
    NSFNanoObject *copiedObject = [object copy];
    
    STAssertTrue (([object isEqualToNanoObject:copiedObject]), @"Equality test should have succeeded.");
}

- (void)testSaveObject
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:@{@"foo" : @"bar"}];
    
    STAssertTrue (nil == [object store], @"Expected the object store to be nil.");

    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:object, nil] error:nil];
    
    STAssertTrue (nil != [object store], @"Expected the object store to be valid.");
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:object.key];
    NSFNanoObject *foundObject = [[[search searchObjectsWithReturnType:NSFReturnObjects error:nil]allValues]lastObject];
    
    NSDate *now = [NSDate new];
    [foundObject setObject:now forKey:@"Date"];
    NSError *error = nil;
    BOOL success = [foundObject saveStoreAndReturnError:&error];
    STAssertTrue (success && (nil == error), @"Expected to save the object.");

    foundObject = [[[search searchObjectsWithReturnType:NSFReturnObjects error:nil]allValues]lastObject];
    STAssertTrue ([[foundObject objectForKey:@"Date"]isEqualToDate:now], @"Expected to find the right object.");

    [nanoStore closeWithError:nil];
}

@end
