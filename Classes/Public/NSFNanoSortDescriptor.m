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

@implementation NSFNanoSortDescriptor
{
    /** \cond */
    NSString    *attribute;
    BOOL        isAscending;
    /** \endcond */
}

@synthesize attribute, isAscending;

+ (NSFNanoSortDescriptor *)sortDescriptorWithAttribute:(NSString *)theAttribute ascending:(BOOL)ascending
{
    return [[self alloc]initWithAttribute:theAttribute ascending:ascending];
}

- (id)initWithAttribute:(NSString *)theAttribute ascending:(BOOL)ascending
{
    if (theAttribute.length == 0)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: theAttribute is invalid.", [self class], _cmd]
                               userInfo:nil]raise];
    
    if ((self = [super init])) {
        attribute = [theAttribute copy];
        isAscending = ascending;
    }
    
    return self;
}

/** \cond */


/** \endcond */

#pragma mark -

- (NSString*)description
{
    NSMutableString *description = [NSMutableString string];
    
    [description appendString:@"\n"];
    [description appendString:[NSString stringWithFormat:@"Sort descriptor address  : 0x%x\n", self]];
    [description appendString:[NSString stringWithFormat:@"Attribute                : %@\n", attribute]];
    [description appendString:[NSString stringWithFormat:@"Is ascending?            : %@\n", (isAscending ? @"YES" : @"NO")]];
    
    return description;
}

@end