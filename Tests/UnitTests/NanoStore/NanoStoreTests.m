//
//  NanoStoreTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 3/12/08.
//  Copyright (c) 2013 Webbo, Inc. All rights reserved.
//

#import "NanoStore.h"
#import "NanoStoreTests.h"
#import "NSFNanoStore_Private.h"
#import "NSFNanoGlobals_Private.h"

@implementation NanoStoreTests

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

- (void)testCreateStore
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue (nanoStore != nil, @"Expected the database to exist.");
}

- (void)testOpenAndCloseStore
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    BOOL test1 = [nanoStore isClosed];
    [nanoStore openWithError:nil];
    BOOL test2 = [nanoStore isClosed];
    [nanoStore closeWithError:nil];
    BOOL test3 = [nanoStore isClosed];
    
    BOOL success = ((test1 == YES) && (test2 == NO) && (test3 == YES));

    [nanoStore closeWithError:nil];
    
    XCTAssertTrue (success == YES, @"Expected store file path to match.");
}

- (void)testStoreFilePath
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFPersistentStoreType path:@"foo"];
    
    NSString *filePath = [nanoStore filePath];
    
    [nanoStore closeWithError:nil];

    XCTAssertTrue ([filePath isEqualToString:@"foo"] == YES, @"Expected store file path to match.");
}

- (void)testStoreInMemoryFilePath
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    NSString *filePath = [nanoStore filePath];

    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([filePath isEqualToString:NSFMemoryDatabase], @"Expected store file path to be '%@'.", NSFMemoryDatabase);
}

- (void)testStoreDescriptionOutsideAutoreleasePool
{
    NSFNanoStore *nanoStore = nil;
    BOOL success = YES;
    
    @try {
        @autoreleasepool {
            nanoStore = [NSFNanoStore createStoreWithType:NSFPersistentStoreType path:@"foo"];
        }
        
        // We should be able to obtain the description here without causing a crash...
        [nanoStore description];
    }
    @catch (NSException *exception) {
        success = NO;
    }
    @finally {
        [nanoStore closeWithError:nil];
    }
    
    XCTAssertTrue (success, @"Expected the store description to be available outside the autoreleasepool.");
}

- (void)testNanoEngineProcessingModeAccessor
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    NSFEngineProcessingMode mode = nanoStore.nanoEngineProcessingMode;
    XCTAssertTrue (NSFEngineProcessingDefaultMode == mode, @"Expected accessor to return the proper value.");

    nanoStore.nanoEngineProcessingMode = NSFEngineProcessingFastMode;
    mode = nanoStore.nanoEngineProcessingMode;
    XCTAssertTrue (NSFEngineProcessingFastMode == mode, @"Expected accessor to return the proper value.");

    [nanoStore closeWithError:nil];
}

- (void)testSaveIntervalAccessor
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    NSUInteger value = 23570;
    
    nanoStore.saveInterval = value;
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([nanoStore saveInterval] == value, @"Expected accessor to return the proper value.");
}

- (void)testHasUnsavedChangesDefault
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    XCTAssertTrue (NO == [nanoStore hasUnsavedChanges], @"Did not expect unsaved changes.");
    
    // Close the document store
    [nanoStore closeWithError:nil];
}

- (void)testHasUnsavedChangesOneChange
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    // Add some data to the document store
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:object error:nil];
    
    XCTAssertTrue (YES == [nanoStore hasUnsavedChanges], @"Expected unsaved changes.");
    
    // Close the document store
    [nanoStore closeWithError:nil];
}

- (void)testHasUnsavedChangesSaveInterval100
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    nanoStore.saveInterval = 100;
    
    // Add some data to the document store
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:object error:nil];
    
    XCTAssertTrue ([nanoStore hasUnsavedChanges], @"Expected unsaved changes.");
    
    // Close the document store
    [nanoStore closeWithError:nil];
}

- (void)testHasUnsavedChangesDiscardChanges
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    nanoStore.saveInterval = 100;
    
    // Add some data to the document store
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:object error:nil];
    
    [nanoStore discardUnsavedChanges];
    XCTAssertTrue (NO == [nanoStore hasUnsavedChanges], @"Did not expect unsaved changes.");
    
    // Close the document store
    [nanoStore closeWithError:nil];
}

