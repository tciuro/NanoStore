//
//  NanoStoreTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 3/12/08.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

#import "NanoStore.h"
#import "NanoStoreTests.h"
#import "NSFNanoStore_Private.h"
#import "NSFNanoGlobals_Private.h"

@implementation NanoStoreTests

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

- (void)testCreateStore
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (nanoStore != nil, @"Expected the database to exist.");
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
    
    STAssertTrue (success == YES, @"Expected store file path to match.");
}

- (void)testStoreFilePath
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFPersistentStoreType path:@"foo"];
    
    NSString *filePath = [nanoStore filePath];
    
    [nanoStore closeWithError:nil];

    STAssertTrue ([filePath isEqualToString:@"foo"] == YES, @"Expected store file path to match.");
}

- (void)testStoreInMemoryFilePath
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    NSString *filePath = [nanoStore filePath];

    [nanoStore closeWithError:nil];
    
    STAssertTrue ([filePath isEqualToString:NSFMemoryDatabase] == YES, [NSString stringWithFormat:@"Expected store file path to be '%@'.", NSFMemoryDatabase]);
}

- (void)testNanoEngineProcessingModeAccessor
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    NSFEngineProcessingMode mode = [nanoStore nanoEngineProcessingMode];
    STAssertTrue (NSFEngineProcessingDefaultMode == mode, @"Expected accessor to return the proper value.");

    [nanoStore setNanoEngineProcessingMode:NSFEngineProcessingFastMode];
    mode = [nanoStore nanoEngineProcessingMode];
    STAssertTrue (NSFEngineProcessingFastMode == mode, @"Expected accessor to return the proper value.");

    [nanoStore closeWithError:nil];
}

- (void)testSaveIntervalAccessor
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    NSUInteger value = 23570;
    
    [nanoStore setSaveInterval:value];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([nanoStore saveInterval] == value, @"Expected accessor to return the proper value.");
}

- (void)testHasUnsavedChangesDefault
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    // Add some data to the document store
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:object error:nil];
    
    STAssertTrue (NO == [nanoStore hasUnsavedChanges], @"Did not expect unsaved changes.");
    
    // Close the document store
    [nanoStore closeWithError:nil];
}

- (void)testHasUnsavedChangesSaveInterval100
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore setSaveInterval:100];
    
    // Add some data to the document store
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:object error:nil];
    
    STAssertTrue (YES == [nanoStore hasUnsavedChanges], @"Expected unsaved changes.");
    
    // Close the document store
    [nanoStore closeWithError:nil];
}

- (void)testHasUnsavedChangesDiscardChanges
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore setSaveInterval:100];
    
    // Add some data to the document store
    NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:object error:nil];
    
    [nanoStore discardUnsavedChanges];
    STAssertTrue (NO == [nanoStore hasUnsavedChanges], @"Did not expect unsaved changes.");
    
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
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search1 = [NSFNanoSearch searchWithStore:nanoStore];
    [search1 setKey:obj1.key];
    NSArray *keys1 = [search1 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    NSFNanoSearch *search2 = [NSFNanoSearch searchWithStore:nanoStore];
    [search2 setKey:obj2.key];
    NSArray *keys2 = [search2 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([keys1 count] + [keys2 count] == 2), @"Expected to find two stored objects.");
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
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, obj4, obj5, nil] error:nil];

    NSFNanoSearch *search1 = [NSFNanoSearch searchWithStore:nanoStore];
    [search1 setKey:obj1.key];
    NSArray *keys1 = [search1 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    NSFNanoSearch *search2 = [NSFNanoSearch searchWithStore:nanoStore];
    [search2 setKey:obj2.key];
    NSArray *keys2 = [search2 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    NSFNanoSearch *search3 = [NSFNanoSearch searchWithStore:nanoStore];
    [search3 setKey:obj3.key];
    NSArray *keys3 = [search3 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([keys1 count] + [keys2 count] + [keys3 count]== 3), @"Expected to find three stored objects.");
}

- (void)testStoreObjectWithPeriodInDictionaryKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    @try {
        [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testStoreObjectsWithNilKeyAttributeAndValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyBadAttributeAndValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:obj1.key];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyGoodAttributeAndBadValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:obj1.key];
    [search setAttribute:@"Countries.France.Nice"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyAttributeAndValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:obj1.key];
    [search setAttribute:@"Countries.France.Nice"];
    [search setValue:@"Cassoulet"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyBadAttributeAndGoodValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:obj1.key];
    [search setValue:@"Cassoulet"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyGoodAttributeAndBadValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setAttribute:@"Countries.France.Nice"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyGoodAttributeAndGoodValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setAttribute:@"Countries.France.Nice"];
    [search setValue:@"Cassoulet"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyBadAttributeAndGoodValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setValue:@"Cassoulet"];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
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
    STAssertTrue (([searchResults count] == 1), @"Expected to find one object.");

    // Remove the object from the store
    [nanoStore removeObject:obj1 error:nil];

    // Verify that the object was removed properly
    searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 0), @"Expected to find zero objects.");
}

- (void)testUpdateObject
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSString *obj1Key = [obj1 nanoObjectKey];
    [nanoStore addObject:obj1 error:nil];
    
    // Update the object and save it
    [obj1 setObject:@"foo" forKey:@"SomeKey"];
    [nanoStore addObject:obj1 error:nil];
     
    // Verify that the object was updated properly
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1Key;
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    STAssertTrue (([searchResults count] == 1), @"Expected to find one object.");

    NSFNanoObject *returnedObject = [searchResults objectForKey:[[searchResults allKeys]lastObject]];
    
    [nanoStore closeWithError:nil];

    STAssertTrue ([[[returnedObject info]objectForKey:@"SomeKey"]isEqualToString:@"foo"], @"Expected to find the updated information.");
}

