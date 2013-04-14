//
//  NanoStoreBagTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 10/15/10.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

#import "NanoStore.h"
#import "NanoStoreBagTests.h"
#import "NSFNanoBag.h"
#import "NSFNanoGlobals_Private.h"
#import "NSFNanoStore_Private.h"
#import "NanoCarTestClass.h"

@implementation NanoStoreBagTests

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

- (void)testBagClassMethod
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;
    NSString *key = bag.key;
    NSArray *returnedKeys = [[bag dictionaryRepresentation]objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue (hasUnsavedChanges && (nil != key) && ([key length] > 0) && (nil != returnedKeys) && ([returnedKeys count] == 0), @"Expected the bag to be properly initialized.");
}

- (void)testBagDescription
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSString *description = [bag description];
    STAssertTrue ((description.length > 0), @"Expected to obtain the bag description.");
}

- (void)testBagEqualToSelf
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    STAssertTrue (([bag isEqualToNanoBag:bag] == YES), @"Expected to test to be true.");
}

- (void)testBagForUUID
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSString *objectKey = [bag nanoObjectKey];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the bag to return a valid UUID.");
    
    bag = [[NSFNanoBag alloc]init];
    objectKey = [bag nanoObjectKey];
    STAssertTrue ((nil != objectKey) && ([objectKey length] > 0), @"Expected the bag to return a valid UUID.");
}

- (void)testBagInitNilObjects
{
    NSFNanoBag *bag = nil;
    
    @try {
        bag = [NSFNanoBag bagWithObjects:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testBagSettingNameManually
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    STAssertTrue (nil == [bag name], @"Expected the name of the bag to be nil.");
    bag.name = @"FooBar";
    STAssertTrue ([bag hasUnsavedChanges], @"Expected the bag to have unsaved changes.");
    STAssertTrue (nil != [bag name], @"Expected the name of the bag to be hold a value.");
    bag.name = nil;
    STAssertTrue (nil == [bag name], @"Expected the name of the bag to be nil.");
}

- (void)testBagWithNameEmptyBag
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bagWithName:@"FooBar"];
    STAssertTrue (nil != [bag name], @"Expected the name of the bag to not be nil.");
    
    NSError *error = nil;
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:&error];
    STAssertTrue (nil == error, @"Saving bag A should have succeded.");
    
    NSFNanoBag *retrievedBag = [nanoStore bagWithName:bag.name];
    STAssertTrue ([[retrievedBag name]isEqualToString:bag.name] == YES, @"We should have found the bag by name.");
    
    [nanoStore closeWithError:nil];
}

- (void)testBagWithNameBagNotEmpty
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSArray *objects = [NSArray arrayWithObjects:
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        nil];
    NSFNanoBag *bag = [NSFNanoBag bagWithName:@"FooBar" andObjects:objects];
    STAssertTrue (nil != [bag name], @"Expected the name of the bag to be nil.");
    
    NSError *error = nil;
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:&error];
    STAssertTrue (nil == error, @"Saving bag A should have succeded.");
    
    NSFNanoBag *retrievedBag = [nanoStore bagWithName:bag.name];
    STAssertTrue ([[retrievedBag name]isEqualToString:bag.name] == YES, @"We should have found the bag by name.");
    
    [nanoStore closeWithError:nil];
}

- (void)testBagSearchByName
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    bag.name = @"FooBar";
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];

    NSFNanoBag *retrievedBag = [nanoStore bagWithName:bag.name];
    STAssertTrue ([[retrievedBag name]isEqualToString:bag.name] == YES, @"We should have found the bag by name.");

    [nanoStore closeWithError:nil];
}