#pragma mark -

- (void)testStoreObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:@[obj1, obj2] error:nil];
    
    NSFNanoSearch *search1 = [NSFNanoSearch searchWithStore:nanoStore];
    search1.key = obj1.key;
    NSArray *keys1 = [search1 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    NSFNanoSearch *search2 = [NSFNanoSearch searchWithStore:nanoStore];
    search2.key = obj2.key;
    NSArray *keys2 = [search2 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue (([keys1 count] + [keys2 count] == 2), @"Expected to find two stored objects.");
}

- (void)testSaveObjectsInBatch
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    nanoStore.saveInterval = 1000;
    NSError *error = nil;
    [nanoStore addObject:[NSFNanoObject nanoObjectWithDictionary:@{@"foo" : @"bar"}] error:&error];
    XCTAssertTrue(nil == error, @"expected to add the object without complications.");
    [nanoStore addObject:[NSFNanoObject nanoObjectWithDictionary:@{@"foo2" : @"bar2"}] error:&error];
    XCTAssertTrue(nil == error, @"expected to add the object without complications.");
    BOOL success = [nanoStore saveStoreAndReturnError:&error];
    XCTAssertTrue(success && (nil == error), @"expected to save the objects.");
    XCTAssertTrue(2 == [nanoStore countOfObjectsOfClassNamed:@"NSFNanoObject"], @"should save 2 objects in a batch");
    [nanoStore closeWithError:nil];
}