- (void)testRemoveObjectForKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    [nanoStore removeObjectsWithKeysInArray:[NSArray arrayWithObjects:obj1.key, obj2.key, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 0), @"Expected to find zero objects.");
}

- (void)testObjectsWithKeysInArray
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoBag *bag = [NSFNanoBag bag];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];

    NSArray *objects = [nanoStore objectsWithKeysInArray:[NSArray arrayWithObjects:bag.key, obj3.key, nil]];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([objects count] == 2), @"Expected to find two objects.");
}

#pragma mark -

- (void)testStoreObjectsWithBadKeyBadAttributeBadValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attributesToBeReturned = [NSArray arrayWithObjects:@"FirstName", @"LastName", nil];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    NSUInteger objectCount = [searchResults count];
    NSUInteger attributesCount = [[search attributesToBeReturned]count] + 1;
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ((objectCount == 1) && (attributesCount == 3), @"Expected to find one object with three attributes.");
}

- (void)testStoreObjectsWithGoodKeyBadAttributeAndValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:obj1.key];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyGoodAttributeAndBadValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:obj1.key];
    [search setAttribute:@"Countries.France.Nice"];
    search.attributesToBeReturned = [NSArray arrayWithObjects:@"FirstName", @"LastName", nil];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyAttributeAndValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:obj1.key];
    [search setAttribute:@"Countries.France.Nice"];
    [search setValue:@"Cassoulet"];
    search.attributesToBeReturned = [NSArray arrayWithObjects:@"FirstName", @"LastName", nil];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithGoodKeyBadAttributeAndGoodValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:obj1.key];
    [search setValue:@"Cassoulet"];
    search.attributesToBeReturned = [NSArray arrayWithObjects:@"FirstName", @"LastName", nil];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyGoodAttributeAndBadValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setAttribute:@"Countries.France.Nice"];
    search.attributesToBeReturned = [NSArray arrayWithObjects:@"FirstName", @"LastName", nil];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyGoodAttributeAndGoodValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setAttribute:@"Countries.France.Nice"];
    [search setValue:@"Cassoulet"];
    search.attributesToBeReturned = [NSArray arrayWithObjects:@"FirstName", @"LastName", nil];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testStoreObjectsWithBadKeyBadAttributeAndGoodValueAndReturnObjectsWithSomeAttributes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setValue:@"Cassoulet"];
    search.attributesToBeReturned = [NSArray arrayWithObjects:@"FirstName", @"LastName", nil];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
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
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSArray *classNames = [nanoStore allObjectClasses];
    
    STAssertTrue ([classNames count] == 2, @"Expected to find two class names.");
}

- (void)testObjectsOfClassNamed
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSArray *classNames = [nanoStore objectsOfClassNamed:@"NSFNanoBag"];
    
    STAssertTrue ([classNames count] == 1, @"Expected to find one object of class NSFNanoBag.");
}

- (void)testRemoveAllObjectsStore
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSString  *theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@;", NSFKeys];
    NSFNanoResult *result = [nanoStore executeSQL:theSQLStatement];
    [theSQLStatement release];
    long long numObjects = [[result firstValue]longLongValue];
    
    theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@;", NSFValues];
    result = [nanoStore executeSQL:theSQLStatement];
    [theSQLStatement release];
    long long numValues = [[result firstValue]longLongValue];
    
    STAssertTrue (numObjects + numValues > 0, @"Expected to find objects.");

    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@;", NSFKeys];
    result = [nanoStore executeSQL:theSQLStatement];
    [theSQLStatement release];
    numObjects = [[result firstValue]longLongValue];
    
    theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@;", NSFValues];
    result = [nanoStore executeSQL:theSQLStatement];
    [theSQLStatement release];
    numValues = [[result firstValue]longLongValue];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (numObjects + numValues == 0, @"Expected to find zero objects.");
}

- (void)testClearIndexes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    [nanoStore clearIndexesAndReturnError:nil];

    NSFNanoEngine *nsfdb = [nanoStore nanoStoreEngine];
    NSArray *indexes = [nsfdb indexes];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([indexes count] == 0, @"Expected all indexes to be cleared.");
}

- (void)testRebuildIndexes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];    
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    [nanoStore clearIndexesAndReturnError:nil];
    [nanoStore rebuildIndexesAndReturnError:nil];
    
    NSFNanoEngine *nsfdb = [nanoStore nanoStoreEngine];
    NSArray *indexes = [nsfdb indexes];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([indexes count] > 0, @"Expected the indexes to be rebuilt.");
}

#pragma mark -

- (void)testNanoStoreEngineDatabase
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    BOOL test1 = ([nanoStore nanoStoreEngine] != nil);
    [nanoStore openWithError:nil];
    BOOL test2 = ([nanoStore nanoStoreEngine] != nil);
    
    [nanoStore closeWithError:nil];
    BOOL test3 = (nil == [nanoStore nanoStoreEngine]);
    
    STAssertTrue ((test1 && test2 && (NO == test3)) == YES, @"Expected all tests against NSFNanoEngine to succeed.");
}

@end
