//
//  NanoStoreSearchTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 10/4/08.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

#import "NanoStore.h"
#import "NSFNanoSearch_Private.h"
#import "NanoStoreSearchTests.h"
#import "NSFNanoStore_Private.h"
#import "NSFNanoObject_Private.h"
#import "NSFNanoSortDescriptor.h"
#import "NanoCarTestClass.h"
#import "NanoPersonTestClass.h"
#import "NSFNanoGlobals_Private.h"

@implementation NanoStoreSearchTests

- (void)setUp
{
    [super setUp];
    
    _defaultTestInfo = [NSFNanoStore _defaultTestData];
    
#ifdef __MAC_OS_X_VERSION_MAX_ALLOWED
    // code only compiled when targeting Mac OS X and not iOS
    // Obtain the system version
    SInt32 major, minor;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    _systemVersion = major + (minor/10.0);
#else
    // Round to the nearest since it's not always exact
    _systemVersion = floorf([[[UIDevice currentDevice]systemVersion]floatValue] * 10 + 0.5) / 10;
#endif
    
    NSFSetIsDebugOn (NO);
}

- (void)tearDown
{
    NSFSetIsDebugOn (NO);
    
    [super tearDown];
}

#pragma mark -

- (void)testSearchStoreNil
{
    NSFNanoSearch *search = nil;
    
    @try {
        search = [NSFNanoSearch searchWithStore:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testSearchStoreSet
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    STAssertTrue ([search nanoStore] != nil, @"Expected default Search object to have a NanoStore object assigned.");
}

- (void)testSearchDefaultValues
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];

    NSString *key = [search key];
    NSString *attribute = [search attribute];
    NSString *value = [search value];
    NSFMatchType match = [search match];
    NSArray *attributesReturned = [search attributesToBeReturned];
    
    BOOL success = (nil == key) && (nil == attribute) && (nil == value) && (match == NSFContains) && ([attributesReturned count] == 0);

    STAssertTrue (success == YES, @"Expected default Search object to be properly initialized.");
}

- (void)testSearchKeyAccessor
{
    NSString *value = @"ABC";
    
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:value];
    
    NSString *retrievedValue = [search key];
    
    STAssertTrue ([retrievedValue isEqualToString:value] == YES, @"Expected accessor to return the proper value.");
}

- (void)testSearchAttributeAccessor
{
    NSString *value = @"ABC";
    
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setAttribute:value];
    
    NSString *retrievedValue = [search attribute];
    
    STAssertTrue ([retrievedValue isEqualToString:value] == YES, @"Expected accessor to return the proper value.");
}

- (void)testSearchValueAccessor
{
    NSString *value = @"ABC";
    
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setValue:value];
    
    NSString *retrievedValue = [search value];
    
    STAssertTrue ([retrievedValue isEqualToString:value] == YES, @"Expected accessor to return the proper value.");
}

- (void)testSearchMatchAccessor
{
    NSFMatchType value = NSFContains;
    
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setMatch:value];
    
    NSFMatchType retrievedValue = [search match];
    
    STAssertTrue (retrievedValue == value == YES, @"Expected accessor to return the proper value.");
}

- (void)testSearchExpressionsAccessor
{
    NSFNanoPredicate *firstNamePred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"foo"];
    NSFNanoPredicate *valuePred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:@"bar"];
    NSFNanoExpression *expression1 = [NSFNanoExpression expressionWithPredicate:firstNamePred];
    [expression1 addPredicate:valuePred withOperator:NSFAnd];
    
    NSFNanoPredicate *countryPred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"another foo"];
    NSFNanoPredicate *cityPred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEndsWith value:@"another bar"];
    NSFNanoExpression *expression2 = [NSFNanoExpression expressionWithPredicate:countryPred];
    [expression2 addPredicate:cityPred withOperator:NSFAnd];
    
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObjects:expression1, expression2, nil]];
    
    NSArray *expressions = [search expressions];
    
    STAssertTrue ([expressions count] == 2, @"Expected accessor to return two expressions.");
}

- (void)testSearchAttributesAccessor
{
    NSArray *value = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
    
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attributesToBeReturned = value;
    
    NSArray *retrievedValue = search.attributesToBeReturned;
    
    STAssertTrue ([retrievedValue isEqualToArray:value] == YES, @"Expected accessor to return the proper value.");
}

