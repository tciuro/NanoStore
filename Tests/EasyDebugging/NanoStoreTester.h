//
//  NanoStoreTester.h
//  NanoStore
//
//  Created by Tito Ciuro on 10/5/08.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

@interface NanoStoreTester : NSObject
{
    NSString        *mStorePath;
    BOOL            mRemoveStoreWhenFinished;
    NSDictionary    *mDefaultTestInfo;
}

- (void)test;

@end
