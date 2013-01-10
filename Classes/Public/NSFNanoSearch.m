/*
     NSFNanoSearch.m
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

#import "NanoStore.h"
#import "NanoStore_Private.h"
#import "NSFNanoSearch_Private.h"
#import "NSFNanoExpression_Private.h"

@interface NSFNanoSearch ()

/** \cond */
@property (nonatomic, copy, readwrite) NSString *sql;
@property (nonatomic) NSFReturnType returnedObjectType;
/** \endcond */
@end

@implementation NSFNanoSearch

// ----------------------------------------------
// Initialization / Cleanup
// ----------------------------------------------

+ (NSFNanoSearch*)searchWithStore:(NSFNanoStore *)store
{
    return [[self alloc]initWithStore:store];
}

- (id)initWithStore:(NSFNanoStore *)store
{
    if (nil == store) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: store is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    if ((self = [self init])) {
        _nanoStore = store;
        [self reset];
    }
    
    return self;
}

/** \cond */

- (void)dealloc
{
    [self reset];
}

/** \endcond */

#pragma mark -

- (NSString *)sql
{
    if (nil == _sql)
        return [self _preparedSQL];
    
    return _sql;
}

#pragma mark -

- (id)executeSQL:(NSString *)theSQLStatement returnType:(NSFReturnType)theReturnType error:(out NSError **)outError
{
    if (nil == theSQLStatement) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the SQL statement is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    if (0 == [theSQLStatement length]) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the SQL statement is empty.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    // Make sure we don't have any lingering parameters that could mess with the results, but keep the sort descriptor(s)
    NSArray *savedSort = [self sort];
    [self reset];
    self.sort = savedSort;
    
    _returnedObjectType = theReturnType;
    _sql = theSQLStatement;
    
    NSDictionary *results = [self _retrieveDataWithError:outError];
    
    return [self _sortResultsIfApplicable:results returnType:theReturnType];
}

- (NSFNanoResult *)executeSQL:(NSString *)theSQLStatement
{
    if (nil == theSQLStatement) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the SQL statement is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    if (0 == [theSQLStatement length]) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the SQL statement is empty.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    // Make sure we don't have any lingering parameters that could mess with the results...
    [self reset];
    
    _sql = theSQLStatement;
    
    return [_nanoStore _executeSQL:theSQLStatement];
}

- (NSFNanoResult *)explainSQL:(NSString *)theSQLStatement
{
    if (nil == theSQLStatement) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the SQL statement is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    if (0 == [theSQLStatement length]) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: the SQL statement is empty.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    return [_nanoStore _executeSQL:[NSString stringWithFormat:@"EXPLAIN %@", theSQLStatement]];
}

- (void)reset
{
    _attributesToBeReturned = nil;
    _key = nil;
    _attribute = nil;
    _value = nil;
    _match = NSFContains;
    _groupValues = NO;
    _sql = nil;
    _sort = nil;
    _offset = 0;
    _limit = 0;
    _returnedObjectType = NSFReturnObjects;
}

#pragma mark -

- (id)searchObjectsWithReturnType:(NSFReturnType)theReturnType error:(out NSError **)outError
{
    _returnedObjectType = theReturnType;
    
    // Make sure we don't have a SQL statement around...
    _sql = nil;
    
    id results = [self _retrieveDataWithError:outError];
    
    return [self _sortResultsIfApplicable:results returnType:theReturnType];
}

- (id)searchObjectsAdded:(NSFDateMatchType)theDateMatch date:(NSDate *)theDate returnType:(NSFReturnType)theReturnType error:(out NSError **)outError
{
    _returnedObjectType = theReturnType;
    
    // Make sure we don't have a SQL statement around...
    _sql = nil;
    
    id results = [self _retrieveDataAdded:theDateMatch calendarDate:theDate error:outError];
    
    if (NSFReturnKeys == theReturnType) {
        results = [results allKeys];
    }
    
    return results;
}

- (NSNumber *)aggregateOperation:(NSFAggregateFunctionType)theFunctionType onAttribute:(NSString *)theAttribute
{    
    NSFReturnType savedObjectTypeReturned = _returnedObjectType;
    _returnedObjectType = NSFReturnKeys;
    
    NSString *savedSQL = _sql;
    _sql = nil;
    
    NSString *theSearchSQLStatement = [self sql];
    NSMutableString *theAggregatedSQLStatement = [NSMutableString new];
    
    switch (theFunctionType) {
        case NSFAverage:
            [theAggregatedSQLStatement appendString:[NSString stringWithFormat:@"SELECT avg(NSFValue) FROM NSFValues WHERE NSFAttribute = '%@' AND NSFKey IN (%@)", theAttribute, theSearchSQLStatement]];
            break;
        case NSFCount:
            [theAggregatedSQLStatement appendString:[NSString stringWithFormat:@"SELECT count(*) FROM NSFValues WHERE NSFAttribute = '%@' AND NSFKey IN (%@)", theAttribute, theSearchSQLStatement]];
            break;
        case NSFMax:
            [theAggregatedSQLStatement appendString:[NSString stringWithFormat:@"SELECT max(NSFValue) FROM NSFValues WHERE NSFAttribute = '%@' AND NSFKey IN (%@)", theAttribute, theSearchSQLStatement]];
            break;
        case NSFMin:
            [theAggregatedSQLStatement appendString:[NSString stringWithFormat:@"SELECT min(NSFValue) FROM NSFValues WHERE NSFAttribute = '%@' AND NSFKey IN (%@)", theAttribute, theSearchSQLStatement]];
            break;
        case NSFTotal:
            /* Note:
             Sum() will throw an "integer overflow" exception if all inputs are integers or NULL and an integer overflow occurs at any point
             during the computation. Total() never throws an integer overflow.
             */
            [theAggregatedSQLStatement appendString:[NSString stringWithFormat:@"SELECT total(NSFValue) FROM NSFValues WHERE NSFAttribute = '%@' AND NSFKey IN (%@)", theAttribute, theSearchSQLStatement]];
            break;
        default:
            break;
    }
    
    NSFNanoResult *result = [_nanoStore _executeSQL:theAggregatedSQLStatement];

    _returnedObjectType = savedObjectTypeReturned;
    _sql = savedSQL;
    
    return [NSNumber numberWithFloat:[[result firstValue]floatValue]];
}

