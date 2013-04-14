//
//  NanoStoreGlobalsTests.m
//  NanoStore
//
//  Created by Tito Ciuro on 4/18/12.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

#import "NanoStore.h"
#import "NanoStoreGlobalsTests.h"
#import "NSFNanoGlobals.h"
#import "NSFNanoGlobals_Private.h"
#import "NSFNanoStore_Private.h"

@interface NanoStoreGlobalsTests ()
@property (nonatomic) NSDictionary *defaultTestInfo;
@end

@implementation NanoStoreGlobalsTests

- (void)setUp
{
    [super setUp];
    
    _defaultTestInfo = [NSFNanoStore _defaultTestData];
    
    NSFSetIsDebugOn (NO);
}

- (void)tearDown
{
    _defaultTestInfo = nil;
    
    NSFSetIsDebugOn (NO);
    
    [super tearDown];
}

#pragma mark -

- (void)testCheckDebugOn
{
    NSFSetIsDebugOn (YES);
    BOOL isDebugOn = NSFIsDebugOn();
    STAssertTrue (isDebugOn, @"Expected isDebugOn to be YES.");
}

- (void)testCheckDebugOff
{
    NSFSetIsDebugOn (NO);
    BOOL isDebugOn = NSFIsDebugOn();
    STAssertTrue (NO == isDebugOn, @"Expected isDebugOn to be NO.");
}

- (void)testStringFromNanoDataType
{
    STAssertTrue([NSFStringFromNanoDataType(NSFNanoTypeUnknown) isEqualToString:@"UNKNOWN"], @"Expected to receive UNKNOWN.");
    STAssertTrue([NSFStringFromNanoDataType(NSFNanoTypeData) isEqualToString:@"BLOB"], @"Expected to receive BLOB.");
    STAssertTrue([NSFStringFromNanoDataType(NSFNanoTypeString) isEqualToString:@"TEXT"], @"Expected to receive TEXT.");
    STAssertTrue([NSFStringFromNanoDataType(NSFNanoTypeDate) isEqualToString:@"TEXT"], @"Expected to receive TEXT.");
    STAssertTrue([NSFStringFromNanoDataType(NSFNanoTypeNumber) isEqualToString:@"REAL"], @"Expected to receive REAL.");
    STAssertTrue([NSFStringFromNanoDataType(NSFNanoTypeRowUID) isEqualToString:@"INTEGER"], @"Expected to receive INTEGER.");
}

- (void)testNanoDataTypeFromString
{
    STAssertTrue(NSFNanoTypeUnknown == NSFNanoDatatypeFromString(@"UNKNOWN"), @"Expected to receive NSFNanoTypeUnknown.");
    STAssertTrue(NSFNanoTypeData == NSFNanoDatatypeFromString(@"BLOB"), @"Expected to receive NSFNanoTypeData.");
    STAssertTrue(NSFNanoTypeString || NSFNanoTypeDate == NSFNanoDatatypeFromString(@"TEXT"), @"Expected to receive NSFNanoTypeString or NSFNanoTypeDate.");
    STAssertTrue(NSFNanoTypeNumber == NSFNanoDatatypeFromString(@"REAL"), @"Expected to receive NSFNanoTypeNumber.");
    STAssertTrue(NSFNanoTypeRowUID == NSFNanoDatatypeFromString(@"INTEGER"), @"Expected to receive NSFNanoTypeRowUID.");                                        
}

- (void)testStringFromMatchType
{
    STAssertTrue([NSFStringFromMatchType(NSFEqualTo) isEqualToString:@"Equal to"], @"Expected to receive UNKNOWN.");
    STAssertTrue([NSFStringFromMatchType(NSFBeginsWith) isEqualToString:@"Begins with"], @"Expected to receive Begins with.");
    STAssertTrue([NSFStringFromMatchType(NSFContains) isEqualToString:@"Contains"], @"Expected to receive Contains.");
    STAssertTrue([NSFStringFromMatchType(NSFEndsWith) isEqualToString:@"Ends with"], @"Expected to receive Ends with.");
    STAssertTrue([NSFStringFromMatchType(NSFInsensitiveEqualTo) isEqualToString:@"Equal to (case insensitive)"], @"Expected to receive Equal to (case insensitive).");
    STAssertTrue([NSFStringFromMatchType(NSFInsensitiveBeginsWith) isEqualToString:@"Begins with (case insensitive)"], @"Expected to receive Begins with (case insensitive).");
    STAssertTrue([NSFStringFromMatchType(NSFInsensitiveContains) isEqualToString:@"Contains (case insensitive)"], @"Expected to receive Contains (case insensitive).");
    STAssertTrue([NSFStringFromMatchType(NSFInsensitiveEndsWith) isEqualToString:@"Ends with (case insensitive)"], @"Expected to receive Ends with (case insensitive).");
    STAssertTrue([NSFStringFromMatchType(NSFGreaterThan) isEqualToString:@"Greater than"], @"Expected to receive Greater than.");
    STAssertTrue([NSFStringFromMatchType(NSFLessThan) isEqualToString:@"Less than"], @"Expected to receive Less than.");
}

- (void)testNSFLog
{
    NSFSetIsDebugOn (YES);
    _NSFLog(@"Testing testNSFLog's coverage.");
}

- (void)testAllClassDescriptions
{
    NSString *description = nil;
    
    NSFNanoEngine *engine = [NSFNanoEngine databaseWithPath:@":memory:"];
    description = [engine JSONDescription];
    STAssertTrue([description length] > 0, @"Expected NSFNanoEngine's JSONDescription value to be valid.");
    
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    description = [nanoStore JSONDescription];
    STAssertTrue([description length] > 0, @"Expected NSFNanoStore's JSONDescription value to be valid.");
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    description = [obj1 JSONDescription];
    STAssertTrue([description length] > 0, @"Expected NSFNanoObject's JSONDescription value to be valid.");
    
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
    description = [search JSONDescription];
    STAssertTrue([description length] > 0, @"Expected NSFNanoSearch's JSONDescription value to be valid.");

    NSFNanoResult *result = [search executeSQL:@"SELECT COUNT(*) FROM NSFKEYS"];
    description = [result JSONDescription];
    STAssertTrue([description length] > 0, @"Expected NSFNanoResult's JSONDescription value to be valid.");
    
    NSFNanoSortDescriptor *sortDescriptor = [[NSFNanoSortDescriptor alloc]initWithAttribute:@"foo" ascending:YES];
    description = [sortDescriptor JSONDescription];
    STAssertTrue([description length] > 0, @"Expected NSFNanoSortDescriptor's JSONDescription value to be valid.");
    
    NSFNanoPredicate *predicate = [[NSFNanoPredicate alloc]initWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"foo"];
    description = [predicate JSONDescription];
    STAssertTrue([description length] > 0, @"Expected NSFNanoPredicate's JSONDescription value to be valid.");
    
    NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:predicate];
    description = [expression JSONDescription];
    STAssertTrue([description length] > 0, @"Expected NSFNanoExpression's JSONDescription value to be valid.");
    
    NSFNanoBag *bag = [NSFNanoBag bagWithObjects:@[obj1]];
    description = [bag JSONDescription];
    STAssertTrue([description length] > 0, @"Expected NSFNanoBag's JSONDescription value to be valid.");
}

@end
