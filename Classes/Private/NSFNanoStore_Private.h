/*
     NSFNanoStore_Private.h
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

#import "NSFNanoStore.h"
#import "NSFOrderedDictionary.h"

/** \cond */

@interface NSFNanoStore (Private)
- (nonnull NSFOrderedDictionary *)dictionaryDescription;
+ (nonnull NSFNanoStore *)_createAndOpenDebugDatabase;
- (nonnull NSFNanoResult *)_executeSQL:(nonnull NSString *)theSQLStatement;
- (nonnull NSString *)_nestedDescriptionWithPrefixedSpace:(nonnull NSString *)prefixedSpace;
- (BOOL)_initializePreparedStatementsWithError:(NSError * _Nullable * _Nullable)outError;
- (void)_releasePreparedStatements;
- (void)_setIsOurTransaction:(BOOL)value;
@property (nonatomic, readonly) BOOL _isOurTransaction;
@property (nonatomic, readonly) BOOL _setupCachingSchema;
- (BOOL)_storeDictionary:(nonnull NSDictionary *)someInfo forKey:(nonnull NSString *)aKey forClassNamed:(nonnull NSString *)classType error:(NSError * _Nullable * _Nullable)outError;
- (BOOL)__storeDictionaries:(nonnull NSArray *)someObjects forKeys:(nonnull NSArray *)someKeys error:(NSError * _Nullable * _Nullable)outError;
- (BOOL)_bindValue:(nonnull id)aValue forAttribute:(nonnull NSString *)anAttribute parameterNumber:(NSInteger)aParamNumber usingSQLite3Statement:(sqlite3_stmt * _Nonnull)aStatement;
- (BOOL)_checkNanoStoreIsReadyAndReturnError:(NSError * _Nullable * _Nullable)outError;
- (NSFNanoDatatype)_NSFDatatypeOfObject:(nonnull id)value;
- (nonnull NSString *)_stringFromValue:(nonnull id)aValue;
+ (nonnull NSString *)_calendarDateToString:(nonnull NSDate *)aDate;
- (void)_flattenCollection:(nonnull NSDictionary *)info keys:(NSMutableArray * _Nullable * _Nullable)flattenedKeys values:(NSMutableArray * _Nullable * _Nullable)flattenedValues;
- (void)_flattenCollection:(nonnull id)someObject keyPath:(NSMutableArray * _Nullable * _Nullable)aKeyPath keys:(NSMutableArray * _Nullable * _Nullable)someKeys values:(NSMutableArray * _Nullable * _Nullable)someValues;
- (BOOL)_prepareSQLite3Statement:(sqlite3_stmt * _Nonnull * _Nonnull)aStatement theSQLStatement:(nonnull NSString *)aSQLQuery;
- (void)_executeSQLite3StepUsingSQLite3Statement:(sqlite3_stmt * _Nonnull)aStatement;
- (BOOL)_addObjectsFromArray:(nonnull NSArray *)someObjects forceSave:(BOOL)forceSave error:(NSError * _Nullable * _Nullable)outError;
+ (nonnull NSDictionary *)_defaultTestData;
- (BOOL)_backupFileStoreToDirectoryAtPath:(nonnull NSString *)aPath extension:(nullable NSString *)anExtension compact:(BOOL)flag error:(NSError * _Nullable * _Nullable)outError;
- (BOOL)_backupMemoryStoreToDirectoryAtPath:(nonnull NSString *)aPath extension:(nullable NSString *)anExtension compact:(BOOL)flag error:(NSError * _Nullable * _Nullable)outError;
@end

/** \endcond */
