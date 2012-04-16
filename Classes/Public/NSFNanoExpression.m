/*
     NSFNanoExpression.m
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

#import "NSFNanoExpression.h"
#import "NanoStore_Private.h"

@implementation NSFNanoExpression
{
    /** \cond */
    NSMutableArray      *predicates;
    NSMutableArray      *operators;
    /** \endcond */
}

@synthesize predicates, operators;

+ (NSFNanoExpression*)expressionWithPredicate:(NSFNanoPredicate *)aPredicate
{
    if (nil == aPredicate)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: the predicate is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    return [[self alloc]initWithPredicate:aPredicate];
}

- (id)initWithPredicate:(NSFNanoPredicate *)aPredicate
{
    if (nil == aPredicate)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: the predicate is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    if ((self = [super init])) {
        predicates = [NSMutableArray new];
        [predicates addObject:aPredicate];
        operators = [NSMutableArray new];
        [operators addObject:[NSNumber numberWithInt:NSFAnd]];
    }
    
    return self;
}

/** \cond */


/** \endcond */

#pragma mark -

- (void)addPredicate:(NSFNanoPredicate *)aPredicate withOperator:(NSFOperator)someOperator
{
    if (nil == aPredicate)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: the predicate is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    [predicates addObject:aPredicate];
    [operators addObject:[NSNumber numberWithInt:someOperator]];
}

- (NSString *)description
{
    NSUInteger i, count = [predicates count];
    NSMutableArray *values = [NSMutableArray new];
    
    // We always have one predicate, so make sure add it
    [values addObject:[[predicates objectAtIndex:0]description]];

    for (i = 1; i < count; i++) {
        NSString *compound = [[NSString alloc]initWithFormat:@" %@ %@", ([[operators objectAtIndex:i]intValue] == NSFAnd) ? @"AND" : @"OR", [[predicates objectAtIndex:i]description]];
        [values addObject:compound];
    }
    
    NSString *value = [values componentsJoinedByString:@""];
    
    return value;
}

@end