- (void)testBagInitEmptyListOfObjects
{
    NSFNanoBag *bag = [NSFNanoBag bagWithObjects:[NSArray array]];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;
    NSString *key = bag.key;
    NSArray *returnedKeys = [[bag dictionaryRepresentation]objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue (hasUnsavedChanges && (nil != key) && ([key length] > 0) && (nil != returnedKeys) && ([returnedKeys count] == 0), @"Expected the bag to be properly initialized.");
}

- (void)testBagInitTwoConformingObjects
{
    NSArray *objects = [NSArray arrayWithObjects:
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        nil];
    
    NSFNanoBag *bag = [NSFNanoBag bagWithObjects:objects];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;
    NSString *key = bag.key;
    NSArray *returnedKeys = [[bag dictionaryRepresentation]objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue (hasUnsavedChanges && (nil != key) && ([key length] > 0) && (nil != returnedKeys) && ([returnedKeys count] == 2), @"Expected the bag to contain two returnedKeys.");
}

- (void)testBagInitPartiallyConformingObjects
{
    NSArray *objects = [NSArray arrayWithObjects:
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        @"foo",
                        nil];
    
    @try {
        [NSFNanoBag bagWithObjects:objects];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testBagEmptyDictionaryRepresentation
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSDictionary *info = [bag dictionaryRepresentation];
    NSString *key = [info objectForKey:NSF_Private_NSFNanoBag_NSFKey];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue ((nil != key) && ([key length] > 0) && (nil != returnedKeys) && ([returnedKeys count] == 0) && (nil != info) && ([info count] == 2), @"Expected the bag to provide a properly formatted dictionary.");
}

- (void)testBagWithTwoConformingObjectsDictionaryRepresentation
{
    NSArray *objects = [NSArray arrayWithObjects:
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        nil];
    
    NSFNanoBag *bag = [NSFNanoBag bagWithObjects:objects];
    NSDictionary *info = [bag dictionaryRepresentation];
    NSString *key = [info objectForKey:NSF_Private_NSFNanoBag_NSFKey];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue ((nil != key) && ([key length] > 0) && (nil != returnedKeys) && ([returnedKeys count] == 2) && (nil != info) && ([info count] == 2), @"Expected the bag to provide a properly formatted dictionary.");
}

- (void)testBagEmptyCount
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    STAssertTrue (0 == bag.count, @"Expected the bag to have zero elements.");
}

- (void)testBagCountTwo
{
    NSArray *objects = [NSArray arrayWithObjects:
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        nil];
    
    NSFNanoBag *bag = [NSFNanoBag bagWithObjects:objects];
    STAssertTrue (2 == bag.count, @"Expected the bag to have two elements.");
}

- (void)testTwoBagsWithSameName
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoBag *bag1 = [NSFNanoBag bagWithName:@"foo" andObjects:@[[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]]];
    NSFNanoBag *bag2 = [NSFNanoBag bagWithName:@"foo" andObjects:@[[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]]];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:bag1, bag2, nil] error:nil];
    NSArray *bags = [nanoStore bagsWithName:@"foo"];
    STAssertTrue (2 == bags.count, @"Expected to find two bags.");
    
    [nanoStore closeWithError:nil];
}

- (void)testBagCountTwoDeleteOne
{
    NSFNanoObject *objectOne = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSArray *objects = [NSArray arrayWithObjects:
                        objectOne,
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        nil];
    
    NSFNanoBag *bag = [NSFNanoBag bagWithObjects:objects];
    STAssertTrue (2 == bag.count, @"Expected the bag to have two elements.");
    [bag removeObject:objectOne];
    STAssertTrue (1 == bag.count, @"Expected the bag to have one element.");
}

- (void)testBagCountAfterSaveEmpty
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bagWithName:@"CountTest"];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    NSFNanoBag *receivedBag = [nanoStore bagWithName:@"CountTest"];
    STAssertTrue (0 == receivedBag.count, @"Expected the bag to have zero elements.");

    [nanoStore closeWithError:nil];
}

- (void)testBagCountAfterSaveTwoObjectsDeleteOne
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *objectOne = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSArray *objects = [NSArray arrayWithObjects:
                        objectOne,
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        nil];
    
    NSFNanoBag *bag = [NSFNanoBag bagWithName:@"CountTest" andObjects:objects];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    NSFNanoBag *receivedBag = [nanoStore bagWithName:@"CountTest"];
    STAssertTrue (2 == receivedBag.count, @"Expected the bag to have two elements.");
    [receivedBag removeObject:objectOne];
    STAssertTrue (1 == receivedBag.count, @"Expected the bag to have one element.");
    
    [nanoStore closeWithError:nil];
}