#pragma mark -
#pragma mark Private Methods
#pragma mark -

/** \cond */

- (NSDictionary *)_retrieveDataWithError:(out NSError **)outError
{
    if (YES == [_nanoStore isClosed]) {
        return nil;
    }
    
    NSMutableDictionary *searchResults = [NSMutableDictionary dictionary];
    
    NSString *aSQLQuery = _sql;

    if (nil != aSQLQuery) {
        // We are going to check whether the user has specified the proper columns based on the search type selected.
        // This is to avoid crashing, since the user shouldn't have to know which columns are involved on each type
        // of search.
        // We basically honor the specified query but replace the columns with the expected ones per returned type.
        
        NSString *subStatement = [aSQLQuery substringFromIndex:[aSQLQuery rangeOfString:@"FROM" options:NSCaseInsensitiveSearch].location];
        NSFReturnType returnType = _returnedObjectType;
        switch (returnType) {
            case NSFReturnKeys:
                aSQLQuery = [NSString stringWithFormat:@"SELECT NSFKey %@", subStatement];
                break;
            case NSFReturnObjects:
                aSQLQuery = [NSString stringWithFormat:@"SELECT NSFKey, NSFKeyedArchive, NSFObjectClass %@", subStatement];
                break;
        }
    } else {
        aSQLQuery = [self _preparedSQL];
    }
    
    _NSFLog(@"_dataWithKey SQL query: %@", aSQLQuery);
    
    sqlite3 *sqliteStore = [[_nanoStore nanoStoreEngine]sqlite];    
    sqlite3_stmt *theSQLiteStatement = NULL;
    
    int status = sqlite3_prepare_v2 (sqliteStore, [aSQLQuery UTF8String], -1, &theSQLiteStatement, NULL );
    
    status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
    
    if (SQLITE_OK == status) {        
        switch (_returnedObjectType) {
            case NSFReturnKeys:
                while (SQLITE_ROW == sqlite3_step (theSQLiteStatement)) {
                    // Sanity check: some queries return NULL, which would cause a crash below.
                    char *valueUTF8 = (char *)sqlite3_column_text (theSQLiteStatement, 0);
                    NSString *theValue = nil;
                    if (NULL != valueUTF8) {
                        theValue = [[NSString alloc]initWithUTF8String:valueUTF8];
                    } else {
                        theValue = [[NSNull null]description];
                    }
                    
                    [searchResults setObject:[NSNull null] forKey:theValue];
                }
                break;
            default:
                while (SQLITE_ROW == sqlite3_step (theSQLiteStatement)) {
                    char *keyUTF8 = (char *)sqlite3_column_text (theSQLiteStatement, 0);
                    NSData *dictBinData = [[NSData alloc] initWithBytes:sqlite3_column_blob(theSQLiteStatement, 1) length: sqlite3_column_bytes(theSQLiteStatement, 1)];
                    char *objectClassUTF8 = (char *)sqlite3_column_text (theSQLiteStatement, 2);
                    
                    // Sanity check: some queries return NULL, which would a crash below.
                    // Since these are values that are NanoStore's resposibility, they should *never* be NULL. Log it for posterity.

                    if ((NULL == keyUTF8) || (dictBinData == nil) || (NULL == objectClassUTF8)) {
                        NSLog(@"*** Warning! These values are NanoStore's resposibility and should *never* be NULL: keyUTF8 (%s) - binArchinve (%@) - objectClassUTF8 (%s)", keyUTF8, [dictBinData debugDescription], objectClassUTF8);
                        continue;
                    }
                    NSDictionary *info = [NSKeyedUnarchiver unarchiveObjectWithData:dictBinData];
                    NSString *keyValue = [[NSString alloc]initWithUTF8String:keyUTF8];
                    NSString *objectClass = [[NSString alloc]initWithUTF8String:objectClassUTF8];
                    
                    if (nil == info) {
                        continue;
                    }
                    
                    if ([_attributesToBeReturned count] == 0) {
                        // Will be released below...
                    } else {
                        // Since we want a subset of the attributes, we need to traverse
                        // the attribute list and find out whether the dictionary contains
                        // the specified attributes. If so, add them to a subset which will
                        // be returned as requested.
                        
                        NSMutableDictionary *subset = [NSMutableDictionary new];
                        
                        for (NSString *attributeValue in _attributesToBeReturned) {
                            id theValue = [info valueForKeyPath:attributeValue];
                            if (nil != theValue) {
                                if (NSNotFound == [attributeValue rangeOfString:@"."].location) {
                                    [subset setValue:theValue forKeyPath:attributeValue];
                                } else {
                                    NSDictionary *subInfo = [self _dictionaryForKeyPath:attributeValue value:theValue];
                                    if ([subInfo count] > 0) {
                                        NSString *subInfoKey = [[subInfo allKeys]objectAtIndex:0];
                                        NSString *subInfoValue = [subInfo objectForKey:subInfoKey];
                                        [subset setValue:subInfoValue forKey:subInfoKey];
                                    }
                                }
                            }
                        }
                        
                        // Will be released below...
                        info = subset;
                    }
                    
                    Class storedObjectClass = NSClassFromString(objectClass);
                    BOOL saveOriginalClassReference = NO;
                    if (nil == storedObjectClass) {
                        storedObjectClass = [NSFNanoObject class];
                        saveOriginalClassReference = YES;
                    }
                    
                    id nanoObject = [[storedObjectClass alloc]initNanoObjectFromDictionaryRepresentation:info forKey:keyValue store:_nanoStore];
                    
                    // If this process does not have knowledge of the original class as was saved in the store, keep a reference
                    // so that we can later on restore the object properly (otherwise it would be stored as a NanoObject.)
                    if (YES == saveOriginalClassReference) {
                        [nanoObject _setOriginalClassString:objectClass];
                    }
                    
                    [searchResults setObject:nanoObject forKey:keyValue];
                    
                }
                break;
        }
        
        sqlite3_finalize (theSQLiteStatement);
        
    } else {
        if (nil != outError) {
            NSString *msg = [NSString stringWithFormat:@"SQLite error ID: %d", status];
            *outError = [NSError errorWithDomain:NSFDomainKey
                                            code:NSFNanoStoreErrorKey
                                        userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: %@", [self class], NSStringFromSelector(_cmd), msg]
                                                                             forKey:NSLocalizedFailureReasonErrorKey]];
        }
        searchResults = nil;
    }
        
    return searchResults;
}

