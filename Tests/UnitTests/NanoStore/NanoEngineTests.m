//
//  NanoEngineTests.h
//  NanoStore
//
//  Created by Tito Ciuro on 9/11/10.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

#import "NanoStore.h"
#import "NanoEngineTests.h"
#import "NSFNanoStore_Private.h"

@implementation NanoEngineTests

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

- (void)testMaxROWUID
{
    NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
    [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
    
    NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:_defaultTestInfo];
    [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
    
    NSFNanoEngine *engine = [nanoStore nanoStoreEngine];
    long long maxRowUID = [engine maxRowUIDForTable:@"NSFKeys"];
    
    [nanoStore closeWithError:nil];
    
    STAssertTrue (maxRowUID == 2, @"Expected to find the max RowUID for the given table.");
}

@end