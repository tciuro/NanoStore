//
//  NanoPersonTestClass.m
//  NanoStore
//
//  Created by Tito Ciuro on 5/26/12.
//  Copyright (c) 2013 Webbo, Inc. All rights reserved.
//

#import "NanoPersonTestClass.h"

NSString *NanoPersonFirst = @"NanoPersonFirst";
NSString *NanoPersonLast  = @"NanoPersonLast";

@implementation NanoPersonTestClass

- (instancetype)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)theDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)theStore
{
    if (self = [super initNanoObjectFromDictionaryRepresentation:nil forKey:aKey store:nil]) {
        _name = theDictionary[NanoPersonFirst];
        _last = theDictionary[NanoPersonLast];
    }
    
    return self;
}

- (NSDictionary *)nanoObjectDictionaryRepresentation
{
    return @{NanoPersonFirst: _name,
            NanoPersonLast: _last};
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