- (void)testStoreMultipleObjectsWithSameKey
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj4 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj5 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:@[obj1, obj2, obj3, obj4, obj5] error:nil];

    NSFNanoSearch *search1 = [NSFNanoSearch searchWithStore:nanoStore];
    search1.key = obj1.key;
    NSArray *keys1 = [search1 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    NSFNanoSearch *search2 = [NSFNanoSearch searchWithStore:nanoStore];
    search2.key = obj2.key;
    NSArray *keys2 = [search2 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    NSFNanoSearch *search3 = [NSFNanoSearch searchWithStore:nanoStore];
    search3.key = obj3.key;
    NSArray *keys3 = [search3 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue (([keys1 count] + [keys2 count] + [keys3 count]== 3), @"Expected to find three stored objects.");
}

- (void)testStoreObjectWithPeriodInDictionaryKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    @try {
        [nanoStore addObjectsFromArray:@[[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    } @catch (NSException *e) {
        XCTAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testStoreObjectsWithNilKeyAttributeAndValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:@[[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyBadAttributeAndValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1.key;
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyGoodAttributeAndBadValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1.key;
    search.attribute = @"Countries.France.Nice";
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyAttributeAndValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1.key;
    search.attribute = @"Countries.France.Nice";
    search.value = @"Cassoulet";
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyBadAttributeAndGoodValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1.key;
    search.value = @"Cassoulet";
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyGoodAttributeAndBadValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"Countries.France.Nice";
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyGoodAttributeAndGoodValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"Countries.France.Nice";
    search.value = @"Cassoulet";
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyBadAttributeAndGoodValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.value = @"Cassoulet";
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testAddAndRemoveObject
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    // Verify that the object was added properly
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
    XCTAssertTrue (([searchResults count] == 1), @"Expected to find one object.");

    // Remove the object from the store
    [nanoStore removeObject:obj1 error:nil];

    // Verify that the object was removed properly
    searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue (([searchResults count] == 0), @"Expected to find zero objects.");
}

- (void)testUpdateObject
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSString *obj1Key = [obj1 nanoObjectKey];
    [nanoStore addObject:obj1 error:nil];
    
    // Update the object and save it
    obj1[@"SomeKey"] = @"foo";
    [nanoStore addObject:obj1 error:nil];
     
    // Verify that the object was updated properly
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1Key;
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    XCTAssertTrue (([searchResults count] == 1), @"Expected to find one object.");

    NSFNanoObject *returnedObject = searchResults[searchResults.allKeys.lastObject];
    
    [nanoStore closeWithError:nil];

    XCTAssertTrue ([[returnedObject info][@"SomeKey"]isEqualToString:@"foo"], @"Expected to find the updated information.");
}

- (void)testRemoveObjectForKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    
    [nanoStore addObjectsFromArray:@[obj1, obj2] error:nil];
    [nanoStore removeObjectsWithKeysInArray:@[obj1.key, obj2.key] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue (([searchResults count] == 0), @"Expected to find zero objects.");
}

- (void)testObjectsWithKeysInArray
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoBag *bag = [NSFNanoBag bag];
    [bag addObjectsFromArray:@[obj1, obj2, obj3] error:nil];
    
    [nanoStore addObjectsFromArray:@[bag] error:nil];

    NSArray *objects = [nanoStore objectsWithKeysInArray:@[bag.key, obj3.key]];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue (([objects count] == 2), @"Expected to find two objects.");
}

#pragma mark -

- (void)testStoreObjectsWithBadKeyBadAttributeBadValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attributesToBeReturned = @[@"FirstName", @"LastName"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    NSUInteger objectCount = searchResults.count;
    NSUInteger attributesCount = search.attributesToBeReturned.count + 1;
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ((objectCount == 1) && (attributesCount == 3), @"Expected to find one object with three attributes.");
}

- (void)testStoreObjectsWithGoodKeyBadAttributeAndValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1.key;
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyGoodAttributeAndBadValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1.key;
    search.attribute = @"Countries.France.Nice";
    search.attributesToBeReturned = @[@"FirstName", @"LastName"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyAttributeAndValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1.key;
    search.attribute = @"Countries.France.Nice";
    search.value = @"Cassoulet";
    search.attributesToBeReturned = @[@"FirstName", @"LastName"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyBadAttributeAndGoodValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1.key;
    search.value = @"Cassoulet";
    search.attributesToBeReturned = @[@"FirstName", @"LastName"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyGoodAttributeAndBadValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"Countries.France.Nice";
    search.attributesToBeReturned = @[@"FirstName", @"LastName"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyGoodAttributeAndGoodValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"Countries.France.Nice";
    search.value = @"Cassoulet";
    search.attributesToBeReturned = @[@"FirstName", @"LastName"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyBadAttributeAndGoodValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.value = @"Cassoulet";
    search.attributesToBeReturned = @[@"FirstName", @"LastName"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

#pragma mark -

- (void)testAllObjectClasses
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];

    NSFNanoBag *bag = [NSFNanoBag bag];
    [bag addObjectsFromArray:@[obj1, obj2, obj3] error:nil];
    
    [nanoStore addObjectsFromArray:@[bag] error:nil];
    
    NSArray *classNames = [nanoStore allObjectClasses];
    
    XCTAssertTrue ([classNames count] == 2, @"Expected to find two class names.");
}

- (void)testObjectsOfClassNamed
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    [bag addObjectsFromArray:@[obj1, obj2, obj3] error:nil];
    
    [nanoStore addObjectsFromArray:@[bag] error:nil];
    
    NSArray *classNames = [nanoStore objectsOfClassNamed:@"NSFNanoBag"];
    XCTAssertTrue ([classNames count] == 1, @"Expected to find one object of class NSFNanoBag.");
}

- (void)testObjectsOfClassNamedSorted
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bagA = [NSFNanoBag bagWithName:@"London"];
    NSFNanoBag *bagB = [NSFNanoBag bagWithName:@"Paris"];
    NSFNanoBag *bagC = [NSFNanoBag bagWithName:@"New York"];
    NSFNanoBag *bagD = [NSFNanoBag bagWithName:@"San Francisco"];

    [nanoStore addObjectsFromArray:@[bagA, bagB, bagC, bagD] error:nil];
    
    NSFNanoSortDescriptor *sortDescriptor = [NSFNanoSortDescriptor sortDescriptorWithAttribute:@"name" ascending:YES];
    NSArray *classNames = [nanoStore objectsOfClassNamed:@"NSFNanoBag" usingSortDescriptors:@[sortDescriptor]];
    
    XCTAssertTrue ([classNames count] == 4, @"Expected to find four objects of class NSFNanoBag.");
    XCTAssertTrue ([[classNames[0]name]isEqualToString:@"London"], @"Expected to find London in the first index.");
    XCTAssertTrue ([[classNames[1]name]isEqualToString:@"New York"], @"Expected to find New York in the second index.");
    XCTAssertTrue ([[classNames[2]name]isEqualToString:@"Paris"], @"Expected to find London in the third index.");
    XCTAssertTrue ([[classNames[3]name]isEqualToString:@"San Francisco"], @"Expected to find London in the fourth index.");
}

- (void)testObjectsOfClassNamedVerifyReturnType
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    [bag addObjectsFromArray:@[obj1, obj2, obj3] error:nil];
    
    [nanoStore addObjectsFromArray:@[bag] error:nil];
    
    NSArray *classNames = [nanoStore objectsOfClassNamed:@"NSFNanoBag"];
    XCTAssertTrue ([classNames isKindOfClass:[NSArray class]], @"Expected the results to be of type array.");
}

- (void)testObjectsOfClassNamedSortedVerifyReturnType
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bagA = [NSFNanoBag bagWithName:@"London"];
    NSFNanoBag *bagB = [NSFNanoBag bagWithName:@"Paris"];
    NSFNanoBag *bagC = [NSFNanoBag bagWithName:@"New York"];
    NSFNanoBag *bagD = [NSFNanoBag bagWithName:@"San Francisco"];
    
    [nanoStore addObjectsFromArray:@[bagA, bagB, bagC, bagD] error:nil];
    
    NSFNanoSortDescriptor *sortDescriptor = [NSFNanoSortDescriptor sortDescriptorWithAttribute:@"name" ascending:YES];
    NSArray *classNames = [nanoStore objectsOfClassNamed:@"NSFNanoBag" usingSortDescriptors:@[sortDescriptor]];
    
    XCTAssertTrue ([classNames isKindOfClass:[NSArray class]], @"Expected the results to be of type array.");
}

- (void)testCountOfObjectsOfClassNamed
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bagA = [NSFNanoBag bagWithName:@"London"];
    NSFNanoBag *bagB = [NSFNanoBag bagWithName:@"Paris"];
    NSFNanoBag *bagC = [NSFNanoBag bagWithName:@"New York"];
    NSFNanoBag *bagD = [NSFNanoBag bagWithName:@"San Francisco"];
    
    [nanoStore addObjectsFromArray:@[bagA, bagB, bagC, bagD] error:nil];
    
    long long count = [nanoStore countOfObjectsOfClassNamed:@"NSFNanoBag"];
    
    XCTAssertTrue (count == 4, @"Expected to find four objects of class NSFNanoBag.");
}

- (void)testCountOfbjectsOfClassNamedEmptyStore
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    long long count = [nanoStore countOfObjectsOfClassNamed:@"NSFNanoBag"];
    
    XCTAssertTrue (count == 0, @"Expected to find zero objects in the store.");
}

- (void)testCountOfbjectsOfClassNamedWithWrongName
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bagA = [NSFNanoBag bagWithName:@"London"];
    NSFNanoBag *bagB = [NSFNanoBag bagWithName:@"Paris"];
    NSFNanoBag *bagC = [NSFNanoBag bagWithName:@"New York"];
    NSFNanoBag *bagD = [NSFNanoBag bagWithName:@"San Francisco"];
    
    [nanoStore addObjectsFromArray:@[bagA, bagB, bagC, bagD] error:nil];
    
    long long count = [nanoStore countOfObjectsOfClassNamed:@"NSFNanoBagFoo"];
    
    XCTAssertTrue (count == 0, @"Expected to find zero objects of class NSFNanoBagFoo.");
}

- (void)testRemoveAllObjectsStore
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:@[obj1, obj2] error:nil];
    
    NSString  *theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@;", NSFKeys];
    NSFNanoResult *result = [nanoStore _executeSQL:theSQLStatement];
    long long numObjects = [result firstValue].longLongValue;
    
    theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@;", NSFValues];
    result = [nanoStore _executeSQL:theSQLStatement];
    long long numValues = [result firstValue].longLongValue;
    
    XCTAssertTrue (numObjects + numValues > 0, @"Expected to find objects.");

    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@;", NSFKeys];
    result = [nanoStore _executeSQL:theSQLStatement];
    numObjects = [result firstValue].longLongValue;
    
    theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@;", NSFValues];
    result = [nanoStore _executeSQL:theSQLStatement];
    numValues = [result firstValue].longLongValue;
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue (numObjects + numValues == 0, @"Expected to find zero objects.");
}

