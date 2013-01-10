//
//  NanoPersonTestClass.m
//  NanoStore
//
//  Created by Tito Ciuro on 5/26/12.
//  Copyright (c) 2012 Webbo, LLC. All rights reserved.
//

#import "NanoPersonTestClass.h"

NSString *NanoPersonFirst = @"NanoPersonFirst";
NSString *NanoPersonLast  = @"NanoPersonLast";

@implementation NanoPersonTestClass

- (id)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)theDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)theStore
{
    if (self = [super initNanoObjectFromDictionaryRepresentation:nil forKey:aKey store:nil]) {
        _name = [theDictionary objectForKey:NanoPersonFirst];
        _last = [theDictionary objectForKey:NanoPersonLast];
    }
    
    return self;
}

- (NSDictionary *)nanoObjectDictionaryRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:_name, NanoPersonFirst,
            _last, NanoPersonLast,
            nil];
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