- (void)testSearchUsingNanoObjectSubclass
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Mercedes";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:person, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = NanoPersonFirst;
    search.match = NSFEqualTo;
    search.value = @"Mercedes";
    search.filterClass = NSStringFromClass([person class]);
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    NanoPersonTestClass *retrievedPerson = [[searchResults allValues]lastObject];

    STAssertTrue (([searchResults count] == 1), @"Expected to find one person object.");
    STAssertTrue ([retrievedPerson isKindOfClass:[NanoPersonTestClass class]], @"Expected to find a NanoPersonTestClass object.");
    STAssertTrue (nil != [retrievedPerson key], @"Expected the object to contain a valid key.");
    STAssertTrue ([[retrievedPerson key]isEqualToString:[person key]], @"Expected to find the object that was saved originally.");
}

- (void)testSearchReset
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setKey:@"foo"];
    [search setValue:@"bar"];
     
    [search reset];
    
    NSString *key = [search key];
    NSString *attribute = [search attribute];
    NSString *value = [search value];
    NSFMatchType match = [search match];
    NSArray *attributesReturned = search.attributesToBeReturned;
    
    BOOL success = (nil == key) && (nil == attribute) && (nil == value) && (match == NSFContains) && ([attributesReturned count] == 0);
    
    STAssertTrue (success == YES, @"Expected default Search object to be properly reset.");
}

#pragma mark -

- (void)testSearchByAttributeExists
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"Rating";
    [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    search.match = NSFEqualTo;
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    
    search.match = NSFBeginsWith;
    search.value = @"good";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 0, @"Expected to find zero objects.");
    search.match = NSFContains;
    search.value = @"good";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 0, @"Expected to find zero objects.");
    search.match = NSFEndsWith;
    search.value = @"good";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 0, @"Expected to find zero objects.");
    
    search.match = NSFBeginsWith;
    search.value = @"Good";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    search.match = NSFContains;
    search.value = @"Good";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    search.match = NSFEndsWith;
    search.value = @"Good";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    
    search.match = NSFInsensitiveBeginsWith;
    search.value = @"good";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    search.match = NSFInsensitiveContains;
    search.value = @"good";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    search.match = NSFInsensitiveEndsWith;
    search.value = @"good";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    
    search.match = NSFGreaterThan;
    search.value = @"g";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 0, @"Expected to find zero objects.");
    search.match = NSFGreaterThan;
    search.value = @"G";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    
    search.match = NSFLessThan;
    search.value = @"vd";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    search.match = NSFLessThan;
    search.value = @"Very";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
    
    search.match = NSFGreaterThan;
    search.value = @"vd";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 0, @"Expected to find zero objects.");
    search.match = NSFGreaterThan;
    search.value = @"Very";
    STAssertTrue ([[search searchObjectsWithReturnType:NSFReturnObjects error:nil]count] == 3, @"Expected to find three objects.");
}

- (void)testSearchObjectsReturningKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults isKindOfClass:[NSArray class]], @"Incorrect class returned. Expected NSArray.");
    STAssertTrue ([searchResults count] == 2, @"Expected to find two objects.");
}

- (void)testSearchObjectsReturningObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults isKindOfClass:[NSDictionary class]], @"Incorrect class returned. Expected NSDictionary.");
    STAssertTrue ([searchResults count] == 2, @"Expected to find two objects.");
}

- (void)testSearchObjectsReturningObjectsWithGivenKey
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj1.key;
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testSearchObjectsReturningKeyWithGivenKey
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore openWithError:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.key = obj2.key;
    
    NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testSearchWithAttributeContainingPeriodAndValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSDictionary *countriesInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"Llavaneres", @"Spain",
                                   @"San Francisco", @"USA",
                                   @"Very Good", @"Rating",
                                   nil, nil];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"John", @"FirstName",
                          @"Doe", @"LastName",
                          countriesInfo, @"Countries",
                          [NSNumber numberWithUnsignedInt:(arc4random() % 32767) + 1], @"SomeNumber",
                          @"To be decided", @"Rating",
                          nil, nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:info];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"Countries.Spain";
    search.match = NSFEqualTo;
    search.value = @"Barcelona";
    
    NSError *searchError = nil;
    id searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:&searchError];

    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testSearchWithAttributeContainingPeriodNoValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"Countries.Spain";
    
    NSError *searchError = nil;
    id searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:&searchError];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 2, @"Expected to find two objects.");
}