- (void)testBagCountRemoveAll
{
    NSArray *objects = [NSArray arrayWithObjects:
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        nil];
    
    NSFNanoBag *bag = [NSFNanoBag bagWithObjects:objects];
    STAssertTrue (2 == bag.count, @"Expected the bag to have two elements.");
    [bag removeAllObjects];
    STAssertTrue (0 == bag.count, @"Expected the bag to have zero elements.");
}

#pragma mark -

- (void)testBagAddNilObject
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    
    @try {
        NSError *outError = nil;
        [bag addObject:nil error:&outError];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testBagAddNonConformingObject
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    
    @try {
        [bag addObject:(id)@"foo" error:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testBagAddConformingObject
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSError *outError = nil;
    BOOL success = [bag addObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo] error:&outError];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;

    NSDictionary *info = [bag dictionaryRepresentation];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue (hasUnsavedChanges && success && (nil == outError) && (nil != returnedKeys) && ([returnedKeys count] == 1), @"Adding a conforming object to a bag should have succeeded.");
}

- (void)testBagAddNilObjectList
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSError *outError = nil;
    BOOL success = [bag addObjectsFromArray:nil error:&outError];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;

    NSDictionary *info = [bag dictionaryRepresentation];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue (hasUnsavedChanges && (NO == success) && (nil != outError) && (nil != returnedKeys) && ([returnedKeys count] == 0), @"Adding a nil object list to a bag should have failed.");
}

- (void)testBagAddWithEmptyObjectList
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSError *outError = nil;
    BOOL success = [bag addObjectsFromArray:[NSArray array] error:&outError];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;

    NSDictionary *info = [bag dictionaryRepresentation];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue (hasUnsavedChanges && success && (nil == outError) && (nil != returnedKeys) && ([returnedKeys count] == 0), @"Adding an empty object list to a bag should have failed.");
}

