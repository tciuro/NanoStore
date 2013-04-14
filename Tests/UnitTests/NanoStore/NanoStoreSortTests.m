//
//  NanoStoreSortTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 5/26/11.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
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
        sort = [NSFNanoSortDescriptor sortDescriptorWithAttribute:nil ascending:YES];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testSortParametersAscending
{
    NSFNanoSortDescriptor *sort = [NSFNanoSortDescriptor sortDescriptorWithAttribute:@"Foo" ascending:YES];
    STAssertTrue ([[sort attribute]isEqualToString:@"Foo"], @"Expected the key to be the same.");
    STAssertTrue (sort.isAscending, @"Expected the sort order to be the same.");
}

- (void)testSortParametersDescending
{
    NSFNanoSortDescriptor *sort = [NSFNanoSortDescriptor sortDescriptorWithAttribute:@"Bar" ascending:NO];
    STAssertTrue ([[sort attribute]isEqualToString:@"Bar"], @"Expected the key to be the same.");
    STAssertTrue (NO == sort.isAscending, @"Expected the sort order to be the same.");
}

- (void)testSortObjectsAscending
{
    // Instantiate a NanoStore and open it
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:[NSDictionary dictionaryWithObject:@"Madrid" forKey:@"City"]];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:[NSDictionary dictionaryWithObject:@"Barcelona" forKey:@"City"]];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:[NSDictionary dictionaryWithObject:@"San Sebastian" forKey:@"City"]];
    NSFNanoObject *obj4 = [NSFNanoObject nanoObjectWithDictionary:[NSDictionary dictionaryWithObject:@"Zaragoza" forKey:@"City"]];
    NSFNanoObject *obj5 = [NSFNanoObject nanoObjectWithDictionary:[NSDictionary dictionaryWithObject:@"Tarragona" forKey:@"City"]];

    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, obj4, obj5, nil] error:nil];
    
    // Prepare the sort
    NSFNanoSortDescriptor *sortCities = [[NSFNanoSortDescriptor alloc]initWithAttribute:@"City" ascending: YES];
    
    // Prepare the search
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.sort = [NSArray arrayWithObjects: sortCities, nil];
    
    // Perform the search
    NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    STAssertTrue ([searchResults count] == 5, @"Expected to find five objects.");
    STAssertTrue ([[[[searchResults objectAtIndex:0]info]objectForKey:@"City"]isEqualToString:@"Barcelona"], @"Expected to find Barcelona.");
    
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
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:bagOne, bagTwo, bagThree, bagFour, nil] error:nil];
    
    // Prepare the sort
    NSFNanoSortDescriptor *sortBagNameDescriptor = [[NSFNanoSortDescriptor alloc]initWithAttribute:@"name" ascending: YES];
    
    // Prepare the search
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.sort = [NSArray arrayWithObject: sortBagNameDescriptor];
    
    NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    STAssertTrue ([searchResults count] == 4, @"Expected to find four objects.");
    STAssertTrue ([[[searchResults objectAtIndex:0]name]isEqualToString:@"Barcelona"], @"Expected to find Barcelona.");
    
    // Cleanup
    
    // Close the document store
    [nanoStore closeWithError:nil];
}

@end