- (void)testSearchObjectsWithOffsetAndLimit
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    for (int i = 0; i < 10; i++) {
        [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]]] error:nil];
    }
    
    NSFNanoSortDescriptor *sortByNumber = [[NSFNanoSortDescriptor alloc]initWithAttribute:@"SomeNumber" ascending:YES];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.value = @"Barcelona";
    search.match = NSFEqualTo;
    search.limit = 5;
    search.offset = 3;
    search.sort = [NSArray arrayWithObjects:sortByNumber, nil];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 5, @"Expected to find five objects.");
}

- (void)testSearchObjectsWithOffsetAndLimitWithExpressions
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    for (int i = 0; i < 10; i++) {
        [nanoStore addObjectsFromArray:[NSArray arrayWithObject:[NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo]] error:nil];
    }
    
    NSFNanoSortDescriptor *sortByValue = [[NSFNanoSortDescriptor alloc]initWithAttribute:NSFKey ascending:YES];
    NSFNanoSortDescriptor *sortByROWID = [[NSFNanoSortDescriptor alloc]initWithAttribute:NSFRowIDColumnName ascending:YES];
    
    NSFNanoPredicate *firstNamePred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"FirstName"];
    NSFNanoPredicate *valuePred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:@"Tito"];
    NSFNanoExpression *expression1 = [NSFNanoExpression expressionWithPredicate:firstNamePred];
    [expression1 addPredicate:valuePred withOperator:NSFAnd];
    
    NSFNanoPredicate *countryPred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"Countries.Spain"];
    NSFNanoPredicate *cityPred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEndsWith value:@"celona"];
    NSFNanoExpression *expression2 = [NSFNanoExpression expressionWithPredicate:countryPred];
    [expression2 addPredicate:cityPred withOperator:NSFAnd];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.expressions = [NSArray arrayWithObjects:expression1, expression2, nil];
    search.limit = 5;
    search.offset = 3;
    search.sort = [NSArray arrayWithObjects:sortByValue, sortByROWID, nil];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 5, @"Expected to find five objects.");
}

- (void)testSearchTwoExpressions
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoPredicate *firstNamePred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"FirstName"];
    NSFNanoPredicate *valuePred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:@"Tito"];
    NSFNanoExpression *expression1 = [NSFNanoExpression expressionWithPredicate:firstNamePred];
    [expression1 addPredicate:valuePred withOperator:NSFAnd];
    
    NSFNanoPredicate *countryPred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"Countries.Spain"];
    NSFNanoPredicate *cityPred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEndsWith value:@"celona"];
    NSFNanoExpression *expression2 = [NSFNanoExpression expressionWithPredicate:countryPred];
    [expression2 addPredicate:cityPred withOperator:NSFAnd];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObjects:expression1, expression2, nil]];

    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testSearchThreeExpressions
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoPredicate *firstNamePred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"FirstName"];
    NSFNanoPredicate *valuePred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:@"Tito"];
    NSFNanoExpression *expression1 = [NSFNanoExpression expressionWithPredicate:firstNamePred];
    [expression1 addPredicate:valuePred withOperator:NSFAnd];
    
    NSFNanoPredicate *countryPred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"Countries.Spain"];
    NSFNanoPredicate *cityPred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEndsWith value:@"celona"];
    NSFNanoExpression *expression2 = [NSFNanoExpression expressionWithPredicate:countryPred];
    [expression2 addPredicate:cityPred withOperator:NSFAnd];
    
    NSFNanoPredicate *countryPred2 = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"Countries.France.Nice"];
    NSFNanoPredicate *cityPred2 = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:@"Cassoulet"];
    NSFNanoExpression *expression3 = [NSFNanoExpression expressionWithPredicate:countryPred2];
    [expression3 addPredicate:cityPred2 withOperator:NSFAnd];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObjects:expression1, expression2, expression3, nil]];

    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

#pragma mark -

- (void)testSearchObjectsAddedBeforeCalendarDate
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:60 * 60];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];

    NSDictionary *searchResults = [search searchObjectsAdded:NSFBeforeDate date:date returnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 2), @"Expected to find two objects.");
}