- (NSDictionary *)_retrieveDataAdded:(NSFDateMatchType)aDateMatch calendarDate:(NSDate *)aDate error:(out NSError **)outError
{
    if ([_nanoStore isClosed] == YES) {
        return nil;
    }
    
    NSString *theSQLStatement = nil;
    NSString *normalizedDateString = [NSFNanoStore _calendarDateToString:aDate];
    
    switch (aDateMatch) {
        case NSFBeforeDate:
            if (self.filterClass.length > 0) {
                theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT %@, %@, %@ FROM %@ WHERE (NSFObjectClass = '%@') AND %@ < '%@'", NSFKey, NSFKeyedArchive, NSFObjectClass, NSFKeys, self.filterClass, NSFCalendarDate, normalizedDateString];
            } else {
                theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT %@, %@, %@ FROM %@ WHERE %@ < '%@'", NSFKey, NSFKeyedArchive, NSFObjectClass, NSFKeys, NSFCalendarDate, normalizedDateString];
            }
            break;
        case NSFOnDate:
            if (self.filterClass.length > 0) {
                theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT %@, %@, %@ FROM %@ WHERE (NSFObjectClass = '%@') AND %@ = '%@'", NSFKey, NSFKeyedArchive, NSFObjectClass, NSFKeys, self.filterClass, NSFCalendarDate, normalizedDateString];
            } else {
                theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT %@, %@, %@ FROM %@ WHERE %@ = '%@'", NSFKey, NSFKeyedArchive, NSFObjectClass, NSFKeys, NSFCalendarDate, normalizedDateString];
            }
            break;
        case NSFAfterDate:
            if (self.filterClass.length > 0) {
                theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT %@, %@, %@ FROM %@ WHERE (NSFObjectClass = '%@') AND %@ > '%@'", NSFKey, NSFKeyedArchive, NSFObjectClass, NSFKeys, self.filterClass, NSFCalendarDate, normalizedDateString];
            } else {
                theSQLStatement = [[NSString alloc]initWithFormat:@"SELECT %@, %@, %@ FROM %@ WHERE %@ > '%@'", NSFKey, NSFKeyedArchive, NSFObjectClass, NSFKeys, NSFCalendarDate, normalizedDateString];
            }
            break;
    }
    
    NSFNanoResult *result = [_nanoStore _executeSQL:theSQLStatement];
    
    NSMutableDictionary *searchResults = [NSMutableDictionary dictionaryWithCapacity:result.numberOfRows];
    
    if (result.numberOfRows > 0) {
        if (NSFReturnKeys == _returnedObjectType) {
            NSArray *resultsKeys = [result valuesForColumn:[NSString stringWithFormat:@"%@.%@", NSFKeys, NSFKey]];
            for (NSString *resultKey in resultsKeys)
                [searchResults setObject:[NSNull null] forKey:resultKey];
            return searchResults;
        } else {
                NSArray *resultsObjectClass = [result valuesForColumn:[NSString stringWithFormat:@"%@.%@", NSFKeys, NSFObjectClass]];
                NSArray *resultsObjects = [result valuesForColumn:[NSString stringWithFormat:@"%@.%@", NSFKeys, NSFKeyedArchive]];
                NSArray *resultsKeys = [result valuesForColumn:[NSString stringWithFormat:@"%@.%@", NSFKeys, NSFKey]];
                NSUInteger i, count = [resultsKeys count];
                
            for (i = 0; i < count; i++) {
                @autoreleasepool {
                    NSDictionary *info = [NSKeyedUnarchiver unarchiveObjectWithData:[resultsObjects objectAtIndex:i]];
                    if (nil != info) {
                        NSString *keyValue = [resultsKeys objectAtIndex:i];
                        
                        NSString *className = [resultsObjectClass objectAtIndex:i];
                        Class storedObjectClass = NSClassFromString(className);
                        BOOL saveOriginalClassReference = NO;
                        if (nil == storedObjectClass) {
                            storedObjectClass = [NSFNanoObject class];
                            saveOriginalClassReference = YES;
                        }
                        
                        id nanoObject = [[storedObjectClass alloc]initNanoObjectFromDictionaryRepresentation:info forKey:keyValue store:_nanoStore];
                        
                        // If this process does not have knowledge of the original class as was saved in the store, keep a reference
                        // so that we can later on restore the object properly (otherwise it would be stored as a NanoObject.)
                        if (YES == saveOriginalClassReference) {
                            [nanoObject _setOriginalClassString:className];
                        }
                        
                        [searchResults setObject:nanoObject forKey:keyValue];
                    }
                }
            }
        }
    }
    
    return searchResults;
}

