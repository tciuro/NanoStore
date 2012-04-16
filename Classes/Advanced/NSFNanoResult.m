/*
     NSFNanoResult.m
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

#import "NSFNanoResult.h"
#import "NanoStore_Private.h"

@implementation NSFNanoResult
{
@protected
    /** \cond */
    NSDictionary    *results;
    /** \endcond */
}

@synthesize numberOfRows;
@synthesize error;

/** \cond */

- (id)init
{
    if ((self = [super init])) {
        [self _reset];
    }
    
    return self;
}

- (void)dealloc
{
    [self _reset];
}
/** \endcond */

- (NSString *)description
{
    NSUInteger numberOfColumns = [[results allKeys]count];
    
    NSMutableString *description = [NSMutableString string];
    [description appendString:@"\n"];
    [description appendString:[NSString stringWithFormat:@"Result address     : 0x%x\n", self]];
    [description appendString:[NSString stringWithFormat:@"Number of columns  : %ld\n", numberOfColumns]];
    if (nil == error)
        if ([[self columns]count] > 0)
            [description appendString:[NSString stringWithFormat:@"Columns            : %@\n", [[self columns]componentsJoinedByString:@", "]]];
        else
            [description appendString:[NSString stringWithFormat:@"Columns            : %@\n", @"()"]];
        else
            [description appendString:[NSString stringWithFormat:@"Columns            : %@\n", @"<column info not available>"]];
    [description appendString:[NSString stringWithFormat:@"Number of rows     : %ld\n", numberOfRows]];
    if (nil == error)
        [description appendString:[NSString stringWithFormat:@"Error              : %@\n", @"<no error>"]];
    else
        [description appendString:[NSString stringWithFormat:@"Error              : %@\n", [error localizedDescription]]];
    
    // Print up to the first ten rows to help visualize the cursor
    if (0 != numberOfColumns) {
        [description appendString:@"Preview of contents:\n                     "];
        NSUInteger i;
        NSArray *columns = [self columns];
        
        // Print the names of the columns
        [description appendString:[NSString stringWithFormat:@"%-15@ | ", @"Row #          "]];
        for (i = 0; i < numberOfColumns; i++) {
            const char *value = [[columns objectAtIndex:i]UTF8String];
            if (numberOfColumns - 1 > i) {
                [description appendString:[NSString stringWithFormat:@"%-15s | ", value]];
            } else {
                [description appendString:[NSString stringWithFormat:@"%-15s\n                     ", value]];
            }
        }
        
        // Print the underline
        const char *value = "===============";
        [description appendString:[NSString stringWithFormat:@"%-15s | ", value]];
        for (i = 0; i < numberOfColumns; i++) {
            if (numberOfColumns - 1 > i) {
                [description appendString:[NSString stringWithFormat:@"%-15s | ", value]];
            } else {
                [description appendString:[NSString stringWithFormat:@"%-15s\n                     ", value]];
            }
        }
        
        // Print the preview of the contents
        if (numberOfRows > 0) {
            NSInteger numberOfRowsToPrint = numberOfRows;
            NSUInteger j;
            
            if (numberOfRows > 100) {
                numberOfRowsToPrint = 100;
            }
            
            for (i = 0; i < numberOfRowsToPrint; i++) {
                [description appendString:[NSString stringWithFormat:@"%-15ld | ", i]];
                for (j = 0; j < numberOfColumns; j++) {
                    NSString *columnName = [columns objectAtIndex:j];
                    const char *value = "<plist data>    ";
                    if (NO == [columnName hasSuffix:@"NSFPlist"]) {
                        value = [[self valueAtIndex:i forColumn:columnName]UTF8String];
                    }
                    
                    if (numberOfColumns - 1 > j) {
                        [description appendString:[NSString stringWithFormat:@"%-15s | ", value]];
                    } else {
                        [description appendString:[NSString stringWithFormat:@"%-15s", value]];
                    }
                }
                
                [description appendString:@"\n                     "];
            }
        } else {
            [description appendString:@"<no data available>"];
        }
    }
    
    return description;
}

#pragma mark -

- (NSArray *)columns
{
    return [results allKeys];
}

- (NSString *)valueAtIndex:(NSUInteger)index forColumn:(NSString *)column
{
    return [[results objectForKey:column]objectAtIndex:index];
}

- (NSArray *)valuesForColumn:(NSString *)column
{
    NSArray *values = [results objectForKey:column];
    
    if (nil == values)
        values = [NSArray array];
    
    return values;
}

- (NSString *)firstValue
{
    NSArray *columns = [results allKeys];
    if (([columns count] > 0) && (numberOfRows > 0)) {
        return [[results objectForKey:[columns objectAtIndex:0]]objectAtIndex:0];
    }
    
    return nil;
}

- (NSError *)error
{
    return [error copy];
}

- (void)writeToFile:(NSString *)path;
{
    [results writeToFile:[path stringByExpandingTildeInPath] atomically:YES];
}

#pragma mark - Private Methods
#pragma mark -

/** \cond */
+ (NSFNanoResult *)_resultWithDictionary:(NSDictionary *)theResults
{
    return [[self alloc]_initWithDictionary:theResults];
}

+ (NSFNanoResult *)_resultWithError:(NSError *)theError
{
    return [[self alloc]_initWithError:theError];
}

- (id)_initWithDictionary:(NSDictionary *)theResults
{
    if (nil == theResults)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: theResults is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    if ([theResults respondsToSelector:@selector(objectForKey:)] == NO)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: theResults is not of type NSDictionary.", [self class], _cmd]
                               userInfo:nil]raise];
    
    if ((self = [self init])) {
        results = theResults;
        [self _calculateNumberOfRows];
    }
    
    return self;
}

- (id)_initWithError:(NSError *)theError
{
    if (nil == theError)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: theError is nil.", [self class], _cmd]
                               userInfo:nil]raise];
    
    if ([theError respondsToSelector:@selector(localizedDescription)] == NO)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %s]: theError is not of type NSError.", [self class], _cmd]
                               userInfo:nil]raise];
    
    if ((self = [self init])) {
        error = theError;
        [self _calculateNumberOfRows];
    }
    
    return self;
}

- (void)_setError:(NSError *)theError
{
    if (error != theError) {
        error = theError;
    }
}

- (void)_reset
{
    numberOfRows = -1;
    results = nil;
    error = nil;
}

- (void)_calculateNumberOfRows
{
    // We cache the value once, for performance reasons
    if (-1 == numberOfRows) {
        NSArray *allKeys = [results allKeys];
        if ([allKeys count] == 0)
            numberOfRows = 0;
        else
            numberOfRows = [[results objectForKey:[allKeys lastObject]]count];
    }
}
/** \endcond */

@end