- (void)testBagAddTwoConformingObjects
{
    NSArray *objects = [NSArray arrayWithObjects:
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSError *outError = nil;
    BOOL success = [bag addObjectsFromArray:objects error:&outError];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;

    NSDictionary *info = [bag dictionaryRepresentation];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue (hasUnsavedChanges && success && (nil == outError) && (nil != returnedKeys) && ([returnedKeys count] == 2), @"Adding a conforming object list to a bag should have succeded.");
}

- (void) testBagAddTwoNSObjectsConformingToProtocol
{
    id car1 = [[NanoCarTestClass alloc] initNanoObjectFromDictionaryRepresentation:@{@"kName" : @"XJ-7"} forKey:[NSFNanoEngine stringWithUUID] store:nil];
    id car2 = [[NanoCarTestClass alloc] initNanoObjectFromDictionaryRepresentation:@{@"kName" : @"Jupiter 8"} forKey:[NSFNanoEngine stringWithUUID] store:nil];
    
    NSArray *objects = @[car1, car2];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSError *outError = nil;
    BOOL success = [bag addObjectsFromArray:objects error:&outError];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;
    
    NSDictionary *info = [bag nanoObjectDictionaryRepresentation];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue (success, @"expected bag to have saved");
    STAssertTrue (hasUnsavedChanges, @"expected bag to have no unsaved changes");
    STAssertNil (outError, @"expect bag to return no error on save");
    STAssertEquals ([returnedKeys count], [objects count], @"expected saved bag to return %d object keys", [objects count]);
}


- (void)testBagAddPartiallyConformingObjects
{
    NSArray *objects = [NSArray arrayWithObjects:
                        [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        @"foo",
                        nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    
    @try {
        [bag addObjectsFromArray:objects error:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

#pragma mark -

- (void)testBagRemoveNilObject
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    
    [bag addObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo] error:nil];
    
    @try {
        [bag removeObject:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testBagRemoveNonConformingObject
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObject:obj1 error:nil];
    
    @try {
        [bag removeObject:(id)@"foo"];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testBagRemoveOneConformingObject
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    [bag removeObject:obj1];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;

    NSDictionary *info = [bag dictionaryRepresentation];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    NSString *returnedKey = [returnedKeys lastObject];
    
    STAssertTrue (hasUnsavedChanges && (nil != returnedKeys) && ([returnedKeys count] == 1) && ([returnedKey isEqualToString:obj2.key]), @"Removing a conforming object from a bag should have succeded.");
}

- (void)restBagRemoveWithEmptyListOfObjects
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    [bag removeObject:obj1];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;

    NSDictionary *info = [bag dictionaryRepresentation];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    NSString *returnedKey = [returnedKeys lastObject];
    
    STAssertTrue (hasUnsavedChanges && (nil != returnedKeys) && ([returnedKeys count] == 1) && ([returnedKey isEqualToString:obj2.key]), @"Removing a conforming object from a bag should have succeded.");
}

- (void)testBagRemoveTwoConformingObjects
{
    NSFNanoBag *bag = [NSFNanoBag bag];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSArray *objects = [NSArray arrayWithObjects:obj1, obj2, nil];
    [bag addObjectsFromArray:objects error:nil];
    [bag removeObjectsInArray:objects];
    BOOL hasUnsavedChanges = bag.hasUnsavedChanges;

    NSDictionary *info = [bag dictionaryRepresentation];
    NSArray *returnedKeys = [info objectForKey:NSF_Private_NSFNanoBag_NSFObjectKeys];
    
    STAssertTrue (hasUnsavedChanges && (nil != returnedKeys) && ([returnedKeys count] == 0), @"Removing conforming objects from a bag should have succeded.");
}

#pragma mark -

- (void)testBagSaveEmptyBag
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    NSArray *bags = [nanoStore bags];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([bags count] == 1, @"Saving an empty bag should have succeded.");
}

- (void)testBagSaveBagWithThreeObjectsAssociatedToStore
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSArray *bags = [nanoStore bags];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([[[bags lastObject]savedObjects]count] == 3, @"Saving a bag should have succeded.");
}

- (void)testBagSaveBagWithThreeObjectsNotAssociatedToStore
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSArray *bags = [nanoStore bags];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([[[bags lastObject]savedObjects]count] == 3, @"Saving a bag should have succeded.");
}

- (void)testBagSaveBagRemovingObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSArray *bags = [nanoStore bags];
    NSFNanoBag *savedBag = [bags lastObject];
    [savedBag removeObjectsWithKeysInArray:[NSArray arrayWithObjects:obj1.key, obj2.key, nil]];
    
    STAssertTrue (([bags count] == 1) && ([[savedBag savedObjects]count] == 1) && ([[savedBag unsavedObjects]count] == 0) && ([[savedBag removedObjects]count] == 2), @"Removing objects from a bag should have succeded.");

    NSError *outError = nil;
    [savedBag saveAndReturnError:&outError];
    STAssertTrue (nil == outError, @"Saving the bag failed. Reason: %@.", [outError localizedDescription]);

    savedBag = [[nanoStore bags]lastObject];

    [nanoStore closeWithError:nil];
    
    STAssertTrue (([[savedBag savedObjects]count] == 1) && ([[savedBag unsavedObjects]count] == 0) && ([[savedBag removedObjects]count] == 0), @"Removing objects from a bag should have succeded.");
}

- (void)testBagSaveBagEditingObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObject:bag error:nil];
    
    NSArray *bags = [nanoStore bags];
    NSFNanoBag *savedBag = [bags lastObject];
    
    NSError *outError = nil;
    NSFNanoObject *editedObject = [[[savedBag savedObjects]allValues]lastObject];
    NSString *editedKey = editedObject.key;
    NSUInteger originalCount = editedObject.info.count;
    [editedObject setObject:@"fooValue" forKey:@"fooKey"];
    [savedBag addObject:editedObject error:&outError];
    STAssertTrue (([[savedBag savedObjects]count] == 2) && ([[savedBag unsavedObjects]count] == 1) && ([[savedBag removedObjects]count] == 0), @"Editing objects from a bag should have succeded.");
    
    [savedBag saveAndReturnError:&outError];
    STAssertTrue (nil == outError, @"Saving the bag failed. Reason: %@.", [outError localizedDescription]);
    
    savedBag = [[nanoStore bags]lastObject];
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([[savedBag savedObjects]count] == 3), @"Expected savedObjects to have 3 elements.");
    STAssertTrue (([[savedBag unsavedObjects]count] == 0), @"Expected unsavedObjects to have 0 elements.");
    STAssertTrue (([[savedBag removedObjects]count] == 0), @"Expected removedObjects to have 0 elements.");
    STAssertTrue (([[[[savedBag savedObjects]objectForKey:editedKey]info]count] == originalCount + 1), @"Editing objects from a bag should have succeded.");
}

