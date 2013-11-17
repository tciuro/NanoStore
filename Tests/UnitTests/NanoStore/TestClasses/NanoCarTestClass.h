//
//  NanoCarTestClass.h
//  NanoStore
//
//  Created by Tito Ciuro on 5/26/12.
//  Copyright (c) 2013 Webbo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSFNanoObjectProtocol.h"

@interface NanoCarTestClass : NSObject <NSFNanoObjectProtocol>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *key;

@end
