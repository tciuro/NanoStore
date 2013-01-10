//
//  NanoPersonTestClass.h
//  NanoStore
//
//  Created by Tito Ciuro on 5/26/12.
//  Copyright (c) 2012 Webbo, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSFNanoObject.h"

extern NSString *NanoPersonFirst;
extern NSString *NanoPersonLast;

@interface NanoPersonTestClass : NSFNanoObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *last;

@end
