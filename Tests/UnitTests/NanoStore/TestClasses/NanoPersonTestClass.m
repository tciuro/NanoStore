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

@synthesize name;
@synthesize last;
@synthesize key;

- (id)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)theDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)theStore
{
    if (self = [self init]) {
        self.name = [theDictionary objectForKey:NanoPersonFirst];
        self.last = [theDictionary objectForKey:NanoPersonLast];
        self.key = aKey;
    }
    
    return self;
}

- (NSDictionary *)nanoObjectDictionaryRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:self.name, NanoPersonFirst,
            self.last, NanoPersonLast,
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
