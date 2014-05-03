//
//  NanoStoreObjectTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 10/14/10.
//  Copyright (c) 2013 Webbo, Inc. All rights reserved.
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
    XCTAssertTrue (([key length] > 0), @"Expected key to be valid.");
    NSDictionary *info = nanoObject.info;
    XCTAssertTrue ((nil == info) && ([info count] == 0), @"Expected info to be valid.");
    NSString *originalClassString = nanoObject.originalClassString;
    XCTAssertTrue ((nil == originalClassString), @"Expected originalClassString to be valid.");
}

- (void)testObjectForUUID
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSString *objectKey = [nanoObject nanoObjectKey];
    XCTAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected key to be valid.");
    
    objectKey = [nanoObject key];
    XCTAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
    
    nanoObject = [[NSFNanoObject alloc]initFromDictionaryRepresentation:_defaultTestInfo];
    objectKey = [nanoObject nanoObjectKey];
    XCTAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
    
    objectKey = [nanoObject key];
    XCTAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the NanoObject to return a valid UUID.");
}

- (void)testSetObjectForKey
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSString *key = nanoObject.key;
    XCTAssertTrue (([key length] > 0), @"Expected key to be valid.");
    [nanoObject setObject:@"bar" forKey:@"foo"];
    NSString *value = [nanoObject objectForKey:@"foo"];
    XCTAssertTrue (([value isEqualToString:@"bar"]), @"Expected setObject:forKey: to succeed.");
}

- (void)testHonorExternalKey
{
    NSString *externalKey = @"fooBar";
    NSFNanoObject *nanoObject = [[NSFNanoObject alloc]initNanoObjectFromDictionaryRepresentation:_defaultTestInfo forKey:externalKey store:nil];
    NSString *key = nanoObject.key;
    XCTAssertTrue (([key isEqualToString:externalKey]), @"Expected the external key to prevail.");
}

- (void)testHonorExternalKey2
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo key:@"fooBar"];
    NSString *key = nanoObject.key;
    XCTAssertTrue (([key isEqualToString:@"fooBar"]), @"Expected the external key to prevail.");
}

- (void)testAddEntriesFromDictionary
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObject];
    NSString *key = nanoObject.key;
    XCTAssertTrue (([key length] > 0), @"Expected key to be valid.");
    [nanoObject addEntriesFromDictionary:_defaultTestInfo];
    NSDictionary *info = nanoObject.info;
    XCTAssertTrue ((nil != info) && ([info count] > 0), @"Expected info to be valid.");
    XCTAssertTrue ([info isEqualToDictionary:_defaultTestInfo], @"Expected info to be equal to _defaultTestInfo.");
}

- (void)testAddEntriesFromDictionary2
{
    NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo key:@"fooBar"];
    NSDictionary *info = nanoObject.info;
    XCTAssertTrue ((nil != info) && ([info count] > 0), @"Expected info to be valid.");
    XCTAssertTrue ([info isEqualToDictionary:_defaultTestInfo], @"Expected info to be equal to _defaultTestInfo.");
}

- (void)testObjectWithEmptyDictionary
{
    NSFNanoObject *object = nil;
    @try {
        object = [NSFNanoObject nanoObjectWithDictionary:[NSDictionary dictionary]];
    } @catch (NSException *e) {
        XCTAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testObjectWithRegularDictionary
{
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSDictionary *retrievedInfo = [object dictionaryRepresentation];
    
    XCTAssertTrue ((nil != object) && [retrievedInfo isEqualToDictionary:_defaultTestInfo], @"Expected: output dictionary == input dictionary.");
}

#pragma mark -

- (void)testObjectSetObjectForKeyNonEmptyObject
{
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [object setObject:@"bar" forKey:@"foo"];
    NSDictionary *info = object.info;

    XCTAssertTrue ((nil != info) && ([info count] == 8) && ([[info objectForKey:@"foo"]isEqualToString:@"bar"]), @"Expected setObject:forKey: to work.");
}

- (void)testObjectSetObjectForKeyEmptyObject
{
    NSFNanoObject *object = [NSFNanoObject nanoObject];
    [object setObject:@"bar" forKey:@"foo"];
    NSDictionary *info = object.info;
    
    XCTAssertTrue ((nil != info) && ([info count] == 1) && ([[info objectForKey:@"foo"]isEqualToString:@"bar"]), @"Expected setObject:forKey: to work.");
}

- (void)testObjectRemoveObjectForKeyNonEmptyObject
{
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [object setObject:@"bar" forKey:@"foo"];
    [object removeObjectForKey:@"foo"];
    NSDictionary *info = object.info;
    
    XCTAssertTrue ((nil != info) && ([info count] == 7) && (nil == [info objectForKey:@"foo"]), @"Expected removeObjectForKey: to work.");
}

- (void)testObjectRemoveObjectForKeyEmptyObject
{
    NSFNanoObject *object = [NSFNanoObject nanoObject];
    [object setObject:@"bar" forKey:@"foo"];
    [object removeObjectForKey:@"foo"];
    NSDictionary *info = object.info;
    
    XCTAssertTrue ((nil != info) && ([info count] == 0) && (nil == [info objectForKey:@"foo"]), @"Expected removeObjectForKey: to work.");
}

#pragma mark -

- (void)testBagCopyNanoObject
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *copiedObject = [object copy];
    
    XCTAssertTrue (([object isEqualToNanoObject:copiedObject]), @"Equality test should have succeeded.");
}

- (void)testSaveObject
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:@{@"foo" : @"bar"}];
    
    XCTAssertTrue (nil == [object store], @"Expected the object store to be nil.");

    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:object, nil] error:nil];
    
    XCTAssertTrue (nil != [object store], @"Expected the object store to be valid.");
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:object.key];
    NSFNanoObject *foundObject = [[[search searchObjectsWithReturnType:NSFReturnObjects error:nil]allValues]lastObject];
    
    NSDate *now = [NSDate new];
    [foundObject setObject:now forKey:@"Date"];
    NSError *error = nil;
    BOOL success = [foundObject saveStoreAndReturnError:&error];
    XCTAssertTrue (success && (nil == error), @"Expected to save the object.");

    foundObject = [[[search searchObjectsWithReturnType:NSFReturnObjects error:nil]allValues]lastObject];
    XCTAssertTrue ([[foundObject objectForKey:@"Date"]isEqualToDate:now], @"Expected to find the right object.");

    [nanoStore closeWithError:nil];
}

