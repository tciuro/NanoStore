//
//  NanoStoreSortTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 5/26/11.
//  Copyright (c) 2013 Webbo, Inc. All rights reserved.
//

#import "NanoStore.h"
#import "NanoStoreSortTests.h"

@implementation NanoStoreSortTests

- (void)setUp
{
    [super setUp];
    
    NSFSetIsDebugOn (NO);
}

- (void)tearDown
{
    NSFSetIsDebugOn (NO);
    
    [super tearDown];
}

#pragma mark -

- (void)testSortWithNilAttributes
{
    NSFNanoSortDescriptor *sort = nil;
    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        sort = [NSFNanoSortDescriptor sortDescriptorWithAttribute:nil ascending:YES];
#pragma clang diagnostic pop
    } @catch (NSException *e) {
        XCTAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testSortParametersAscending
{
    NSFNanoSortDescriptor *sort = [NSFNanoSortDescriptor sortDescriptorWithAttribute:@"Foo" ascending:YES];
    XCTAssertTrue ([[sort attribute]isEqualToString:@"Foo"], @"Expected the key to be the same.");
    XCTAssertTrue (sort.isAscending, @"Expected the sort order to be the same.");
}

- (void)testSortParametersDescending
{
    NSFNanoSortDescriptor *sort = [NSFNanoSortDescriptor sortDescriptorWithAttribute:@"Bar" ascending:NO];
    XCTAssertTrue ([[sort attribute]isEqualToString:@"Bar"], @"Expected the key to be the same.");
    XCTAssertTrue (NO == sort.isAscending, @"Expected the sort order to be the same.");
}

- (void)testSortObjectsAscending
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:@{@"City": @"Madrid"}];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:@{@"City": @"Barcelona"}];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:@{@"City": @"San Sebastian"}];
    NSFNanoObject *obj4 = [NSFNanoObject nanoObjectWithDictionary:@{@"City": @"Zaragoza"}];
    NSFNanoObject *obj5 = [NSFNanoObject nanoObjectWithDictionary:@{@"City": @"Tarragona"}];

    [nanoStore addObjectsFromArray:@[obj1, obj2, obj3, obj4, obj5] error:nil];
    
    // Prepare the sort
    NSFNanoSortDescriptor *sortCities = [[NSFNanoSortDescriptor alloc]initWithAttribute:@"City" ascending: YES];
    
    // Prepare the search
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.sort = @[sortCities];
    
    // Perform the search
    NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    XCTAssertTrue ([searchResults count] == 5, @"Expected to find five objects.");
    
    XCTAssertTrue ([[[[searchResults objectAtIndex:0]info]objectForKey:@"City"]isEqualToString:@"Barcelona"], @"Expected to find Barcelona.");
    
    XCTAssertTrue ([[searchResults[0] info][@"City"]isEqualToString:@"Barcelona"], @"Expected to find Barcelona.");
    
    // Cleanup
    
    // Close the document store
    [nanoStore closeWithError:nil];
}

- (void)testSortBagsAscending
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoBag *bagOne = [NSFNanoBag bagWithName:@"San Sebastian"];
    NSFNanoBag *bagTwo = [NSFNanoBag bagWithName:@"Barcelona"];
    NSFNanoBag *bagThree = [NSFNanoBag bagWithName:@"Madrid"];
    NSFNanoBag *bagFour = [NSFNanoBag bagWithName:@"Zaragoza"];
    
    [nanoStore addObjectsFromArray:@[bagOne, bagTwo, bagThree, bagFour] error:nil];
    
    // Prepare the sort
    NSFNanoSortDescriptor *sortBagNameDescriptor = [[NSFNanoSortDescriptor alloc]initWithAttribute:@"name" ascending: YES];
    
    // Prepare the search
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.sort = @[sortBagNameDescriptor];
    
    NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    XCTAssertTrue ([searchResults count] == 4, @"Expected to find four objects.");
    XCTAssertTrue ([[searchResults[0]name]isEqualToString:@"Barcelona"], @"Expected to find Barcelona.");
    
    // Cleanup
    
    // Close the document store
    [nanoStore closeWithError:nil];
}

@end
