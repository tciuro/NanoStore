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
#import "NSFOrderedDictionary.h"

@implementation NSFNanoExpression
{
    /** \cond */
    NSMutableArray *_predicates;
    NSMutableArray *_operators;
    /** \endcond */
}

+ (NSFNanoExpression*)expressionWithPredicate:(NSFNanoPredicate *)aPredicate
{
    return [[self alloc]initWithPredicate:aPredicate];
}

- (id)initWithPredicate:(NSFNanoPredicate *)aPredicate
{
    if (nil == aPredicate) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the predicate is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    if ((self = [super init])) {
        _predicates = [NSMutableArray new];
        [_predicates addObject:aPredicate];
        _operators = [NSMutableArray new];
        [_operators addObject:[NSNumber numberWithInt:NSFAnd]];
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
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the predicate is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    [_predicates addObject:aPredicate];
    [_operators addObject:[NSNumber numberWithInt:someOperator]];
}

- (NSString *)description
{
    NSArray *values = [self arrayDescription];
    
    return [values componentsJoinedByString:@""];
}

- (NSArray *)arrayDescription
{
    NSUInteger i, count = [_predicates count];
    NSMutableArray *values = [NSMutableArray new];
    
    // We always have one predicate, so make sure add it
    [values addObject:[[_predicates objectAtIndex:0]description]];
    
    for (i = 1; i < count; i++) {
        NSString *compound = [[NSString alloc]initWithFormat:@" %@ %@", ([[_operators objectAtIndex:i]intValue] == NSFAnd) ? @"AND" : @"OR", [[_predicates objectAtIndex:i]description]];
        [values addObject:compound];
    }
    
    return values;
}

- (NSString *)JSONDescription
{
    NSArray *values = [self arrayDescription];
    
    NSError *outError = nil;
    NSString *description = [NSFNanoObject _NSObjectToJSONString:values error:&outError];
    
    return description;
}

@end