- (NSString *)_preparedSQL
{
    NSString *aSQLQuery = nil;
    
    if (nil == _expressions) {
        aSQLQuery = [self _prepareSQLQueryStringWithKey:_key attribute:_attribute value:_value matching:_match];
    } else {
        aSQLQuery = [self _prepareSQLQueryStringWithExpressions:_expressions];
    }
    
    // Add the limit clause if required
    if (_limit > 0) {
        aSQLQuery = [NSString stringWithFormat:@"%@ LIMIT %li", aSQLQuery, _limit];
    }
    
    // Add the offset clause if required
    if (_offset > 0) {
        aSQLQuery = [NSString stringWithFormat:@"%@ OFFSET %li", aSQLQuery, _offset];
    }
    
    return aSQLQuery;
}

- (NSString *)_prepareSQLQueryStringWithKey:(NSString *)aKey attribute:(NSString *)anAttribute value:(id)aValue matching:(NSFMatchType)aMatch
{    
    NSMutableString *theSQLStatement = nil;
    NSString *attributes = nil;
    
    // Make sure we escape quotes if present and the value is a string
    if (YES == [aValue isKindOfClass:[NSString class]]) {
        aValue = [aValue stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    }
    
    if (nil != _attributesToBeReturned) {
        // Prepare the list of attributes we need to gather. Include NSFKEY as well.
        NSMutableSet *set = [[NSMutableSet alloc]initWithArray:_attributesToBeReturned];
        NSArray *objects = [set allObjects];
        NSMutableArray *quotedObjects = [NSMutableArray new];
        for (NSString *object in objects) {
            NSString *theValue = [[NSString alloc]initWithFormat:@"'%@'", object];
            [quotedObjects addObject:theValue];
        }
        attributes = [quotedObjects componentsJoinedByString:@","];
    }
    
    NSFReturnType returnType = _returnedObjectType;
    
    if ((nil == aKey) && (nil == anAttribute) && (nil == aValue)) {
        switch (returnType) {
            case NSFReturnKeys:
                return @"SELECT NSFKEY FROM NSFKeys";
                break;
            default:
                return @"SELECT NSFKey, NSFKeyedArchive, NSFObjectClass FROM NSFKeys";
                break;
        }
    } else {
        switch (returnType) {
            case NSFReturnKeys:
                if (NO == _groupValues) {
                    theSQLStatement = [NSMutableString stringWithString:@"SELECT DISTINCT (NSFKEY) FROM NSFValues WHERE "];
                } else {
                    theSQLStatement = [NSMutableString stringWithString:@"SELECT NSFKEY FROM NSFValues WHERE "];
                }
                break;
            default:
                theSQLStatement = [NSMutableString stringWithString:@"SELECT NSFKEY FROM NSFValues WHERE "];
                break;
        }
    }
    
    NSString *segment = nil;
    BOOL querySegmentWasAdded = NO;
    
    if (nil != aKey) {
        if ((nil == anAttribute) && (nil == aValue))
            segment = [NSFNanoSearch _querySegmentForColumn:NSFKey value:aKey matching:aMatch];
        else
            segment = [NSFNanoSearch _querySegmentForColumn:NSFKey value:aKey matching:NSFEqualTo];
        [theSQLStatement appendString:segment];
        querySegmentWasAdded = YES;
    }
    
    if (nil != anAttribute) {
        if (YES == querySegmentWasAdded) {
            [theSQLStatement appendString:@" AND "];
        }
        
        // We need to introspect whether the attribute contains a dot "." or not. Based on the case, we'll need to GLOB the attribute
        // or leave it as is.
        
        if (NSNotFound == [anAttribute rangeOfString:@"."].location) {
            segment = [NSFNanoSearch _querySegmentForAttributeColumnWithValue:anAttribute matching:aMatch valueColumnWithValue:aValue];
        } else {
            if (nil == aValue) {
                segment = [NSFNanoSearch _querySegmentForColumn:NSFAttribute value:anAttribute matching:aMatch];
            } else {
                segment = [NSFNanoSearch _querySegmentForColumn:NSFAttribute value:anAttribute matching:NSFEqualTo];
                [theSQLStatement appendString:segment];
                [theSQLStatement appendString:@" AND "];
                segment = [NSFNanoSearch _querySegmentForColumn:NSFValue value:aValue matching:aMatch];
            }
        }
        
        [theSQLStatement appendString:segment];
        if (self.bag != nil) {
            NSString *selectInABag = [NSString stringWithFormat:@" AND NSFKey IN (SELECT NSFValue FROM NSFVALUES WHERE NSFKey == '%@' AND NSFAttribute == '%@')",self.bag.key,NSF_Private_NSFNanoBag_NSFObjectKeys];
            [theSQLStatement appendString:selectInABag];
        }
    } else {
        if (nil != aValue) {
            if (YES == querySegmentWasAdded)
                [theSQLStatement appendString:@" AND "];
            segment = [NSFNanoSearch _querySegmentForColumn:NSFValue value:aValue matching:aMatch];
            [theSQLStatement appendString:segment];
        }
    }
    
    if ((_limit > 0) || (_offset > 0)) {
        [theSQLStatement appendString:@" ORDER BY ROWID"];
    }
    
    if (YES == _groupValues) {
        [theSQLStatement appendString:@" GROUP BY NSFValue"];
    }
    
    if (NSFReturnObjects == returnType) {
        if (self.filterClass.length > 0) {
            theSQLStatement = [NSString stringWithFormat:@"SELECT DISTINCT (NSFKey),NSFKeyedArchive,NSFObjectClass FROM NSFKeys WHERE (NSFObjectClass = '%@') AND NSFKey IN (%@)", self.filterClass, theSQLStatement];
        } else {
            theSQLStatement = [NSString stringWithFormat:@"SELECT DISTINCT (NSFKey),NSFKeyedArchive,NSFObjectClass FROM NSFKeys WHERE NSFKey IN (%@)", theSQLStatement];
        }
    } else {
        if (self.filterClass.length > 0) {
            theSQLStatement = [NSString stringWithFormat:@"SELECT (NSFKEY) FROM NSFKeys WHERE (NSFObjectClass = '%@') AND NSFKEY IN (%@)", self.filterClass, theSQLStatement];
        }
    }
    
    return theSQLStatement;
}

- (NSString *)_prepareSQLQueryStringWithExpressions:(NSArray *)someExpressions
{
    NSUInteger i, count = [someExpressions count];
    NSMutableArray *sqlComponents = [NSMutableArray new];
    NSMutableString *parentheses = [NSMutableString new];
    NSFReturnType returnType = _returnedObjectType;

    if (count == 0) {
        if (NSFReturnObjects == returnType) {
            [sqlComponents addObject:@"SELECT NSFKEY FROM NSFValues"];
        } else {
            [sqlComponents addObject:@"SELECT DISTINCT (NSFKEY) FROM NSFValues"];
        }
    } else {
        for (i = 0; i < count; i++) {
            NSFNanoExpression *expression = [someExpressions objectAtIndex:i];
            NSMutableString *theSQL = nil;;
            
            if (NSFReturnObjects == returnType) {
                theSQL = [[NSMutableString alloc]initWithFormat:@"SELECT NSFKEY FROM NSFValues WHERE %@", [expression description]];
            } else {
                theSQL = [[NSMutableString alloc]initWithFormat:@"SELECT DISTINCT (NSFKEY) FROM NSFValues WHERE %@", [expression description]];
            }
            
            if ((count > 1) && (i < count-1)) {
                [theSQL appendString:@" AND NSFKEY IN ("];
                [parentheses appendString:@")"];
            }
            
            [sqlComponents addObject:theSQL];
        }
    }
    
    if ([parentheses length] > 0)
        [sqlComponents addObject:parentheses];
    
    NSString *theValue = [sqlComponents componentsJoinedByString:@""];
    
    if (NSFReturnObjects == returnType) {
        if (self.filterClass.length > 0) {
            theValue = [NSString stringWithFormat:@"SELECT DISTINCT (NSFKey),NSFKeyedArchive,NSFObjectClass FROM NSFKeys WHERE (NSFObjectClass = '%@') AND NSFKey IN (%@)", self.filterClass, theValue];
        } else {
            theValue = [NSString stringWithFormat:@"SELECT DISTINCT (NSFKey),NSFKeyedArchive,NSFObjectClass FROM NSFKeys WHERE NSFKey IN (%@)", theValue];
        }
    } else {
        if (self.filterClass.length > 0) {
            theValue = [NSString stringWithFormat:@"SELECT DISTINCT (NSFKey) FROM NSFKeys WHERE (NSFObjectClass = '%@') AND NSFKey IN (%@)", self.filterClass, theValue];
        }
    }
    
    return theValue;
}

+ (NSString *)_prepareSQLQueryStringWithKeys:(NSArray *)someKeys
{
    //Prepare the keys by single quoting them...
    NSMutableArray *preparedKeys = [NSMutableArray new];
    for (NSString *theKey in someKeys) {
        NSString *quotedKey = [[NSString alloc]initWithFormat:@"'%@'", theKey];
        [preparedKeys addObject:quotedKey];
    }
    
    NSMutableString *theSQLStatement = [NSMutableString stringWithString:@"SELECT DISTINCT (NSFKEY) FROM NSFValues WHERE NSFKey IN ("];
    [theSQLStatement appendString:[preparedKeys componentsJoinedByString:@","]];
    [theSQLStatement appendString:@")"];
    
    theSQLStatement = [NSString stringWithFormat:@"SELECT DISTINCT (NSFKey),NSFKeyedArchive,NSFObjectClass FROM NSFKeys WHERE NSFKey IN (%@)", theSQLStatement];
    
    return theSQLStatement;
}

+ (NSString *)_querySegmentForColumn:(NSString *)aColumn value:(id)aValue matching:(NSFMatchType)match
{
    NSMutableString *segment = [NSMutableString string];
    NSMutableString *value = nil;
    NSMutableString *mutatedString = nil;
    NSInteger mutatedStringLength = 0;
    unichar sentinelChar;
    
    if (YES == [aValue isKindOfClass:[NSString class]]) {
        switch (match) {
            case NSFEqualTo:
                value = [[NSMutableString alloc]initWithFormat:@"%@ = '%@'", aColumn, aValue];
                [segment appendString:value];
                break;
            case NSFBeginsWith:
                sentinelChar = [aValue characterAtIndex:[aValue length] - 1] + 1;
                value = [[NSMutableString alloc]initWithFormat:@"(%@ >= '%@' AND %@ < '%@%c')", aColumn, aValue, aColumn, aValue, sentinelChar];
                [segment appendString:value];
                break;
            case NSFContains:
                value = [[NSMutableString alloc]initWithFormat:@"%@ GLOB '*%@*'", aColumn, aValue];
                [segment appendString:value];
                break;
            case NSFEndsWith:
                value = [[NSMutableString alloc]initWithFormat:@"%@ GLOB '*%@'", aColumn, aValue];
                [segment appendString:value];
                break;
            case NSFInsensitiveEqualTo:
                value = [[NSMutableString alloc]initWithFormat:@"upper(%@) = '%@'", aColumn, [aValue uppercaseString]];
                [segment appendString:value];
                break;
            case NSFInsensitiveBeginsWith:
                mutatedString = [[NSMutableString alloc]initWithString:aValue];
                mutatedStringLength = [aValue length];
                value = [[NSMutableString alloc]initWithFormat:@"%c", [mutatedString characterAtIndex:mutatedStringLength - 1]+1];
                [mutatedString replaceCharactersInRange:NSMakeRange(mutatedStringLength - 1, 1) withString:value];
                value = [[NSMutableString alloc]initWithFormat:@"(upper(%@) >= '%@' AND upper(%@) < '%@')", aColumn, [aValue uppercaseString], aColumn, [mutatedString uppercaseString]];
                [segment appendString:value];
                break;
            case NSFInsensitiveContains:
                value = [[NSMutableString alloc]initWithFormat:@"%@ LIKE '%@%@%@'", aColumn, @"%", aValue, @"%"];
                [segment appendString:value];
                break;
            case NSFInsensitiveEndsWith:
                value = [[NSMutableString alloc]initWithFormat:@"%@ LIKE '%@%@'", aColumn, @"%", aValue];
                [segment appendString:value];
                break;
            case NSFGreaterThan:
                value = [[NSMutableString alloc]initWithFormat:@"%@ > '%@'", aColumn, aValue];
                [segment appendString:value];
                break;
            case NSFLessThan:
                value = [[NSMutableString alloc]initWithFormat:@"%@ < '%@'", aColumn, aValue];
                [segment appendString:value];
                break;
            case NSFNotEqualTo:
                value = [[NSMutableString alloc]initWithFormat:@"%@ <> '%@'", aColumn, aValue];
                [segment appendString:value];
                break;
        }
    } else if (YES == [aValue isKindOfClass:[NSArray class]]) {
        // Quote the parameters
        NSMutableArray *quotedParameters = [[NSMutableArray alloc]initWithCapacity:[aValue count]];
        value = [[NSMutableString alloc]initWithFormat:@"%@ IN (", aColumn];
        for (NSString *parameter in aValue) {
            NSString *quotedParameter = [[NSString alloc]initWithFormat:@"'%@'", parameter];
            [quotedParameters addObject:quotedParameter];
        }
        //Add them to the string delimited by string
        [value appendString:[quotedParameters componentsJoinedByString:@","]];
        [value appendString:@")"];
        
        // Complete the query segment
        [segment appendString:value];
        
        // Free allocated resources
    } else if (YES == [aValue isKindOfClass:[NSNull class]]){
        switch (match) {
            case NSFEqualTo:
                value = [[NSMutableString alloc]initWithFormat:@"%@ IS NULL", aColumn];
                [segment appendString:value];
                break;
            case NSFNotEqualTo:
                value = [[NSMutableString alloc]initWithFormat:@"%@ IS NOT NULL", aColumn];
                [segment appendString:value];
                break;
            default:
                break;
        }
    }
    
    return segment;
}

+ (NSString *)_querySegmentForAttributeColumnWithValue:(id)anAttributeValue matching:(NSFMatchType)match valueColumnWithValue:(id)aValue
{
    NSMutableString *segment = [NSMutableString string];
    NSMutableString *value = nil;

    if ((YES == [aValue isKindOfClass:[NSString class]]) || (nil == aValue)) {
        if (nil == aValue) {
            value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@') OR (%@ GLOB '%@.*') OR (%@ GLOB '*.%@.*') OR (%@ GLOB '*.%@'))", NSFAttribute, anAttributeValue, NSFAttribute, anAttributeValue, NSFAttribute, anAttributeValue, NSFAttribute, anAttributeValue];
            [segment appendString:value];
        } else {
            switch (match) {
                case NSFEqualTo:
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND %@ = '%@') OR (%@ GLOB '%@.*' AND %@ = '%@') OR (%@ GLOB '*.%@.*' AND %@ = '%@') OR (%@ GLOB '*.%@' AND %@ = '%@'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFBeginsWith:
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND %@ GLOB '%@*') OR (%@ GLOB '%@.*' AND %@ GLOB '%@*') OR (%@ GLOB '*.%@.*' AND %@ GLOB '%@*') OR (%@ GLOB '*.%@' AND %@ GLOB '%@*'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFContains:
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND %@ GLOB '%@') OR (%@ GLOB '%@.*' AND %@ GLOB '%@') OR (%@ GLOB '*.%@.*' AND %@ GLOB '%@') OR (%@ GLOB '*.%@' AND %@ GLOB '%@'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFEndsWith:
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND %@ GLOB '*%@') OR (%@ GLOB '%@.*' AND %@ GLOB '*%@') OR (%@ GLOB '*.%@.*' AND %@ GLOB '*%@') OR (%@ GLOB '*.%@' AND %@ GLOB '*%@'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFInsensitiveEqualTo:
                    aValue = [aValue uppercaseString];
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND upper(%@) = '%@') OR (%@ GLOB '%@.*' AND upper(%@) = '%@') OR (%@ GLOB '*.%@.*' AND upper(%@) = '%@') OR (%@ GLOB '*.%@' AND upper(%@) = '%@'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFInsensitiveBeginsWith:
                    aValue = [aValue uppercaseString];
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND upper(%@) GLOB '%@*') OR (%@ GLOB '%@.*' AND upper(%@) GLOB '%@*') OR (%@ GLOB '*.%@.*' AND upper(%@) GLOB '%@*') OR (%@ GLOB '*.%@' AND upper(%@) GLOB '%@*'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFInsensitiveContains:
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND %@ LIKE '%@') OR (%@ GLOB '%@.*' AND %@ LIKE '%@') OR (%@ GLOB '*.%@.*' AND %@ LIKE '%@') OR (%@ GLOB '*.%@' AND %@ LIKE '%@'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFInsensitiveEndsWith:
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND %@ LIKE '%%%@') OR (%@ GLOB '%@.*' AND %@ LIKE '%%%@') OR (%@ GLOB '*.%@.*' AND %@ LIKE '%%%@') OR (%@ GLOB '*.%@' AND %@ LIKE '%%%@'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFGreaterThan:
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND %@ > '%@') OR (%@ GLOB '%@.*' AND %@ > '%@') OR (%@ GLOB '*.%@.*' AND %@ > '%@') OR (%@ GLOB '*.%@' AND %@ > '%@'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFLessThan:
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ = '%@' AND %@ < '%@') OR (%@ GLOB '%@.*' AND %@ < '%@') OR (%@ GLOB '*.%@.*' AND %@ < '%@') OR (%@ GLOB '*.%@' AND %@ < '%@'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];
                    break;
                case NSFNotEqualTo:
                    value = [[NSMutableString alloc]initWithFormat:@"((%@ <> '%@' AND %@ <> '%@') OR (%@ GLOB '%@.*' AND %@ <> '%@') OR (%@ GLOB '*.%@.*' AND %@ <> '%@') OR (%@ GLOB '*.%@' AND %@ <> '%@'))", NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue, NSFAttribute, anAttributeValue, NSFValue, aValue];
                    [segment appendString:value];

                    break;
            }
        }
    } else if (YES == [aValue isKindOfClass:[NSArray class]]) {
        // Quote the parameters
        NSMutableArray *quotedParameters = [[NSMutableArray alloc]initWithCapacity:[aValue count]];
        value = [[NSMutableString alloc]initWithFormat:@"%@ IN (", NSFAttribute];
        for (NSString *parameter in aValue) {
            NSString *quotedParameter = [[NSString alloc]initWithFormat:@"'%@'", parameter];
            [quotedParameters addObject:quotedParameter];
        }
        //Add them to the string delimited by string
        [value appendString:[quotedParameters componentsJoinedByString:@","]];
        [value appendString:@")"];
        
        // Complete the query segment
        [segment appendString:value];
        
        // Free allocated resources
    } else if (YES == [aValue isKindOfClass:[NSNull class]]) {
        NSString *NULLStringValue = NSFStringFromNanoDataType (NSFNanoTypeNULL);
        switch (match) {
            case NSFEqualTo:
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND %@ = '%@') OR (%@ GLOB '%@.*' AND %@ = '%@') OR (%@ GLOB '*.%@.*' AND %@ = '%@') OR (%@ GLOB '*.%@' AND %@ = '%@')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFNotEqualTo:
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND %@ <> '%@') OR (%@ GLOB '%@.*' AND %@ <> '%@') OR (%@ GLOB '*.%@.*' AND %@ <> '%@') OR (%@ GLOB '*.%@' AND %@ <> '%@')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFBeginsWith:
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND %@ GLOB '%@*') OR (%@ GLOB '%@.*' AND %@ GLOB '%@*') OR (%@ GLOB '*.%@.*' AND %@ GLOB '%@*') OR (%@ GLOB '*.%@' AND %@ GLOB '%@*')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFContains:
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND %@ GLOB '%@') OR (%@ GLOB '%@.*' AND %@ GLOB '%@') OR (%@ GLOB '*.%@.*' AND %@ GLOB '%@') OR (%@ GLOB '*.%@' AND %@ GLOB '%@')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFEndsWith:
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND %@ GLOB '*%@') OR (%@ GLOB '%@.*' AND %@ GLOB '*%@') OR (%@ GLOB '*.%@.*' AND %@ GLOB '*%@') OR (%@ GLOB '*.%@' AND %@ GLOB '*%@')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFInsensitiveEqualTo:
                aValue = [aValue uppercaseString];
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND upper(%@) = '%@') OR (%@ GLOB '%@.*' AND upper(%@) = '%@') OR (%@ GLOB '*.%@.*' AND upper(%@) = '%@') OR (%@ GLOB '*.%@' AND upper(%@) = '%@')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFInsensitiveBeginsWith:
                aValue = [aValue uppercaseString];
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND upper(%@) GLOB '%@*') OR (%@ GLOB '%@.*' AND upper(%@) GLOB '%@*') OR (%@ GLOB '*.%@.*' AND upper(%@) GLOB '%@*') OR (%@ GLOB '*.%@' AND upper(%@) GLOB '%@*')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFInsensitiveContains:
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND %@ LIKE '%@') OR (%@ GLOB '%@.*' AND %@ LIKE '%@') OR (%@ GLOB '*.%@.*' AND %@ LIKE '%@') OR (%@ GLOB '*.%@' AND %@ LIKE '%@')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFInsensitiveEndsWith:
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND %@ LIKE '%%%@') OR (%@ GLOB '%@.*' AND %@ LIKE '%%%@') OR (%@ GLOB '*.%@.*' AND %@ LIKE '%%%@') OR (%@ GLOB '*.%@' AND %@ LIKE '%%%@')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFGreaterThan:
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND %@ > '%@') OR (%@ GLOB '%@.*' AND %@ > '%@') OR (%@ GLOB '*.%@.*' AND %@ > '%@') OR (%@ GLOB '*.%@' AND %@ > '%@')", NSFAttribute, NSFDatatype, NULLStringValue, aValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
            case NSFLessThan:
                value = [[NSMutableString alloc]initWithFormat:@"(%@ = '%@' AND %@ < '%@') OR (%@ GLOB '%@.*' AND %@ < '%@') OR (%@ GLOB '*.%@.*' AND %@ < '%@') OR (%@ GLOB '*.%@' AND %@ < '%@')", NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue, NSFAttribute, anAttributeValue, NSFDatatype, NULLStringValue];
                [segment appendString:value];
                break;
        }
    }
    
    return segment;
}