- (void)testClearIndexes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    [nanoStore clearIndexesAndReturnError:nil];

    NSFNanoEngine *nsfdb = nanoStore.nanoStoreEngine;
    NSArray *indexes = [nsfdb indexes];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([indexes count] == 0, @"Expected all indexes to be cleared.");
}

- (void)testRebuildIndexes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    [nanoStore clearIndexesAndReturnError:nil];
    [nanoStore rebuildIndexesAndReturnError:nil];
    
    NSFNanoEngine *nsfdb = nanoStore.nanoStoreEngine;
    NSArray *indexes = [nsfdb indexes];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue ([indexes count] > 0, @"Expected the indexes to be rebuilt.");
}

#pragma mark -

- (void)testNanoStoreEngineDatabase
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    BOOL test1 = (nanoStore.nanoStoreEngine != nil);
    [nanoStore openWithError:nil];
    BOOL test2 = (nanoStore.nanoStoreEngine != nil);
    
    [nanoStore closeWithError:nil];
    BOOL test3 = (nil == nanoStore.nanoStoreEngine);
    
    XCTAssertTrue ((test1 && test2 && (NO == test3)) == YES, @"Expected all tests against NSFNanoEngine to succeed.");
}

- (void)testStoreNSNullObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:@{@"aNull" : [NSNull null]}];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:@{@"bNull" : [NSNull null]}];
    [nanoStore addObjectsFromArray:@[obj1, obj2] error:nil];
    
    NSFNanoSearch *search1 = [NSFNanoSearch searchWithStore:nanoStore];
    search1.key = obj1.key;
    NSArray *keys1 = [search1 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    NSFNanoSearch *search2 = [NSFNanoSearch searchWithStore:nanoStore];
    search2.key = obj2.key;
    NSArray *keys2 = [search2 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    XCTAssertTrue (([keys1 count] + [keys2 count] == 2), @"Expected to find two null stored objects.");
}

- (void)testStoreNSURLObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSURL *url1 = [NSURL URLWithString:@"https://github.com/tciuro/NanoStore"];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:@{@"aURL" : url1}];
    NSURL *url2 = [NSURL URLWithString:@"http://www.apple.com"];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:@{@"bURL" : url2}];
    [nanoStore addObjectsFromArray:@[obj1, obj2] error:nil];
    
    NSFNanoSearch *search1 = [NSFNanoSearch searchWithStore:nanoStore];
    search1.key = obj1.key;
    NSDictionary *objects1 = [search1 searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    NSFNanoSearch *search2 = [NSFNanoSearch searchWithStore:nanoStore];
    search2.key = obj2.key;
    NSDictionary *objects2 = [search2 searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    NSURL *retrievedURL1 = objects1.allValues.lastObject[@"aURL"];
    NSURL *retrievedURL2 = objects2.allValues.lastObject[@"bURL"];

    XCTAssertTrue ([[url1 absoluteString]isEqualToString:[retrievedURL1 absoluteString]], @"Expected to find aURL.");
    XCTAssertTrue ([[url2 absoluteString]isEqualToString:[retrievedURL2 absoluteString]], @"Expected to find bURL.");
}

- (void)testBagSearch
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:@{@"FirstName" : @"Tito"}];
    [nanoStore addObjectsFromArray:@[obj1, obj2, obj3] error:nil];
    
    NSArray *objects = @[[NSFNanoObject nanoObjectWithDictionary:@{@"FirstName" : @"Tito", @"foo" : @"bar"}],
                        [NSFNanoObject nanoObjectWithDictionary:@{@"FirstName" : @"Jane"}]];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    BOOL success = [bag addObjectsFromArray:objects error:nil];
    XCTAssertTrue (success, @"Expected the bag to hold the objects.");
    
    [nanoStore addObjectsFromArray:@[bag] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"FirstName";
    search.match = NSFEqualTo;
    search.value = @"Tito";
    search.bag = bag;
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    NSFNanoObject *retrievedObject = searchResults.allValues.lastObject;
    XCTAssertTrue ([searchResults count] == 1, @"Expected to find one object. while found %lu",(unsigned long)[searchResults count]);
    XCTAssertTrue ([retrievedObject[@"foo"]isEqualToString:@"bar"], @"Expected to find the proper object inside the bag.");
}

@end
