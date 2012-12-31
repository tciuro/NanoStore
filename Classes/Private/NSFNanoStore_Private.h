/*
     NSFNanoStore_Private.h
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

#import "NSFNanoStore.h"
#import "NSFOrderedDictionary.h"

/** \cond */

@interface NSFNanoStore (Private)
- (NSFOrderedDictionary *)dictionaryDescription;
+ (NSFNanoStore *)_createAndOpenDebugDatabase;
- (NSFNanoResult *)_executeSQL:(NSString *)theSQLStatement;
- (NSString*)_nestedDescriptionWithPrefixedSpace:(NSString *)prefixedSpace;
- (BOOL)_initializePreparedStatementsWithError:(out NSError **)outError;
- (void)_releasePreparedStatements;
- (void)_setIsOurTransaction:(BOOL)value;
- (BOOL)_isOurTransaction;
- (BOOL)_setupCachingSchema;
- (BOOL)_storeDictionary:(NSDictionary *)someInfo forKey:(NSString *)aKey forClassNamed:(NSString *)classType error:(out NSError **)outError;
- (BOOL)__storeDictionaries:(NSArray *)someObjects forKeys:(NSArray *)someKeys error:(out NSError **)outError;
- (BOOL)_bindValue:(id)aValue forAttribute:(NSString *)anAttribute parameterNumber:(NSInteger)aParamNumber usingSQLite3Statement:(sqlite3_stmt *)aStatement;
- (BOOL)_checkNanoStoreIsReadyAndReturnError:(out NSError **)outError;
- (NSFNanoDatatype)_NSFDatatypeOfObject:(id)value;
- (NSString *)_stringFromValue:(id)aValue;
+ (NSString *)_calendarDateToString:(NSDate *)aDate;
- (void)_flattenCollection:(NSDictionary *)info keys:(NSMutableArray **)flattenedKeys values:(NSMutableArray **)flattenedValues;
- (void)_flattenCollection:(id)someObject keyPath:(NSMutableArray **)aKeyPath keys:(NSMutableArray **)someKeys values:(NSMutableArray **)someValues;
- (BOOL)_prepareSQLite3Statement:(sqlite3_stmt **)aStatement theSQLStatement:(NSString *)aSQLQuery;
- (void)_executeSQLite3StepUsingSQLite3Statement:(sqlite3_stmt *)aStatement;
- (BOOL)_addObjectsFromArray:(NSArray *)someObjects forceSave:(BOOL)forceSave error:(out NSError **)outError;
+ (NSDictionary *)_defaultTestData;
- (BOOL)_backupFileStoreToDirectoryAtPath:(NSString *)aPath extension:(NSString *)anExtension compact:(BOOL)flag error:(out NSError **)outError;
- (BOOL)_backupMemoryStoreToDirectoryAtPath:(NSString *)aPath extension:(NSString *)anExtension compact:(BOOL)flag error:(out NSError **)outError;
@end

/** \endcond */