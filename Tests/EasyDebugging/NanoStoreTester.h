//
//  NanoStoreTester.h
//  NanoStore
//
//  Created by Tito Ciuro on 10/5/08.
//  Copyright (c) 2013 Webbo, Inc. All rights reserved.
//

@interface NanoStoreTester : NSObject
{
    NSString        *mStorePath;
    BOOL            mRemoveStoreWhenFinished;
    NSDictionary    *mDefaultTestInfo;
}

- (void)test;

@end