- (NSDictionary *)_dictionaryForKeyPath:(NSString *)keyPath value:(id)theValue
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSMutableArray *keys = [[keyPath componentsSeparatedByString:@"."]mutableCopy];
    
    if ([keys count] == 1) {
        [info setObject:theValue forKey:keyPath];
        return info;
    }
    
    NSInteger i;

    for (i = 0; i < [keys count]; i++) {
        NSString *keyValue = [keys objectAtIndex:i];
        [keys removeObjectAtIndex:0];
        NSDictionary *subInfo = [self _dictionaryForKeyPath:[keys componentsJoinedByString:@"."] value:theValue];
        if (nil != subInfo)
            [info setObject:subInfo forKey:keyValue];
    }
    
    return info;
}

+ (NSString *)_quoteStrings:(NSArray *)strings joiningWithDelimiter:(NSString *)delimiter
{
    NSMutableArray *quotedParameters = [[NSMutableArray alloc]initWithCapacity:[strings count]];
    for (NSString *string in strings) {
        NSString *quotedParameter = [[NSString alloc]initWithFormat:@"\"%@\"", string];
        [quotedParameters addObject:quotedParameter];
    }
    
    NSString *quotedString = [quotedParameters componentsJoinedByString:@","];
    
    
    return quotedString;
}