- (void)testSearchObjectsAddedBeforeCalendarDateFilterByClass
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Mercedes";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:car, person, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"kName";
    search.match = NSFEqualTo;
    search.value = @"Mercedes";
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:60 * 60];
    
    NSDictionary *searchResults = [search searchObjectsAdded:NSFBeforeDate date:date returnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 1), @"Expected to find one car object.");
}

- (void)testSearchObjectsAddedAfterCalendarDate
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:-(60 * 60)];

    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsAdded:NSFAfterDate date:date returnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 2), @"Expected to find two objects.");
}

- (void)testSearchObjectsAddedAfterCalendarDateFilterByClass
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Mercedes";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:car, person, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"kName";
    search.match = NSFEqualTo;
    search.value = @"Mercedes";
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:-(60 * 60)];

    NSDictionary *searchResults = [search searchObjectsAdded:NSFAfterDate date:date returnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 1), @"Expected to find one car object.");
}

- (void)testSearchKeysAddedBeforeCalendarDate
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:60 * 60];

    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];

    NSArray *searchResults = [search searchObjectsAdded:NSFBeforeDate date:date returnType:NSFReturnKeys error:nil];
    
    STAssertTrue (([[searchResults lastObject]isKindOfClass:[NSString class]]), @"Expected the key to be a string.");

    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 2), @"Expected to find two objects.");
}

- (void)testSearchKeysAddedBeforeCalendarDateFilterByClass
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Mercedes";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:car, person, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"kName";
    search.match = NSFEqualTo;
    search.value = @"Mercedes";
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:60 * 60];
    
    NSArray *searchResults = [search searchObjectsAdded:NSFBeforeDate date:date returnType:NSFReturnKeys error:nil];
    
    STAssertTrue (([[searchResults lastObject]isKindOfClass:[NSString class]]), @"Expected the key to be a string.");
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 1), @"Expected to find one object.");
}

- (void)testSearchKeysAddedAfterCalendarDate
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:-(60 * 60)];

    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];

    NSArray *searchResults = [search searchObjectsAdded:NSFAfterDate date:date returnType:NSFReturnKeys error:nil];
    
    STAssertTrue (([[searchResults lastObject]isKindOfClass:[NSString class]]), @"Expected the key to be a string.");
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 2), @"Expected to find two objects.");
}

- (void)testSearchKeysAddedAfterCalendarDateFilterByClass
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Mercedes";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:car, person, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"kName";
    search.match = NSFEqualTo;
    search.value = @"Mercedes";
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:-(60 * 60)];
    
    NSArray *searchResults = [search searchObjectsAdded:NSFAfterDate date:date returnType:NSFReturnKeys error:nil];
    
    STAssertTrue (([[searchResults lastObject]isKindOfClass:[NSString class]]), @"Expected the key to be a string.");
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 1), @"Expected to find one object.");
}

#pragma mark -

- (void)testSearchExecuteNilSQL
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    @try {
        [search executeSQL:nil returnType:NSFReturnObjects error:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testSearchExecuteEmptySQL
{
    NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFMemoryStoreType path:nil];
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];

    @try {
        [search executeSQL:@"" returnType:NSFReturnObjects error:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testSearchExecuteSQLWithWrongColumnTypes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSDictionary *results = [search executeSQL:@"SELECT Blah, Foo, Bar FROM NSFKeys" returnType:NSFReturnObjects error:nil];
    
    STAssertTrue ([results count] == 2, @"Expected to find two objects.");
}

- (void)testSearchExecuteSQL
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSDictionary *result = [search executeSQL:@"SELECT * FROM NSFKEYS" returnType:NSFReturnObjects error:nil];
    
    STAssertTrue ([result count] == 2, @"Expected to find two objects.");
}

- (void)testSearchExecuteSQLCountKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSFNanoResult *result = [search executeSQL:@"SELECT COUNT(*) FROM NSFKEYS"];
    STAssertTrue ([result error] == nil, @"We didn't expect an error.");

    STAssertTrue (([result numberOfRows] == 1) && ([[result firstValue]isEqualToString:@"2"]), @"Expected to find one object containing the value '2'.");
}

- (void)testSearchExecuteBadSQLCountKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoResult *result = [nanoStore _executeSQL:@"SELECT COUNT FROM NSFKEYS"];
    
    BOOL containsErrorInfo = ([result error] != nil);
    
    STAssertTrue (containsErrorInfo == YES, @"Expected to find error information.");
}

- (void)testSearchExecuteSQLReturningKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSArray *result = [search executeSQL:@"SELECT * FROM NSFKEYS" returnType:NSFReturnKeys error:nil];
    
    STAssertTrue ([result isKindOfClass:[NSArray class]], @"Incorrect class returned. Expected NSArray.");
    STAssertTrue ([result count] == 2, @"Expected to find two objects.");
}

- (void)testSearchExecuteSQLReturningObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSDictionary *result = [search executeSQL:@"SELECT * FROM NSFKEYS" returnType:NSFReturnObjects error:nil];
    
    STAssertTrue ([result isKindOfClass:[NSDictionary class]], @"Incorrect class returned. Expected NSArray.");
    STAssertTrue ([result count] == 2, @"Expected to find two objects.");
}

- (void)testSearchReturningObjectsOfClassNSFNanoObject
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    BOOL isClassCorrect = [[searchResults objectForKey:obj1.key]isKindOfClass:[NSFNanoObject class]];
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 2) && isClassCorrect, @"Expected to find two objects of type NSFNanoObject.");
}

- (void)testSearchReturningObjectsWithCalendarDateOfClassNSFNanoObject
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSDate *date = [[NSDate date]dateByAddingTimeInterval:5];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsAdded:NSFBeforeDate date:date returnType:NSFReturnObjects error:nil];
    BOOL isClassCorrect = [[searchResults objectForKey:obj1.key]isKindOfClass:[NSFNanoObject class]];
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 2) && isClassCorrect, @"Expected to find two objects of type NSFNanoObject.");
}

- (void)testSearchFilteringResultsByClassReturnObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Mercedes";
    person.last = @"Doe";

    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:car, person, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"kName";
    search.match = NSFEqualTo;
    search.value = @"Mercedes";
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    BOOL isClassCorrect = [[searchResults objectForKey:car.key]isKindOfClass:[NanoCarTestClass class]];
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 1) && isClassCorrect, @"Expected to find one object of type NanoCarTestClass.");
}

- (void)testSearchFilteringResultsByClassReturnKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Mercedes";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:car, person, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"kName";
    search.match = NSFEqualTo;
    search.value = @"Mercedes";
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
    BOOL isClassCorrect = [[searchResults lastObject]isEqualToString:car.key];
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 1) && isClassCorrect, @"Expected to find one object of type NanoCarTestClass.");
}

- (void)testSearchWithExpressionAndFilteringObjectResultsByClass
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Mercedes";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:car, person, nil] error:nil];
        
    NSFNanoPredicate *predicateAttr = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"kName"];
    NSFNanoPredicate *predicateVal  = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:@"Mercedes"];
    NSFNanoExpression *expression   = [NSFNanoExpression expressionWithPredicate:predicateAttr];
    [expression addPredicate:predicateVal withOperator:NSFAnd];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object");
    
    BOOL isClassCorrect = [[searchResults objectForKey:car.key] isKindOfClass:[NanoCarTestClass class]];
    [nanoStore closeWithError:nil];
    STAssertTrue (isClassCorrect, @"Expected to find type NanoCarTestClass.");
}

- (void)testSearchWithExpressionAndFilteringKeyResultsByClass
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Mercedes";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:car, person, nil] error:nil];
    
    NSFNanoPredicate *predicateAttr = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"kName"];
    NSFNanoPredicate *predicateVal  = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:@"Mercedes"];
    NSFNanoExpression *expression   = [NSFNanoExpression expressionWithPredicate:predicateAttr];
    [expression addPredicate:predicateVal withOperator:NSFAnd];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObject:expression]];
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object");
    
    BOOL isClassCorrect = [[searchResults lastObject]isEqualToString:car.key];
    [nanoStore closeWithError:nil];
    STAssertTrue (isClassCorrect, @"Expected to find type NanoCarTestClass.");
}

#pragma mark -

- (void)testSearchObjectKnownInThisProcess
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];

    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");

    id objectReturned = [searchResults objectForKey:[[searchResults allKeys]lastObject]];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([objectReturned isKindOfClass:[NSFNanoObject class]] == YES) && (nil == [objectReturned originalClassString]), @"Expected to retrieve a pure NanoObject.");
}

