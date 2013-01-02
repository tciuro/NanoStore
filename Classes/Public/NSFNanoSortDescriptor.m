/*
     NSFNanoSortDescriptor.m
     NanoStore
     
     Copyright (c) 2010 Webbo, L.L.C. All rights reserved.
     
     Redistribution and use in source and binary forms, with or without modification, are permitted
     provided that the following conditions are met:
     
     * Redistributions of source code must retain the above copyright notice, this list of conditions
     and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
     and the following disclaimer in the documentation and/or other materials provided with the distribution.
     * Neither the name of Webbo nor the names of its contributors may be used to endorse or promote
     products derived from this software without specific prior written permission.
     
     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
     WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
     PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY
     DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
     PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
     OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
     SUCH DAMAGE.
 */

#import "NSFNanoSortDescriptor.h"
#import "NSFNanoGlobals.h"
#import "NSFOrderedDictionary.h"
#import "NSFNanoObject_Private.h"

@interface NSFNanoSortDescriptor ()

/** \cond */
@property (nonatomic, copy, readwrite) NSString *attribute;
@property (nonatomic, readwrite) BOOL isAscending;
/** \endcond */

@end

@implementation NSFNanoSortDescriptor

+ (NSFNanoSortDescriptor *)sortDescriptorWithAttribute:(NSString *)theAttribute ascending:(BOOL)ascending
{
    return [[self alloc]initWithAttribute:theAttribute ascending:ascending];
}

- (id)initWithAttribute:(NSString *)theAttribute ascending:(BOOL)ascending
{
    if (theAttribute.length == 0)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theAttribute is invalid.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ((self = [super init])) {
        _attribute = theAttribute;
        _isAscending = ascending;
    }
    
    return self;
}

/** \cond */


/** \endcond */

#pragma mark -

- (NSString *)description
{
    return [self JSONDescription];
}

- (NSFOrderedDictionary *)dictionaryDescription
{
    NSFOrderedDictionary *values = [NSFOrderedDictionary new];
    
    values[@"Sort descriptor address"] = [NSString stringWithFormat:@"%p", self];
    values[@"Attribute"] = _attribute;
    values[@"Is ascending?"] = (_isAscending ? @"YES" : @"NO");
    
    return values;
}

- (NSString *)JSONDescription
{
    NSFOrderedDictionary *values = [self dictionaryDescription];
    
    NSError *outError = nil;
    NSString *description = [NSFNanoObject _NSObjectToJSONString:values error:&outError];
    
    return description;
}

@end