- (id)_sortResultsIfApplicable:(NSDictionary *)results returnType:(NSFReturnType)theReturnType
{
    id theResults = results;
    
    if ([_sort count] > 0) {
        if (NSFReturnObjects == theReturnType) {
            NSMutableArray *cocoaSortDescriptors = [NSMutableArray new];
            
            for (NSFNanoSortDescriptor *descriptor in _sort) {
                NSString *targetKeyPath = [[NSString alloc]initWithFormat:@"rootObject.%@", descriptor.attribute];
                NSSortDescriptor *cocoaSort = [[NSSortDescriptor alloc]initWithKey:targetKeyPath ascending:descriptor.isAscending];
                [cocoaSortDescriptors addObject:cocoaSort];
            }
            theResults = [[results allValues]sortedArrayUsingDescriptors:cocoaSortDescriptors];
        } else {
            theResults = [results allKeys];
        }
    } else if (NSFReturnKeys == theReturnType) {
        theResults = [results allKeys];
    }
    
    return theResults;
}

- (NSString *)description
{
    return [self JSONDescription];
}

- (NSFOrderedDictionary *)dictionaryDescription
{
    NSFOrderedDictionary *values = [NSFOrderedDictionary new];
    
    values[@"NanoSearch address"] = [NSString stringWithFormat:@"%p", self];
    values[@"Document store"] = [_nanoStore dictionaryDescription];
    values[@"Attributes to be returned"] = (_attributesToBeReturned ? [_attributesToBeReturned componentsJoinedByString:@","] : @"All");
    values[@"Key"] = (_key ? _key : @"<nil>");
    values[@"Attribute"] = (_attribute ? _attribute : @"<nil>");
    values[@"Value"] = (_value ? _value : @"<nil>");
    values[@"Match"] = NSFStringFromMatchType(_match);
    
    NSMutableArray *tempExpressions = [NSMutableArray new];
    for (NSFNanoExpression *expression in _expressions) {
        [tempExpressions addObject:[expression description]];
    }
    values[@"Expressions"] = ([tempExpressions count] > 0 ? tempExpressions : @"<nil>");
    
    values[@"Group values?"] = (_groupValues ? @"YES" : @"NO");
    
    NSString *tempSQL = [self sql];
    values[@"SQL"] = (tempSQL ? tempSQL : @"<nil>");
    values[@"Sort"] = (_sort ? _sort : @"<nil>");
    values[@"Filter class"] = (_filterClass ? _filterClass : @"<nil>");
    values[@"Offset"] = @(_offset);
    values[@"Limit"] = @(_limit);
    
    return values;
}

- (NSString *)JSONDescription
{
    NSFOrderedDictionary *values = [self dictionaryDescription];
    
    NSError *outError = nil;
    NSString *description = [NSFNanoObject _NSObjectToJSONString:values error:&outError];
    
    return description;
}

/** \endcond */

@end