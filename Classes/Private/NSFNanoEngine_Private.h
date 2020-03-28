/*
 *  NSFNanoEngine_Private.h
 *  A lightweight Cocoa wrapper for SQLite
 *  
 *  Written by Tito Ciuro (21-Jan-2003)

	Copyright (c) 2004, Tito Ciuro
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted
	provided that the following conditions are met:
	
	• 	Redistributions of source code must retain the above copyright notice, this list of conditions
		and the following disclaimer.
	• 	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
		and the following disclaimer in the documentation and/or other materials provided with the distribution.
	• 	Neither the name of Tito Ciuro nor the names of its contributors may be used to endorse or promote
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

#import "NSFNanoEngine.h"
#import "NSFNanoGlobals_Private.h"
#import "NSFNanoResult.h"
#import "NSFOrderedDictionary.h"

/** \cond */

@interface NSFNanoEngine (Private)
- (nonnull NSFOrderedDictionary *)dictionaryDescription;
+ (nonnull NSArray *)NSFP_sharedROWIDKeywords;
@property (nonatomic, readonly, copy, nonnull ) NSString *NSFP_cacheMethodToString;
- (nonnull NSString *)NSFP_nestedDescriptionWithPrefixedSpace:(nonnull NSString *)prefixedSpace;
+ (nullable NSDictionary *)_plistToDictionary:(nonnull NSString *)aPlist;
+ (void)NSFP_decodeQuantum:(unsigned char * _Nonnull)dest andSource:(const char * _Nonnull)src;
@property (nonatomic, readonly, copy, nonnull) NSArray *NSFP_flattenAllTables;
- (NSInteger)NSFP_prepareSQLite3Statement:(sqlite3_stmt * _Nonnull * _Nonnull)aStatement theSQLStatement:(nonnull NSString *)aSQLQuery;
+ (int)NSFP_stripBitsFromExtendedResultCode:(int)extendedResult;

- (BOOL)NSFP_beginTransactionMode:(nonnull NSString *)theSQLStatement;
- (BOOL)NSFP_createTable:(nonnull NSString *)table withColumns:(nonnull NSArray *)tableColumns datatypes:(nonnull NSArray *)tableDatatypes isTemporary:(BOOL)isTemporaryFlag;
- (BOOL)NSFP_removeColumn:(nonnull NSString *)column fromTable:(nonnull NSString *)table;
- (void)NSFP_rebuildDatatypeCache;
- (BOOL)NSFP_insertStringValues:(nonnull NSArray *)values forColumns:(nonnull NSArray *)columns table:(nonnull NSString *)table;

- (void)NSFP_sqlString:(nonnull NSMutableString *)theSQLStatement appendingTags:(nonnull NSArray *)tags quoteTags:(BOOL)flag;
- (void)NSFP_sqlString:(nonnull NSMutableString *)theSQLStatement appendingTags:(nonnull NSArray *)columns;
- (BOOL)NSFP_sqlString:(nonnull NSMutableString *)theSQLStatement forTable:(nonnull NSString *)table withColumns:(nonnull NSArray *)columns datatypes:(nonnull NSArray *)datatypes;

- (NSInteger)NSFP_ROWIDPresenceLocation:(nonnull NSArray *)tableColumns datatypes:(nonnull NSArray *)datatypes;

- (nonnull NSString *)NSFP_prefixWithDotDelimiter:(nonnull NSString *)tableAndColumn;
- (nonnull NSString *)NSFP_suffixWithDotDelimiter:(nonnull NSString *)tableAndColumn;

- (void)NSFP_installCommitCallback;
- (void)NSFP_uninstallCommitCallback;
@end

/** \endcond */
