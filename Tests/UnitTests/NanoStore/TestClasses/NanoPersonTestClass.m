//
//  NanoPersonTestClass.m
//  NanoStore
//
//  Created by Tito Ciuro on 5/26/12.
//  Copyright (c) 2012 Webbo, LLC. All rights reserved.
//

#import "NanoPersonTestClass.h"

#define kName   @"kName"
#define kLast   @"kLast"

@implementation NanoPersonTestClass

@synthesize name;
@synthesize last;
@synthesize key;

- (id)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)theDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)theStore
{
    if (self = [self init]) {
        self.name = [theDictionary objectForKey:kName];
        self.last = [theDictionary objectForKey:kLast];
        self.key = aKey;
    }
    
    return self;
}

- (NSDictionary *)nanoObjectDictionaryRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:self.name, kName,
            self.last, kLast,
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
