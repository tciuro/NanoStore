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

@interface NSFNanoResult ()

/** \cond */
@property (nonatomic, assign, readwrite) NSUInteger numberOfRows;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic) NSDictionary *results;
/** \endcond */

@end

@implementation NSFNanoResult

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
    NSUInteger numberOfColumns = [[_results allKeys]count];
    
    NSMutableString *description = [NSMutableString string];
    [description appendString:@"\n"];
    [description appendString:[NSString stringWithFormat:@"Result address     : %p\n", self]];
    [description appendString:[NSString stringWithFormat:@"Number of columns  : %ld\n", numberOfColumns]];
    if (nil == _error)
        if ([[self columns]count] > 0)
            [description appendString:[NSString stringWithFormat:@"Columns            : %@\n", [[self columns]componentsJoinedByString:@", "]]];
        else
            [description appendString:[NSString stringWithFormat:@"Columns            : %@\n", @"()"]];
        else
            [description appendString:[NSString stringWithFormat:@"Columns            : %@\n", @"<column info not available>"]];
    [description appendString:[NSString stringWithFormat:@"Number of rows     : %ld\n", _numberOfRows]];
    if (nil == _error)
        [description appendString:[NSString stringWithFormat:@"Error              : %@\n", @"<no error>"]];
    else
        [description appendString:[NSString stringWithFormat:@"Error              : %@\n", [_error localizedDescription]]];
    
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
        if (_numberOfRows > 0) {
            NSInteger numberOfRowsToPrint = _numberOfRows;
            NSUInteger j;
            
            if (_numberOfRows > 100) {
                numberOfRowsToPrint = 100;
            }
            
            for (i = 0; i < numberOfRowsToPrint; i++) {
                [description appendString:[NSString stringWithFormat:@"%-15ld | ", i]];
                for (j = 0; j < numberOfColumns; j++) {
                    NSString *columnName = [columns objectAtIndex:j];
                    const char *value = "<plist data>    ";
                    if (NO == [columnName hasSuffix:@"NSFKeyedArchive"]) {
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

- (NSFOrderedDictionary *)dictionaryDescription
{
    NSUInteger numberOfColumns = [[_results allKeys]count];

    NSFOrderedDictionary *values = [NSFOrderedDictionary new];
    
    values[@"Result address"] = [NSString stringWithFormat:@"%p", self];
    values[@"Number of columns"] = @(numberOfColumns);
    if (nil == _error) {
        if ([[self columns]count] > 0) {
            values[@"Columns"] = [[self columns]componentsJoinedByString:@", "];
        } else {
            values[@"Columns"] = @"()";
        }
    } else {
        values[@"Columns"] = @"<column info not available>";
    }
    values[@"Number of rows"] = @(_numberOfRows);
    if (nil == _error) {
        values[@"Error"] = @"<nil>";
    } else {
        values[@"Error"] = [NSString stringWithFormat:@"%@", [_error localizedDescription]];
    }
    
    // Print up to the first ten rows to help visualize the cursor
    if (0 != numberOfColumns) {
        NSUInteger i;
        NSArray *columns = [self columns];
        NSMutableString *contentString = [NSMutableString new];
        NSMutableArray *printedContent = [NSMutableArray new];
        
        // Print the names of the columns
        [contentString appendString:[NSString stringWithFormat:@"%-15@ | ", @"Row #          "]];
        for (i = 0; i < numberOfColumns; i++) {
            const char *value = [[columns objectAtIndex:i]UTF8String];
            if (numberOfColumns - 1 > i) {
                [contentString appendString:[NSString stringWithFormat:@"%-15s | ", value]];
            } else {
                [contentString appendString:[NSString stringWithFormat:@"%-15s", value]];
            }
        }
        [printedContent addObject:[contentString copy]];
        
        // Print the underline
        [contentString setString:@""];
        const char *value = "===============";
        [contentString appendString:[NSString stringWithFormat:@"%-15s | ", value]];
        for (i = 0; i < numberOfColumns; i++) {
            if (numberOfColumns - 1 > i) {
                [contentString appendString:[NSString stringWithFormat:@"%-15s | ", value]];
            } else {
                [contentString appendString:[NSString stringWithFormat:@"%-15s", value]];
            }
        }
        [printedContent addObject:[contentString copy]];

        // Print the preview of the contents
        if (_numberOfRows > 0) {
            NSInteger numberOfRowsToPrint = _numberOfRows;
            NSUInteger j;
            
            if (_numberOfRows > 100) {
                numberOfRowsToPrint = 100;
            }
            
            [contentString setString:@""];

            for (i = 0; i < numberOfRowsToPrint; i++) {
                [contentString appendString:[NSString stringWithFormat:@"%-15ld | ", i]];
                for (j = 0; j < numberOfColumns; j++) {
                    NSString *columnName = [columns objectAtIndex:j];
                    const char *value = "<plist data>    ";
                    if (NO == [columnName hasSuffix:@"NSFPlist"]) {
                        value = [[self valueAtIndex:i forColumn:columnName]UTF8String];
                    }
                    
                    if (numberOfColumns - 1 > j) {
                        [contentString appendString:[NSString stringWithFormat:@"%-15s | ", value]];
                    } else {
                        [contentString appendString:[NSString stringWithFormat:@"%-15s", value]];
                    }
                }
                
                [printedContent addObject:[contentString copy]];
            }
        } else {
            [printedContent addObject:@"<no data available>"];
        }
        
        values[@"Preview of contents"] = printedContent;
    }
    
    return values;
}

- (NSString *)JSONDescription
{
    NSFOrderedDictionary *values = [self dictionaryDescription];
    
    NSError *outError = nil;
    NSString *description = [NSFNanoObject _NSObjectToJSONString:values error:&outError];
    if (nil != outError) {
        description = [outError localizedDescription];
    }
    
    return description;
}

#pragma mark -

- (NSArray *)columns
{
    return [_results allKeys];
}

- (NSString *)valueAtIndex:(NSUInteger)index forColumn:(NSString *)column
{
    return [[_results objectForKey:column]objectAtIndex:index];
}

- (NSArray *)valuesForColumn:(NSString *)column
{
    NSArray *values = [_results objectForKey:column];
    
    if (nil == values)
        values = [NSArray array];
    
    return values;
}

- (NSString *)firstValue
{
    NSArray *columns = [_results allKeys];
    if (([columns count] > 0) && (_numberOfRows > 0)) {
        return [[_results objectForKey:[columns objectAtIndex:0]]objectAtIndex:0];
    }
    
    return nil;
}

- (void)writeToFile:(NSString *)path;
{
    [_results writeToFile:[path stringByExpandingTildeInPath] atomically:YES];
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
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theResults is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ([theResults respondsToSelector:@selector(objectForKey:)] == NO)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theResults is not of type NSDictionary.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ((self = [self init])) {
        _results = theResults;
        [self _calculateNumberOfRows];
    }
    
    return self;
}

- (id)_initWithError:(NSError *)theError
{
    if (nil == theError)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theError is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ([theError respondsToSelector:@selector(localizedDescription)] == NO)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theError is not of type NSError.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ((self = [self init])) {
        _error = theError;
        [self _calculateNumberOfRows];
    }
    
    return self;
}

- (void)_reset
{
    _numberOfRows = -1;
    _results = nil;
    _error = nil;
}

- (void)_calculateNumberOfRows
{
    // We cache the value once, for performance reasons
    if (-1 == _numberOfRows) {
        NSArray *allKeys = [_results allKeys];
        if ([allKeys count] == 0)
            _numberOfRows = 0;
        else
            _numberOfRows = [[_results objectForKey:[allKeys lastObject]]count];
    }
}
/** \endcond */

@end