- (void)testBagDeleteBag
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    NSError *outError = nil;
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:&outError];
    STAssertTrue (nil == outError, @"Could not save the bag. Reason: %@", [outError localizedDescription]);

    NSArray *savedBags = [nanoStore bags];
    NSString *keyToBeRemoved = [[savedBags lastObject]key];
    STAssertTrue (nil != keyToBeRemoved, @"The key of the bag to be removed cannot be nil.");

    [nanoStore removeObjectsWithKeysInArray:[NSArray arrayWithObject:keyToBeRemoved] error:nil];
    
    NSArray *removedBags = [nanoStore bags];

    [nanoStore closeWithError:nil];
    
    STAssertTrue (([savedBags count] == 1) && [removedBags count] == 0, @"Removing a bag should have succeded.");
}

- (void)testBagReloadBag
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSArray *bags = [nanoStore bags];
    NSFNanoBag *savedBagA = [bags lastObject];

    // Edit an object, replace it in savedBagA
    NSError *outError = nil;
    NSFNanoObject *editedObject = [[[savedBagA savedObjects]allValues]lastObject];
    [editedObject setObject:@"fooValue" forKey:@"fooKey"];
    [savedBagA addObject:editedObject error:&outError];
    STAssertTrue (([[savedBagA savedObjects]count] == 2) && ([[savedBagA unsavedObjects]count] == 1) && ([[savedBagA removedObjects]count] == 0), @"Editing objects from a bag should have succeded.");
    
    // Remove an object from savedBagA and save it
    [savedBagA removeObjectWithKey:obj1.key];
    BOOL success = [savedBagA saveAndReturnError:&outError];
    STAssertTrue (success && (nil == outError), @"Saving the bag should have succeded.");
    STAssertTrue (([[savedBagA savedObjects]count] == 2) && ([[savedBagA unsavedObjects]count] == 0) && ([[savedBagA removedObjects]count] == 0), @"Removing an object from a bag should have succeded.");

    bags = [nanoStore bags];
    NSFNanoBag *savedBagB = [bags lastObject];

    editedObject = [[[savedBagB savedObjects]allValues]lastObject];
    [editedObject setObject:@"fooValue" forKey:@"fooKey"];
    [savedBagB addObject:editedObject error:&outError];
    success = [savedBagB reloadBagWithError:&outError];
    STAssertTrue (success, @"The bad reload should have succeeded.");

    success = YES;
    NSArray *sortedArrayA = [[[savedBagA savedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSArray *sortedArrayB = [[[savedBagB savedObjects]allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    if (NO == [sortedArrayA isEqualToArray:sortedArrayB]) {
        success = NO;
    }
    
    STAssertTrue ((NO == success), @"The bag comparison should have failed.");
    STAssertTrue (([[savedBagB savedObjects]count] == 1) && ([[savedBagB unsavedObjects]count] == 1) && ([[savedBagB removedObjects]count] == 0), @"Reloading the bag should have preserved the change.");

    [nanoStore closeWithError:nil];
}

- (void)testBagUndoUnsavedBag
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    NSError *outError = nil;
    [bag undoChangesWithError:&outError];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([[bag savedObjects]count] == 0) && ([[bag unsavedObjects]count] == 0) && ([[bag removedObjects]count] == 0), @"Undoing the changes of an unsaved bag should have succeded.");
}

- (void)testBagUndoSavedBag
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSArray *bags = [nanoStore bags];
    NSFNanoBag *savedBag = [bags lastObject];

    NSError *outError = nil;
    NSFNanoObject *editedObject = [[[savedBag savedObjects]allValues]lastObject];
    [editedObject setObject:@"fooValue" forKey:@"fooKey"];
    [savedBag addObject:editedObject error:&outError];
    STAssertTrue (([[savedBag savedObjects]count] == 2) && ([[savedBag unsavedObjects]count] == 1) && ([[savedBag removedObjects]count] == 0), @"Editing objects from a bag should have succeded.");
    
    [savedBag undoChangesWithError:&outError];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([[savedBag savedObjects]count] == 3) && ([[savedBag unsavedObjects]count] == 0) && ([[savedBag removedObjects]count] == 0), @"Undoing the changes of a saved bag should have succeded.");
}