- (void)testSearchObjectNotKnownInThisProcess
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    // Hack to change the class name in the store placing a bogus one...
    NSString *bogusClassName = @"foobar";
    NSString *obj1Key = obj1.key;
    NSString *theSQLStatement = [NSString stringWithFormat:@"UPDATE NSFKeys SET NSFObjectClass ='%@' WHERE NSFKey='%@'", bogusClassName, obj1Key];
    [nanoStore _executeSQL:theSQLStatement];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
    
    id objectReturned = [searchResults objectForKey:[[searchResults allKeys]lastObject]];

    [nanoStore closeWithError:nil];
    
    STAssertTrue (([objectReturned isKindOfClass:[NSFNanoObject class]] == YES) && ([[objectReturned originalClassString]isEqualToString:bogusClassName]), @"Expected to retrieve a NanoObject which an original class name of type 'foobar'.");
}

- (void)testSearchObjectNotKnownInThisProcessEditAndSave
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj1 error:nil];
    
    // Hack to change the class name in the store placing a bogus one...
    NSString *bogusClassName1 = @"foobar";
    NSString *obj1Key = obj1.key;
    NSString *theSQLStatement = [NSString stringWithFormat:@"UPDATE NSFKeys SET NSFObjectClass ='%@' WHERE NSFKey='%@'", bogusClassName1, obj1Key];
    [nanoStore _executeSQL:theSQLStatement];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
    
    // Make sure we have a NanoObject of class foobar
    NSFNanoObject *objectReturned = [searchResults objectForKey:[[searchResults allKeys]lastObject]];
    STAssertTrue (([objectReturned isKindOfClass:[NSFNanoObject class]] == YES) && ([[objectReturned originalClassString]isEqualToString:bogusClassName1]), @"Expected to retrieve a NanoObject which an original class name of type 'foobar'.");

    // Now, let's manipulate the original class name to make sure it gets honored and saved properly
    NSString *bogusClassName2 = @"superduper";
    [objectReturned removeAllObjects];
    [objectReturned setObject:@"fooValue" forKey:@"fooKey"];
    [objectReturned _setOriginalClassString:bogusClassName2];
    [nanoStore addObject:objectReturned error:nil];
    
    searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
    
    // Make sure the saving process honored the foobar class and didn't overwrite it with NSFNanoObject
    objectReturned = [searchResults objectForKey:[[searchResults allKeys]lastObject]];
    STAssertTrue (([objectReturned isKindOfClass:[NSFNanoObject class]] == YES) && ([[objectReturned originalClassString]isEqualToString:bogusClassName2]), @"Expected to retrieve a NanoObject which an original class name of type 'superduper'.");

    [nanoStore closeWithError:nil];
}

#pragma mark -

