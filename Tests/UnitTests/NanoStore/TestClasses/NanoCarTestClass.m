//
//  NanoCarTestClass.m
//  NanoStore
//
//  Created by Tito Ciuro on 5/26/12.
//  Copyright (c) 2013 Webbo, Inc. All rights reserved.
//

#import "NanoCarTestClass.h"

#define kName   @"kName"

@implementation NanoCarTestClass

- (instancetype)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)theDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)theStore
{
    if (self = [self init]) {
        _name = theDictionary[kName];
        _key = aKey;
    }
    
    return self;
}

- (NSDictionary *)nanoObjectDictionaryRepresentation
{
    return @{kName: _name};
}

- (NSString *)nanoObjectKey
{
    return self.key;
}

- (id)rootObject
{
    return self;
}

@end
