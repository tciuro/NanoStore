//
//  NanoStoreTester.m
//  NanoStore
//
//  Created by Tito Ciuro on 10/5/08.
//  Copyright (c) 2013 Webbo, Inc. All rights reserved.
//

#import "NanoStore.h"
#import "NanoStoreTester.h"
#import "NSFNanoStore_Private.h"

@interface NanoStoreTester (Private)
- (NSDictionary *)defaultTestData;
- (void)removeStoreDatabase;
@end

@implementation NanoStoreTester

- (id)init
{
    if ((self = [super init])) {
        
        mRemoveStoreWhenFinished = YES;
        
        mStorePath = [[@"~/Desktop/NSFNanoStoreTest.data" stringByExpandingTildeInPath]retain];
        
        mDefaultTestInfo = [[NSFNanoStore _defaultTestData]retain];
        
    }
    
    return self;
}

- (void)dealloc
{
    [mStorePath release];
    [mDefaultTestInfo release];
    [super dealloc];
}

#pragma mark -

- (void)test
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:mDefaultTestInfo];
    NSString *key1 = [obj1 nanoObjectKey];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:mDefaultTestInfo];
    NSString *key2 = [obj2 nanoObjectKey];
    
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoSearch *search1 = [NSFNanoSearch searchWithStore:nanoStore];
    [search1 setKey:key1];
    NSArray *keys1 = [search1 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    NSFNanoSearch *search2 = [NSFNanoSearch searchWithStore:nanoStore];
    [search2 setKey:key2];
    NSArray *keys2 = [search2 searchObjectsWithReturnType:NSFReturnKeys error:nil];
    
    [nanoStore closeWithError:nil];
    
    if ([keys1 count] + [keys2 count] == 2)
        NSLog(@"Succeeded.");
    else
        NSLog(@"Expected to find the stored objects.");
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

- (void)removeStoreDatabase
{
    if (mRemoveStoreWhenFinished)
        [[NSFileManager defaultManager]removeItemAtPath:mStorePath error:nil];
}

@end