- (void)testAggregateFunctions
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    STAssertTrue ([[search aggregateOperation:NSFAverage onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFAverage to return a valid number.");
    STAssertTrue ([[search aggregateOperation:NSFCount onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFCount to return a valid number.");
    STAssertTrue ([[search aggregateOperation:NSFMax onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFMax to return a valid number.");
    STAssertTrue ([[search aggregateOperation:NSFMin onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFMin to return a valid number.");
    STAssertTrue ([[search aggregateOperation:NSFTotal onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFTotal to return a valid number.");
}

- (void)testAggregateFunctionsWithFilters
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]];
    NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:[NSFNanoStore _defaultTestData]];
    
    NSFNanoBag *bag = [NSFNanoBag bag];
    [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObject:bag] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"LastName";
    search.match = NSFEqualTo;
    search.value = @"Ciuro";
    
    STAssertTrue ([[search aggregateOperation:NSFAverage onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFAverage to return a valid number.");
    STAssertTrue ([[search aggregateOperation:NSFCount onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFCount to return a valid number.");
    STAssertTrue ([[search aggregateOperation:NSFMax onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFMax to return a valid number.");
    STAssertTrue ([[search aggregateOperation:NSFMin onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFMin to return a valid number.");
    STAssertTrue ([[search aggregateOperation:NSFTotal onAttribute:@"SomeNumber"]floatValue] != 0, @"Expected NSFTotal to return a valid number.");
}

#pragma mark -

- (void)testExplainSQLNil
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];

    @try {
        [search explainSQL:nil];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testExplainSQLEmpty
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    
    @try {
        [search explainSQL:@""];
    } @catch (NSException *e) {
        STAssertTrue (e != nil, @"We should have caught the exception.");
    }
}

- (void)testExplainSQLBogus
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSFNanoResult *results = [search explainSQL:@"foo bar"];
    STAssertTrue (([results error] != nil) && ([results numberOfRows] == 0), @"Expected an error and no rows back.");
}

- (void)testExplainSQL
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSFNanoResult *results = [search explainSQL:@"SELECT * FROM NSFKeys WHERE NSFKey = 'ABC'"];
    STAssertTrue (([results error] == nil) && ([results numberOfRows] > 0), @"Expected some rows back.");
}

- (void)testSearchTestFTS3
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    NSFNanoResult *results = [search executeSQL:@"CREATE VIRTUAL TABLE simple USING fts3(tokenize=simple);"];
    
    BOOL isLioniOS5OrLater = ((_systemVersion >= 10.7f) || (_systemVersion >= 5.1f));
    
    STAssertTrue (isLioniOS5OrLater && ([results error] == nil), @"Wasn't expecting an error.");
}

- (void)testSearchObjectsQuotes
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Leo'd";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:person, nil] error:nil];
    
    NSArray* allPeople = [nanoStore objectsOfClassNamed:NSStringFromClass([NanoPersonTestClass class])];
    STAssertTrue(([allPeople count] == 1), @"Should have one person");
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = NanoPersonFirst;
    search.match = NSFEqualTo;
    search.value = person.name;
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
    [nanoStore closeWithError:nil];
    
    STAssertTrue (([searchResults count] == 1), @"Expected to find one person object, found %d", [searchResults count]);
}

- (void)testSearchObjectsQuotesUsingExpression
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *person = [NanoPersonTestClass new];
    person.name = @"Leo'd";
    person.last = @"Doe";
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:person, nil] error:nil];
    
    NSFNanoObject *obj = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObject:obj error:nil];
    
    NSFNanoPredicate *firstNamePred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:NanoPersonFirst];
    NSFNanoPredicate *valuePred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:person.name];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:firstNamePred];
    [expression addPredicate:valuePred withOperator:NSFAnd];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObjects:expression, nil]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

#pragma mark -

- (void)testSearchWithNullValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *personA = [NanoPersonTestClass new];
    personA.name = @"Leo'd";
    personA.last = @"Doe";
    
    NSDictionary *info = @{@"name" : @"foo", @"last" : [NSNull null]};
    NSFNanoObject *personB = [NSFNanoObject nanoObjectWithDictionary:info];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:personA, personB, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.match = NSFEqualTo;
    search.value = [NSNull null];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
    STAssertTrue ([personB objectForKey:@"last"] == [NSNull null], @"Expected to find the NSNull object.");
}

- (void)testSearchWithAttributeHasNullValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *personA = [NanoPersonTestClass new];
    personA.name = @"Leo'd";
    personA.last = @"Doe";
    
    NSDictionary *info = @{@"name" : @"foo", @"last" : [NSNull null]};
    NSFNanoObject *personB = [NSFNanoObject nanoObjectWithDictionary:info];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:personA, personB, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = @"last";
    search.match = NSFEqualTo;
    search.value = [NSNull null];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
    STAssertTrue ([personB objectForKey:@"last"] == [NSNull null], @"Expected to find the NSNull object.");
}

- (void)testSearchWithAttributeDoesNotHaveNullValue
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *personA = [NanoPersonTestClass new];
    personA.name = @"Leo'd";
    personA.last = @"Doe";
    
    NSDictionary *info = @{NanoPersonFirst : @"foo", NanoPersonLast : [NSNull null]};
    NSFNanoObject *personB = [NSFNanoObject nanoObjectWithDictionary:info];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:personA, personB, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.attribute = NanoPersonLast;
    search.match = NSFNotEqualTo;
    search.value = [NSNull null];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    NanoPersonTestClass *retrievedObject = [[searchResults allValues]lastObject];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
    STAssertTrue ([retrievedObject isKindOfClass:[NanoPersonTestClass class]], @"Expected to find a NanoPersonTestClass object.");
    STAssertTrue ([[retrievedObject last]isEqualToString:@"Doe"], @"Expected to find the non-NSNull object.");
}

- (void)testSearchWithNullValuePredicate
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *personA = [NanoPersonTestClass new];
    personA.name = @"Leo'd";
    personA.last = @"Doe";
    
    NSDictionary *info = @{@"name" : @"foo", @"last" : [NSNull null]};
    NSFNanoObject *personB = [NSFNanoObject nanoObjectWithDictionary:info];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:personA, personB, nil] error:nil];
    
    NSFNanoPredicate *lastNamePred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"last"];
    NSFNanoPredicate *valuePred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:[NSNull null]];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:lastNamePred];
    [expression addPredicate:valuePred withOperator:NSFAnd];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObjects:expression, nil]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
    STAssertTrue ([personB objectForKey:@"last"] == [NSNull null], @"Expected to find the NSNull object.");
}

