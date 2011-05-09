//
//  NanoStoreExpressionTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 3/30/08.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

#import "NanoStore.h"
#import "NanoStoreExpressionTests.h"
#import "NSFNanoStore_Private.h"

@implementation NanoStoreExpressionTests

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

- (void)testPredicateWithNilValue
{
    NSFNanoPredicate *predicate = nil;
    @try {
        predicate = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testExpressionWithNilPredicate
{
    NSFNanoExpression *expression = nil;
    @try {
        expression = [NSFNanoExpression expressionWithPredicate:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testOnePredicateOneExpressionEqualTo
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoPredicate *predicateFirstName = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"FirstName"];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicateFirstName];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testOnePredicateOneExpressionBeginsWith
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    BOOL success = [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    STAssertTrue (YES == success, @"Expected to store the object.");

    NSFNanoPredicate *predicateFirstName = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFBeginsWith value:@"First"];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicateFirstName];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testOnePredicateOneExpressionContains
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoPredicate *predicateFirstName = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFContains value:@"irs"];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicateFirstName];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 1), @"Expected to find one object.");
}

- (void)testOnePredicateOneExpressionEndsWith
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoPredicate *predicateFirstName = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEndsWith value:@"Name"];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicateFirstName];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 1), @"Expected to find one object.");
}

- (void)testOnePredicateOneExpressionInsensitiveEqualTo
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoPredicate *predicateFirstName = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFInsensitiveEqualTo value:@"LASTNamE"];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicateFirstName];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testOnePredicateOneExpressionInsensitiveBeginsWith
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoPredicate *predicateFirstName = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFInsensitiveBeginsWith value:@"FIrsT"];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicateFirstName];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testOnePredicateOneExpressionInsensitiveContains
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoPredicate *predicateFirstName = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFInsensitiveContains value:@"IrsT"];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicateFirstName];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testOnePredicateOneExpressionInsensitiveEndsWith
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoPredicate *predicateFirstName = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFInsensitiveEndsWith value:@"NaMe"];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicateFirstName];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testTwoPredicatesOneExpression
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoPredicate *predicateAttribute = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"FirstName"];
    NSFNanoPredicate *predicateValue = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:@"Tito"];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicateAttribute];
    [expression addPredicate:predicateValue withOperator:NSFAnd];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

#pragma mark -

- (NSDictionary *)defaultTestData
{
    NSArray *dishesInfo = [NSArray arrayWithObject:@"Cassoulet"];
    NSDictionary *citiesInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Bouillabaisse", @"Marseille",
                                dishesInfo, @"Nice",
                                nil, nil];
    NSDictionary *countriesInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"Barcelona", @"Spain",
                                   @"San Francisco", @"USA",
                                   citiesInfo, @"France",
                                   nil, nil];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"Tito", @"FirstName",
                          @"Ciuro", @"LastName",
                          countriesInfo, @"Countries",
                          nil, nil];
    
    return info;
}

@end
