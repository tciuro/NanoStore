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

@implementation NSFNanoPredicate

@synthesize column, match, value;

// ----------------------------------------------
// Initialization / Cleanup
// ----------------------------------------------

+ (NSFNanoPredicate*)predicateWithColumn:(NSFTableColumnType)type matching:(NSFMatchType)matching value:(NSString *)aValue
{
    if (nil == aValue)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: value is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    return [[self alloc]initWithColumn:type matching:matching value:aValue];
}

- (id)initWithColumn:(NSFTableColumnType)type matching:(NSFMatchType)matching value:(NSString *)aValue
{
    if (nil == aValue)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: value is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ((self = [super init])) {
        column = type;
        match = matching;
        value = aValue;
    }
    
    return self;
}

- (NSString *)description
{
    return [[self arrayDescription]lastObject];
}

- (NSArray *)arrayDescription
{
    NSMutableArray *values = [NSMutableArray new];
    
    NSString *columnValue = nil;
    NSMutableString *mutatedString = nil;
    NSInteger mutatedStringLength = 0;
    
    switch (column) {
        case NSFKeyColumn:
            columnValue = NSFKey;
            break;
        case NSFAttributeColumn:
            columnValue = NSFAttribute;
            break;
        default:
            columnValue = NSFValue;
            break;
    }
    
    // Make sure we escape quotes if present and the value is a string
    value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    
    switch (match) {
        case NSFEqualTo:
            [values addObject:[NSString stringWithFormat:@"%@ = '%@'", columnValue, value]];
            break;
        case NSFBeginsWith:
            mutatedString = [NSMutableString stringWithString:value];
            mutatedStringLength = [value length];
            [mutatedString replaceCharactersInRange:NSMakeRange(mutatedStringLength - 1, 1) withString:[NSString stringWithFormat:@"%c", [mutatedString characterAtIndex:mutatedStringLength - 1]+1]];
            [values addObject:[NSString stringWithFormat:@"(%@ >= '%@' AND %@ < '%@')", columnValue, value, columnValue, mutatedString]];
            break;
        case NSFContains:
            [values addObject:[NSString stringWithFormat:@"%@ GLOB '*%@*'", columnValue, value]];
            break;
        case NSFEndsWith:
            [values addObject:[NSString stringWithFormat:@"%@ GLOB '*%@'", columnValue, value]];
            break;
        case NSFInsensitiveEqualTo:
            [values addObject:[NSString stringWithFormat:@"upper(%@) = '%@'", columnValue, [value uppercaseString]]];
            break;
        case NSFInsensitiveBeginsWith:
            mutatedString = [NSMutableString stringWithString:value];
            mutatedStringLength = [value length];
            [mutatedString replaceCharactersInRange:NSMakeRange(mutatedStringLength - 1, 1) withString:[NSString stringWithFormat:@"%c", [mutatedString characterAtIndex:mutatedStringLength - 1]+1]];
            [values addObject:[NSString stringWithFormat:@"(upper(%@) >= '%@' AND upper(%@) < '%@')", columnValue, [value uppercaseString], columnValue, [mutatedString uppercaseString]]];
            break;
        case NSFInsensitiveContains:
            [values addObject:[NSString stringWithFormat:@"%@ LIKE '%@%@%@'", columnValue, @"%", value, @"%"]];
            break;
        case NSFInsensitiveEndsWith:
            [values addObject:[NSString stringWithFormat:@"%@ LIKE '%@%@'", columnValue, @"%", value]];
            break;
        case NSFGreaterThan:
            [values addObject:[NSString stringWithFormat:@"%@ > '%@'", columnValue, value]];
            break;
        case NSFLessThan:
            [values addObject:[NSString stringWithFormat:@"%@ < '%@'", columnValue, value]];
            break;
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

/** \cond */


/** \endcond */

@end
