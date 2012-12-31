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
- (NSFOrderedDictionary *)dictionaryDescription;
+ (NSArray *)NSFP_sharedROWIDKeywords;
- (NSString *)NSFP_cacheMethodToString;
- (NSString*)NSFP_nestedDescriptionWithPrefixedSpace:(NSString *)prefixedSpace;
+ (NSDictionary *)_plistToDictionary:(NSString *)aPlist;
- (NSFNanoDatatype)NSFP_datatypeForTable:(NSString *)table column:(NSString *)column;
+ (void)NSFP_decodeQuantum:(unsigned char *)dest andSource:(const char *)src;
- (void)NSFP_setFullColumnNamesEnabled;
- (NSArray *)NSFP_flattenAllTables;
- (NSInteger)NSFP_prepareSQLite3Statement:(sqlite3_stmt **)aStatement theSQLStatement:(NSString *)aSQLQuery;
- (NSFNanoDatatype)NSFP_datatypeForColumn:(NSString *)tableAndColumn;
+ (int)NSFP_stripBitsFromExtendedResultCode:(int)extendedResult;

- (BOOL)NSFP_beginTransactionMode:(NSString *)theSQLStatement;
- (BOOL)NSFP_createTable:(NSString *)table withColumns:(NSArray *)tableColumns datatypes:(NSArray *)tableDatatypes isTemporary:(BOOL)isTemporaryFlag;
- (BOOL)NSFP_removeColumn:(NSString *)column fromTable:(NSString *)table;
- (void)NSFP_rebuildDatatypeCache;
- (BOOL)NSFP_insertStringValues:(NSArray *)values forColumns:(NSArray *)columns table:(NSString *)table;

- (void)NSFP_sqlString:(NSMutableString*)theSQLStatement appendingTags:(NSArray *)tags quoteTags:(BOOL)flag;
- (void)NSFP_sqlString:(NSMutableString*)theSQLStatement appendingTags:(NSArray *)columns;
- (BOOL)NSFP_sqlString:(NSMutableString*)theSQLStatement forTable:(NSString *)table withColumns:(NSArray *)columns datatypes:(NSArray *)datatypes;

- (NSInteger)NSFP_ROWIDPresenceLocation:(NSArray *)tableColumns datatypes:(NSArray *)datatypes;
- (BOOL)NSFP_isColumnROWIDAlias:(NSString *)column forTable:(NSString *)table;

- (NSString *)NSFP_prefixWithDotDelimiter:(NSString *)tableAndColumn;
- (NSString *)NSFP_suffixWithDotDelimiter:(NSString *)tableAndColumn;

- (void)NSFP_installCommitCallback;
- (void)NSFP_uninstallCommitCallback;
@end

/** \endcond */