- (void)testSearchDoesNotHaveNullValuePredicate
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *personA = [NanoPersonTestClass new];
    personA.name = @"Leo'd";
    personA.last = @"Doe";
    
    NSDictionary *info = @{NanoPersonFirst : @"foo", NanoPersonLast : [NSNull null]};
    NSFNanoObject *personB = [NSFNanoObject nanoObjectWithDictionary:info];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:personA, personB, nil] error:nil];
    
    NSFNanoPredicate *lastNamePred = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:NanoPersonLast];
    NSFNanoPredicate *valuePred = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFNotEqualTo value:[NSNull null]];
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:lastNamePred];
    [expression addPredicate:valuePred withOperator:NSFAnd];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    [search setExpressions:[NSArray arrayWithObjects:expression, nil]];
    
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
    
    [nanoStore closeWithError:nil];
    
    NanoPersonTestClass *retrievedObject = [[searchResults allValues]lastObject];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
    STAssertTrue ([retrievedObject isKindOfClass:[NanoPersonTestClass class]], @"Expected to find a NanoPersonTestClass object.");
    STAssertTrue ([[retrievedObject last]isEqualToString:@"Doe"], @"Expected to find the non-NSNull object.");
}

- (void)testSearchFilterClassWithLimitReturnObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *personA = [NanoPersonTestClass new];
    personA.name = @"Leo'd";
    personA.last = @"Doe";
    
    NanoPersonTestClass *personB = [NanoPersonTestClass new];
    personB.name = @"Titus";
    personB.last = @"Magnus";
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:personA, personB, nil] error:nil];

    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.filterClass = NSStringFromClass([NanoPersonTestClass class]);
    search.limit = 2;

    NSError *error = nil;
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:&error];
    
    STAssertTrue ([searchResults count] == 2, @"Expected to find two objects.");
}

- (void)testSearchFilterClassWithNoLimitReturnObjects
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *personA = [NanoPersonTestClass new];
    personA.name = @"Leo'd";
    personA.last = @"Doe";
    
    NanoPersonTestClass *personB = [NanoPersonTestClass new];
    personB.name = @"Titus";
    personB.last = @"Magnus";
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:personA, personB, car, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSError *error = nil;
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:&error];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

- (void)testSearchFilterClassWithLimitReturnKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *personA = [NanoPersonTestClass new];
    personA.name = @"Leo'd";
    personA.last = @"Doe";
    
    NanoPersonTestClass *personB = [NanoPersonTestClass new];
    personB.name = @"Titus";
    personB.last = @"Magnus";
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:personA, personB, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.filterClass = NSStringFromClass([NanoPersonTestClass class]);
    search.limit = 2;
    
    NSError *error = nil;
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:&error];
    
    STAssertTrue ([searchResults count] == 2, @"Expected to find two objects.");
}

- (void)testSearchFilterClassNoLimitReturnKeys
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NanoPersonTestClass *personA = [NanoPersonTestClass new];
    personA.name = @"Leo'd";
    personA.last = @"Doe";
    
    NanoPersonTestClass *personB = [NanoPersonTestClass new];
    personB.name = @"Titus";
    personB.last = @"Magnus";
    
    NanoCarTestClass *car = [NanoCarTestClass new];
    car.name = @"Mercedes";
    car.key = [NSFNanoEngine stringWithUUID];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:personA, personB, car, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    search.filterClass = NSStringFromClass([NanoCarTestClass class]);
    
    NSError *error = nil;
    NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnKeys error:&error];
    
    STAssertTrue ([searchResults count] == 1, @"Expected to find one object.");
}

@end