//
//  NanoCarTestClass.m
//  NanoStore
//
//  Created by Tito Ciuro on 5/26/12.
//  Copyright (c) 2012 Webbo, LLC. All rights reserved.
//

#import "NanoCarTestClass.h"

#define kName   @"kName"

@implementation NanoCarTestClass

- (id)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)theDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)theStore
{
    if (self = [self init]) {
        _name = [theDictionary objectForKey:kName];
        _key = aKey;
    }
    
    return self;
}

- (NSDictionary *)nanoObjectDictionaryRepresentation
{
    return [NSDictionary dictionaryWithObject:_name forKey:kName];
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