- (void)testBagSearchBagsWithKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    NSError *outError = nil;
    [nanoStore removeAllObjectsFromStoreAndReturnError:&outError];
    
    NSFNanoBag *bag1 = [NSFNanoBag bag];
    NSArray *objects = [NSArray arrayWithObjects:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo],
                        nil];
    [bag1 addObjectsFromArray:objects error:nil];
    
    NSFNanoBag *bag2 = [NSFNanoBag bag];
    [bag2 addObjectsFromArray:objects error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:bag1, bag2, nil] error:nil];
    
    NSArray *savedBags = [nanoStore bags];
    STAssertTrue ([savedBags count] == 2, @"Expected to find two bags.");

    savedBags = [nanoStore bagsWithKeysInArray:[NSArray arrayWithObjects:bag1.key, bag2.key, nil]];

    [nanoStore closeWithError:nil];
    
    STAssertTrue ([savedBags count] == 2, @"Expected to find bags by their key.");
}

- (void)testBagSearchBagsContainingObjectsWithKey
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    NSError *outError = nil;
    [nanoStore removeAllObjectsFromStoreAndReturnError:&outError];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSArray *bags = [nanoStore bagsContainingObjectWithKey:obj3.key];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([bags count] == 1) && ([[[bags lastObject]key]isEqualToString:[bag key]]), @"Searching a bag containing a specific key should have succeded.");
}

- (void)testBagCopyBag
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    [nanoStore addObject:bag error:nil];
    
    NSFNanoBag *copiedBag = [bag copy];
    
    STAssertTrue (([bag isEqualToNanoBag:copiedBag]), @"Equality test should have succeeded.");
}

- (void)testBagIsEqualToNanoBag
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObject:bag error:nil];
    
    NSArray *bags = [nanoStore bags];
    NSFNanoBag *savedBagA = [bags lastObject];
    bags = [nanoStore bags];
    NSFNanoBag *savedBagB = [bags lastObject];
    
    STAssertTrue (([savedBagA isEqualToNanoBag:savedBagB]), @"Equality test should have succeeded.");
    
    NSError *outError = nil;
    NSFNanoObject *editedObject = [NSFNanoObject nanoObjectWithDictionary:[NSDictionary dictionaryWithObject:@"fooObject" forKey:@"fooKey"]];
    [savedBagB addObject:editedObject error:&outError];
    
    STAssertTrue ((NO == [savedBagA isEqualToNanoBag:savedBagB]), @"Equality test should have failed.");
    
    [nanoStore closeWithError:nil];
}

#pragma mark -

- (void)testBagDeflate
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSFNanoBag *resultBag = [[nanoStore bags]lastObject];
    
    [resultBag deflateBag];
    
    NSDictionary *savedObjects = resultBag.savedObjects;
    BOOL deflated = YES;
    for (NSString *objectKey in savedObjects) {
        if ([NSNull null] != [savedObjects objectForKey:objectKey]) {
            deflated = NO;
            break;
        }
    }
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (deflated, @"Expected the bag to be deflated.");
}

- (void)testBagInflate
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSFNanoBag *resultBag = [[nanoStore bags]lastObject];
    
    [resultBag deflateBag];
    [resultBag inflateBag];

    NSDictionary *savedObjects = resultBag.savedObjects;
    BOOL inflated = YES;
    for (NSString *objectKey in savedObjects) {
        if ([NSNull null] == [savedObjects objectForKey:objectKey]) {
            inflated = NO;
            break;
        }
    }
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (inflated, @"Expected the bag to be inflated.");
}

@end