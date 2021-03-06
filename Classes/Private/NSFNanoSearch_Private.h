/*
     NSFNanoSearch_Private.h
     NanoStore
     
     Copyright (c) 2013 Webbo, Inc. All rights reserved.
     
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

/** \cond */

@interface NSFNanoSearch (Private)
- (nullable NSDictionary *)_retrieveDataWithError:(NSError * _Nullable * _Nullable)outError;
- (nullable NSDictionary *)_retrieveDataAdded:(NSFDateMatchType)aDateMatch calendarDate:(nonnull NSDate *)aDate error:(NSError * _Nullable * _Nullable)outError;
@property (nonatomic, readonly, copy, nonnull) NSString *_preparedSQL;
- (nonnull NSString *)_prepareSQLQueryStringWithKey:(nullable NSString *)aKey attribute:(nullable NSString *)anAttribute value:(nullable id)aValue matching:(NSFMatchType)match;
- (nonnull NSString *)_prepareSQLQueryStringWithExpressions:(nonnull NSArray *)someExpressions;
- (nonnull NSArray *)_resultsFromSQLQuery:(nonnull NSString *)theSQLStatement;
+ (nonnull NSString *)_prepareSQLQueryStringWithKeys:(nonnull NSArray *)someKeys;
+ (nonnull NSString *)_querySegmentForColumn:(nonnull NSString *)aColumn value:(nonnull id)aValue matching:(NSFMatchType)match;
+ (nonnull NSString *)_querySegmentForAttributeColumnWithValue:(nonnull id)anAttributeValue matching:(NSFMatchType)match valueColumnWithValue:(nullable id)aValue;
- (nonnull NSDictionary *)_dictionaryForKeyPath:(nonnull NSString *)keyPath value:(nonnull id)value;
+ (nonnull NSString *)_quoteStrings:(nonnull NSArray *)strings joiningWithDelimiter:(nonnull NSString *)delimiter;
- (nonnull id)_sortResultsIfApplicable:(nonnull NSDictionary *)results returnType:(NSFReturnType)theReturnType;
@end

/** \endcond */