#pragma mark -

- (void)testHasUnsavedChangesInit
{
    NSFNanoObject *object = [NSFNanoObject new];
    XCTAssertTrue (NO == object.hasUnsavedChanges, @"Expected hasUnsavedChangesto be NO.");
}

- (void)testHasUnsavedChangesNanoObjectWithDictionary
{
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:@{@"foo" : @"bar"}];
    XCTAssertTrue (YES == object.hasUnsavedChanges, @"Expected hasUnsavedChangesto be YES.");
}

- (void)testHasUnsavedChangesAddEntriesFromDictionary
{
    NSFNanoObject *object = [NSFNanoObject new];
    [object addEntriesFromDictionary:@{@"foo" : @"bar"}];
    XCTAssertTrue (YES == object.hasUnsavedChanges, @"Expected hasUnsavedChangesto be YES.");
}

- (void)testHasUnsavedChangesSetObjectForKey
{
    NSFNanoObject *object = [NSFNanoObject new];
    [object setObject:@"bar" forKey:@"foo"];
    XCTAssertTrue (YES == object.hasUnsavedChanges, @"Expected hasUnsavedChangesto be YES.");
}

- (void)testHasUnsavedChangesRemoveObjectForKey
{
    NSFNanoObject *object = [NSFNanoObject new];
    [object setObject:@"bar" forKey:@"foo"];
    [object removeObjectForKey:@"foo"];
    XCTAssertTrue (YES == object.hasUnsavedChanges, @"Expected hasUnsavedChangesto be YES.");
}

- (void)testHasUnsavedChangesRemoveAllObjects
{
    NSFNanoObject *object = [NSFNanoObject new];
    [object removeAllObjects];
    XCTAssertTrue (YES == object.hasUnsavedChanges, @"Expected hasUnsavedChangesto be YES.");
}

- (void)testHasUnsavedChangesRemoveObjectsForKeys
{
    NSFNanoObject *object = [NSFNanoObject new];
    [object removeObjectsForKeys:@[@"foo"]];
    XCTAssertTrue (YES == object.hasUnsavedChanges, @"Expected hasUnsavedChangesto be YES.");
}

- (void)testHasUnsavedChangesSaveStoreIntervalOne
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:@{@"foo" : @"bar"}];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:object, nil] error:nil];
    
    NSError *error = nil;
    BOOL success = [object saveStoreAndReturnError:&error];
    XCTAssertTrue (success && (nil == error), @"Expected to save the object.");
    XCTAssertTrue (NO == object.hasUnsavedChanges, @"Expected hasUnsavedChangesto be NO.");
    
    [nanoStore closeWithError:nil];
}

- (void)testHasUnsavedChangesSaveStoreIntervalFive
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore setSaveInterval:5];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:@{@"foo" : @"bar"}];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:object, nil] error:nil];
    
    NSError *error = nil;
    BOOL success = [object saveStoreAndReturnError:&error];
    XCTAssertTrue (!success && (nil == error), @"Expected to not save the object.");
    XCTAssertTrue (YES == object.hasUnsavedChanges, @"Expected hasUnsavedChangesto be NO.");
    
    [nanoStore closeWithError:nil];
}

@end
