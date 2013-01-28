/*
     NSFNanoEngine.m
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
#import "NSFOrderedDictionary.h"

#import <stdio.h>
#import <stdlib.h>
#import <unistd.h>

#pragma mark// ==================================
#pragma mark// NSFNanoEngine C Declarations
#pragma mark// ==================================

int NSFP_commitCallback(void* nsfdb);

static char     __NSFP_base64Table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static NSArray  *__NSFP_SQLCommandsReturningData = nil;
static NSArray  *__NSFPSharedROWIDKeywords = nil;
static NSSet    *__NSFPSharedNanoStoreEngineDatatypes = nil;

#pragma mark -

@interface NSFNanoEngine ()

/** \cond */
@property (nonatomic, assign, readwrite) sqlite3 *sqlite;
@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic) NSMutableDictionary *schema;
@property (nonatomic) BOOL willCommitChangeSchema;
@property (nonatomic) unsigned int busyTimeout;
/** \endcond */

@end

@implementation NSFNanoEngine

#pragma mark -

#pragma mark// ==================================
#pragma mark// Initialization/Cleanup Methods
#pragma mark// ==================================

+ (id)databaseWithPath:(NSString *)thePath
{
 if (nil == thePath)
     [[NSException exceptionWithName:NSFUnexpectedParameterException
                              reason:[NSString stringWithFormat:@"*** -[%@ %@]: thePath is nil.", [self class], NSStringFromSelector(_cmd)]
                            userInfo:nil]raise];
    
    return [[self alloc]initWithPath:thePath];
}

- (id)initWithPath:(NSString *)thePath
{
    if (nil == thePath)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: thePath is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ((self = [self init])) {
        _path = thePath;
    }
    
    return self;
}

/** \cond */

+ (void)initialize
{
    __NSFP_SQLCommandsReturningData = [[NSArray alloc]initWithObjects:@"SELECT", @"PRAGMA", @"EXPLAIN", nil];
}

- (id)init
{
    if ((self = [super init])) {
        _path = nil;
        _schema = nil;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

/** \endcond */

- (NSString *)description
{
    return [self JSONDescription];
}

- (NSFOrderedDictionary *)dictionaryDescription
{
    NSFOrderedDictionary *values = [NSFOrderedDictionary new];
    
    values[@"SQLite address"] = [NSString stringWithFormat:@"%p", self.sqlite];
    values[@"Database path"] = _path;
    values[@"Cache method"] = [self NSFP_cacheMethodToString];
    
    return values;
}

- (NSString *)JSONDescription
{
    NSFOrderedDictionary *values = [self dictionaryDescription];
    
    NSError *outError = nil;
    NSString *description = [NSFNanoObject _NSObjectToJSONString:values error:&outError];
    
    return description;
}

#pragma mark// ==================================
#pragma mark// Opening & Closing Methods
#pragma mark// ==================================

- (BOOL)openWithCacheMethod:(NSFCacheMethod)theCacheMethod useFastMode:(BOOL)useFastMode
{
    int status = sqlite3_open_v2( [_path UTF8String], &_sqlite,
                                 SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_AUTOPROXY | SQLITE_OPEN_FULLMUTEX, NULL);
    
    // Set NanoStoreEngine's page size to match the system current page size
    if (0 == [[self tables]count]) {
        NSUInteger systemPageSize = [NSFNanoEngine systemPageSize];
        [self setPageSize:systemPageSize];
    }

    // Since we're operating with extended result code support, extract the bits
    // and obtain the regular result code
    // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
    
    status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
    
    if ((SQLITE_OK != status) || (sqlite3_extended_result_codes(self.sqlite, 1) != SQLITE_OK))
        return NO;
        
    if ([[_path lowercaseString]isEqualToString:NSFMemoryDatabase] == YES) {
        
        sqlite3_exec(self.sqlite, "PRAGMA fullfsync = OFF;", NULL, NULL, NULL);
        sqlite3_exec(self.sqlite, "PRAGMA temp_store = MEMORY", NULL, NULL, NULL);
        sqlite3_exec(self.sqlite, "PRAGMA synchronous = OFF;", NULL, NULL, NULL);
        sqlite3_exec(self.sqlite, "PRAGMA journal_mode = MEMORY;", NULL, NULL, NULL);
        sqlite3_exec(self.sqlite, "PRAGMA temp_store = MEMORY", NULL, NULL, NULL);
        
    } else {
        
        // Set FastMode accordingly...
        if (YES == useFastMode) {
            sqlite3_exec(self.sqlite, "PRAGMA fullfsync = OFF;", NULL, NULL, NULL);
            sqlite3_exec(self.sqlite, "PRAGMA synchronous = OFF;", NULL, NULL, NULL);
            sqlite3_exec(self.sqlite, "PRAGMA journal_mode = MEMORY;", NULL, NULL, NULL);
            sqlite3_exec(self.sqlite, "PRAGMA temp_store = MEMORY", NULL, NULL, NULL);
        } else {
            sqlite3_exec(self.sqlite, "PRAGMA fullfsync = OFF;", NULL, NULL, NULL);
            sqlite3_exec(self.sqlite, "PRAGMA synchronous = FULL;", NULL, NULL, NULL);
            sqlite3_exec(self.sqlite, "PRAGMA journal_mode = DELETE", NULL, NULL, NULL);
            sqlite3_exec(self.sqlite, "PRAGMA temp_store = DEFAULT", NULL, NULL, NULL);
        }
        
    }

    // Save whether we want data to be fetched lazily
    _cacheMethod = theCacheMethod;
    
    [self setBusyTimeout:250];
    
    // Refresh the schema cache
    [self NSFP_rebuildDatatypeCache];
    
    [self NSFP_installCommitCallback];
    
    return YES;
}


- (BOOL)close
{
    if (NO == self.sqlite) {
        return NO;
    }
    
    if (YES == [self isTransactionActive]) {
        [self rollbackTransaction];
    }
    
    // Make sure we clear the temporary data from schema
    NSArray *tempTables = [self temporaryTables];
    
    if ([tempTables count] > 0) {
        [self beginTransaction];
        
        for (NSString *table in tempTables) {
            [self dropTable:table];
        }
        
        [self commitTransaction];
    }
    
    int status = sqlite3_close(self.sqlite);
    _sqlite = NULL;
    
    // Since we're operating with extended result code support, extract the bits
    // and obtain the regular result code
    // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
    
    status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
    
    return (SQLITE_OK == status);
}

- (BOOL)isDatabaseOpen
{
    return (NULL != self.sqlite);
}

#pragma mark Transaction Methods

- (BOOL)beginTransaction
{
    if (YES == [self isTransactionActive])
        return NO;
    
    _willCommitChangeSchema = NO;
    
    return [self beginDeferredTransaction];
}

- (BOOL)beginDeferredTransaction
{
    if (YES == [self isTransactionActive])
        return NO;
    
    _willCommitChangeSchema = NO;
    
    return [self NSFP_beginTransactionMode:@"BEGIN DEFERRED TRANSACTION;"];
}

- (BOOL)commitTransaction
{
    if (NO == [self isTransactionActive]) {
        _willCommitChangeSchema = NO;
        return NO;
    }
    
    if (NO == _willCommitChangeSchema)
        [self NSFP_uninstallCommitCallback];
    
    BOOL success = (nil == [[self executeSQL:@"COMMIT TRANSACTION;"]error]);
    
    if (NO == _willCommitChangeSchema)
        [self NSFP_installCommitCallback];
    
    _willCommitChangeSchema = NO;
    
    return success;
}

- (BOOL)rollbackTransaction
{
    if ([self isTransactionActive] == NO) {
        _willCommitChangeSchema = NO;
        return NO;
    }
    
    BOOL success = (nil == [[self executeSQL:@"ROLLBACK TRANSACTION;"]error]);
    
    _willCommitChangeSchema = NO;
    
    return success;
}

- (BOOL)isTransactionActive
{
    sqlite3* myDB = self.sqlite;
    
    int status = sqlite3_get_autocommit(myDB);
    
    // Since we're operating with extended result code support, extract the bits
    // and obtain the regular result code
    // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
    
    status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
    
    return (0 == status);
}

#pragma mark// ==================================
#pragma mark// Utility Methods
#pragma mark// ==================================

+ (NSString *)stringWithUUID
{ 
    CFUUIDRef uuidCF = CFUUIDCreate(NULL);
    NSString *uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuidCF);
    CFRelease(uuidCF);
    return uuid;
} 

- (BOOL)compact
{
    if (NO == [self isTransactionActive])
        return (nil == [[self executeSQL:@"VACUUM;"]error]);
    
    return NO;
}

- (BOOL)integrityCheck
{
    if (NO == [self isTransactionActive]) {
        NSFNanoResult* result = [self executeSQL:@"PRAGMA integrity_check"];
        
        // SQLite returns the status as 'ok'. Let's code defensively and lowercase the result.
        return ([[[[result valuesForColumn:@"integrity_check"]lastObject]lowercaseString]isEqualToString:@"ok"]);
    }
    
    return NO;
}

+ (NSString *)nanoStoreEngineVersion
{
    return NSFVersionKey;
}

+ (NSString *)sqliteVersion
{
    return [NSString stringWithUTF8String: sqlite3_libversion()];
}

+ (NSSet*)sharedNanoStoreEngineDatatypes
{
    if (nil == __NSFPSharedNanoStoreEngineDatatypes)
        __NSFPSharedNanoStoreEngineDatatypes = [[NSSet alloc]initWithObjects:NSFStringFromNanoDataType(NSFNanoTypeRowUID),
                                                NSFStringFromNanoDataType(NSFNanoTypeString),
                                                NSFStringFromNanoDataType(NSFNanoTypeData),
                                                NSFStringFromNanoDataType(NSFNanoTypeDate),
                                                NSFStringFromNanoDataType(NSFNanoTypeNumber),
                                                nil];
    
    return __NSFPSharedNanoStoreEngineDatatypes;
}

#pragma mark// ==================================
#pragma mark// Table and Introspection Methods
#pragma mark// ==================================

- (BOOL)createTable:(NSString *)table withColumns:(NSArray *)columns datatypes:(NSArray *)datatypes
{
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == columns)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: columns is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == datatypes)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: datatypes is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    return [self NSFP_createTable:table withColumns:columns datatypes:datatypes isTemporary:NO];
}

- (BOOL)dropTable:(NSString *)table
{
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    BOOL transactionSetHere = NO;
    if ([self isTransactionActive] == NO)
        transactionSetHere = [self beginTransaction];
    
    NSString *theSQLStatement = [[NSString alloc]initWithFormat:@"DROP TABLE %@;", table];
    BOOL everythingIsFine = (nil == [[self executeSQL:theSQLStatement]error]);
    
    if (everythingIsFine) {
        theSQLStatement = [[NSString alloc]initWithFormat:@"DELETE FROM %@ WHERE %@ = '%@';", NSFP_SchemaTable, NSFP_TableIdentifier, table];
        everythingIsFine = (nil == [[self executeSQL:theSQLStatement]error]);
    }
    
    if (transactionSetHere) {
        if (everythingIsFine)
            [self commitTransaction];
        else
            [self rollbackTransaction];
    }
    
    if (everythingIsFine)
        [self NSFP_rebuildDatatypeCache];
    
    return everythingIsFine;
}

- (BOOL)createIndexForColumn:(NSString *)column table:(NSString *)table isUnique:(BOOL)flag
{
    if (nil == column)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: column is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSString  *theSQLStatement = nil;
    
    if (flag)
        theSQLStatement = [[NSString alloc]initWithFormat:@"CREATE UNIQUE INDEX %@_%@_IDX ON %@ (%@);", table, column, table, column];
    else
        theSQLStatement = [[NSString alloc]initWithFormat:@"CREATE INDEX %@_%@_IDX ON %@ (%@);", table, column, table, column];
    
    BOOL indexWasCreated = (nil == [[self executeSQL:theSQLStatement]error]);
    
    return indexWasCreated;
}

- (void)dropIndex:(NSString *)indexName
{
    if (nil == indexName)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: indexName is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSString  *theSQLStatement = [[NSString alloc]initWithFormat:@"DROP INDEX %@;", indexName];
    
    [self executeSQL:theSQLStatement];
}

- (NSArray *)tables
{
    NSArray *allTables = [self NSFP_flattenAllTables];
    if ([allTables count] == 0)
        return allTables;
    
    // Remove NSF's private table
    NSMutableArray *tempTables = [NSMutableArray arrayWithArray:allTables];
    [tempTables removeObject:NSFP_SchemaTable];
    
    return tempTables;
}

- (NSDictionary *)allTables
{
    NSMutableDictionary *allTables = [NSMutableDictionary dictionary];
    
    // Make sure we obtain full column names
    [self NSFP_setFullColumnNamesEnabled];
    
    NSFNanoResult *databasesResult = [self executeSQL:@"PRAGMA database_list"];
    NSArray *databases = [databasesResult valuesForColumn:@"name"];
    
    for (NSString *database in databases) {
        NSString *theSQLStatement = [NSString stringWithFormat:@"SELECT * FROM %@.sqlite_master;", database];
        NSFNanoResult* result = [self executeSQL:theSQLStatement];
        if (nil == [result error]) {
            // Get all tables in the database
            NSArray *databaseTables = [result valuesForColumn:@"sqlite_master.tbl_name"];
            NSSet *tablesPerDatabase = [NSSet setWithArray:databaseTables];
            [allTables setObject: [tablesPerDatabase allObjects] forKey: database];
        }
    }
    
    return allTables;
}

- (NSArray *)columnsForTable:(NSString *)table
{
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];

    NSString *theSQLStatement = nil;
    NSString  *database = [self NSFP_prefixWithDotDelimiter:table];
    
    if ([database isEqualToString:table] == NO) {
        database = [NSString stringWithFormat:@"%@.", database];
        table = [self NSFP_suffixWithDotDelimiter:table];
        theSQLStatement = [NSString stringWithFormat:@"PRAGMA %@.table_info ('%@');", database, table];
    } else {
        theSQLStatement = [NSString stringWithFormat:@"PRAGMA table_info ('%@');", table];
    }
    
    NSFNanoResult *result = [self executeSQL:theSQLStatement];
    
    return [result valuesForColumn:@"name"];
}

- (NSArray *)datatypesForTable:(NSString *)table
{
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSString *theSQLStatement = nil;
    NSString  *database = [self NSFP_prefixWithDotDelimiter:table];
    
    if ([database isEqualToString:table] == NO) {
        database = [NSString stringWithFormat:@"%@.", database];
        table = [self NSFP_suffixWithDotDelimiter:table];
        theSQLStatement = [NSString stringWithFormat:@"PRAGMA %@.table_info ('%@');", database, table];
    } else {
        theSQLStatement = [NSString stringWithFormat:@"PRAGMA table_info ('%@');", table];
    }
    
    NSFNanoResult *result = [self executeSQL:theSQLStatement];
    
    return [result valuesForColumn:@"type"];
}

- (NSArray *)indexes
{
    NSFNanoResult* result = [self executeSQL:@"SELECT name FROM sqlite_master WHERE type='index' ORDER BY name"];
    
    return [result valuesForColumn:@"sqlite_master.name"];
}

- (NSArray *)indexedColumnsForTable:(NSString *)table
{
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSFNanoResult* result = [self executeSQL:[NSString stringWithFormat:@"SELECT sqlite_master.name FROM sqlite_master WHERE type = 'index' AND sqlite_master.tbl_name = '%@';", table]];
    if ([result numberOfRows] == 0) {
        result = [self executeSQL:[NSString stringWithFormat:@"SELECT sqlite_temp_master.name FROM sqlite_temp_master WHERE type = 'index' AND sqlite_temp_master.tbl_name = '%@';", table]];
        return [result valuesForColumn:@"sqlite_temp_master.name"];
    }
    
    return [result valuesForColumn:@"sqlite_master.name"];
}

- (NSArray *)temporaryTables
{
    NSFNanoResult* result = [self executeSQL:@"SELECT * FROM sqlite_temp_master"]; 
    return [[NSSet setWithArray:[result valuesForColumn:@"sqlite_temp_master.tbl_name"]]allObjects];
}

- (NSFNanoResult *)executeSQL:(NSString *)theSQLStatement
{
    if (nil == theSQLStatement)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theSQLStatement is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ([theSQLStatement length] == 0)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theSQLStatement is empty.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    // Check whether we will need to return a dictionary with results
    sqlite3 *sqliteStore = self.sqlite;
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    BOOL returnInfo = NO;
    
    for (NSString *sqlCommand in __NSFP_SQLCommandsReturningData) {
        if ([theSQLStatement compare:sqlCommand options:NSCaseInsensitiveSearch range:NSMakeRange(0, [sqlCommand length])] == NSOrderedSame) {
            returnInfo = YES;
            break;
        }
    }
    
    int status = SQLITE_OK;
    char *errorMessage = NULL;
    
    if (returnInfo) {
        sqlite3_stmt *theSQLiteStatement = NULL;

        status = sqlite3_prepare_v2 (sqliteStore, [theSQLStatement UTF8String], -1, &theSQLiteStatement, NULL );
        
        status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];

        if (SQLITE_OK == status) {
            info = [NSMutableDictionary dictionary];
            int columnIndex, numColumns = sqlite3_column_count (theSQLiteStatement);
            
            while (SQLITE_ROW == sqlite3_step (theSQLiteStatement)) {
                for (columnIndex = 0; columnIndex < numColumns; columnIndex++) {
                    // Safety check: obtain the column and value. If the column is NULL, skip the iteration.
                    char *columnUTF8 = (char *)sqlite3_column_name (theSQLiteStatement, columnIndex);
                    if (NULL == columnUTF8) {
                        continue;
                    }
                    NSString *column = [[NSString alloc]initWithUTF8String:columnUTF8];

                    // Sanity check: some queries return NULL, which would cause a crash below.
                    if ([column isEqualToString:@"NSFKeys.NSFKeyedArchive"]) {
                        //KeyedArchive is a blob
                        NSData *dictBinData = [[NSData alloc] initWithBytes:sqlite3_column_blob(theSQLiteStatement, columnIndex) length: sqlite3_column_bytes(theSQLiteStatement, 1)];
                        
                        // Obtain the array to collect the values. If the array doesn't exist, create it.
                        NSMutableArray *values = [info objectForKey:column];
                        if (nil == values) {
                            values = [NSMutableArray new];
                        }
                        [values addObject:dictBinData];
                        [info setObject:values forKey:column];
                    }else
                    {
                        char *valueUTF8 = (char *)sqlite3_column_text (theSQLiteStatement, columnIndex);
                        NSString *value = nil;
                        if (NULL != valueUTF8) {
                            value = [[NSString alloc]initWithUTF8String:valueUTF8];
                        } else {
                            value = [[NSNull null]description];
                        }
                        
                        // Obtain the array to collect the values. If the array doesn't exist, create it.
                        NSMutableArray *values = [info objectForKey:column];
                        if (nil == values) {
                            values = [NSMutableArray new];
                        }
                        [values addObject:value];
                        [info setObject:values forKey:column];
                    }

                    
                    // Let's cleanup. This will keep the memory footprint low...
                }
                
            }
            
            sqlite3_finalize (theSQLiteStatement);
        }
    } else {
        status = sqlite3_exec(sqliteStore, [theSQLStatement UTF8String], NULL, NULL, &errorMessage);
        
        // Since we're operating with extended result code support, extract the bits
        // and obtain the regular result code
        // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
        
        status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
    }
    
    NSFNanoResult *result = nil;
    
    if (SQLITE_OK != status) {
        NSString *msg = (NULL != errorMessage) ? [NSString stringWithUTF8String:errorMessage] : [NSString stringWithFormat:@"SQLite error ID: %d", status];
        result = [NSFNanoResult _resultWithError:[NSError errorWithDomain:NSFDomainKey
                                                                    code:NSFNanoStoreErrorKey
                                                                userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"*** -[%@ %@]: %@", [self class], NSStringFromSelector(_cmd), msg]
                                                                                                     forKey:NSLocalizedFailureReasonErrorKey]]];
    } else {
        result = [NSFNanoResult _resultWithDictionary:info];
    }
    
    // Cleanup
    if (NULL != errorMessage) {
        sqlite3_free (errorMessage);
    }
    
    return result;
}

- (long long)maxRowUIDForTable:(NSString *)table
{
    if (nil == table) {
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theSQLStatement is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    }
    
    NSString *sql = [[NSString alloc]initWithFormat:@"SELECT max(ROWID) FROM %@", table];
    
    NSFNanoResult *result = [self executeSQL:sql];
    
    
    return [[result firstValue]longLongValue];
}

#pragma mark// ==================================
#pragma mark// SQLite Tunning Methods
#pragma mark// ==================================

- (void)setBusyTimeout:(unsigned int)theTimeout
{
    // If the timeout is out-of-range, default the value
    if ((theTimeout < 100) || (theTimeout > 5 * 1000)) {
        theTimeout = 250;
    }
    
    _busyTimeout = theTimeout;
    
    sqlite3_busy_timeout(self.sqlite, _busyTimeout);
}

+ (NSInteger)systemPageSize
{
    static NSUInteger __sSystemPageSize = NSNotFound;
    
    if (NSNotFound == __sSystemPageSize) {
        __sSystemPageSize = getpagesize();
    }
    
    return __sSystemPageSize;
}

+ (NSUInteger)recommendedCacheSize
{
    static NSUInteger __sRecommendedCacheSize = NSNotFound;
    
    if (NSNotFound == __sRecommendedCacheSize) {
        NSUInteger defaultNanoStoreEngineCacheSize = 10000;
        unsigned long long physMem = [[NSProcessInfo processInfo] physicalMemory];
        
        physMem = physMem / (512 * 1024 * 1000);
        __sRecommendedCacheSize = (NSInteger)physMem * defaultNanoStoreEngineCacheSize;
        if (0 == __sRecommendedCacheSize) {
            __sRecommendedCacheSize = defaultNanoStoreEngineCacheSize;
        }
    }
    
    return __sRecommendedCacheSize;
}

- (BOOL)setCacheSize:(NSUInteger)numberOfPages
{
    if (numberOfPages < 1000)
        numberOfPages = 1000;
    
    [self executeSQL:[NSString stringWithFormat:@"PRAGMA cache_size = %ld", numberOfPages]];
    NSUInteger cacheSize = [self cacheSize];
    return (cacheSize == numberOfPages);
}

- (NSUInteger)cacheSize
{
    NSFNanoResult *result = [self executeSQL:@"PRAGMA cache_size;"];
    NSString *value = [result firstValue];
    return [value integerValue];
}

- (BOOL)setPageSize:(NSUInteger)numberOfBytes
{
    [self executeSQL:[NSString stringWithFormat:@"PRAGMA page_size = %ld", numberOfBytes]];
    NSUInteger pageSize = [self pageSize];
    return (pageSize == numberOfBytes);
}

- (NSUInteger)pageSize
{
    NSFNanoResult *result = [self executeSQL:@"PRAGMA page_size;"];
    NSString *value = [result firstValue];
    return [value integerValue];
}

- (BOOL)setEncodingType:(NSFEncodingType)theEncodingType
{
    BOOL success = NO;
    
    if (NSFEncodingUTF8 == theEncodingType) {
        [self executeSQL:@"PRAGMA encoding = \"UTF-8\";"];
        NSFEncodingType encoding = [self encoding];
        success = (NSFEncodingUTF8 == encoding);
    } else if (NSFEncodingUTF16 == theEncodingType) {
        [self executeSQL:@"PRAGMA encoding = \"UTF-16\";"];
        NSFEncodingType encoding = [self encoding];
        success = (NSFEncodingUTF16 == encoding);
    }
    
    return success;
}

- (NSFEncodingType)encoding
{
    NSFNanoResult *result = [self executeSQL:@"pragma encoding;"];
    NSString *value = [result firstValue];
    return [NSFNanoEngine NSStringToNSFEncodingType:value];
}

+ (NSFEncodingType)NSStringToNSFEncodingType:(NSString *)value
{
    NSFEncodingType convertedValue = NSFEncodingUnknown;
    
    if (YES == [value isEqualToString:@"UTF-8"]) {
        convertedValue = NSFEncodingUTF8;
    } else if (YES == [value isEqualToString:@"UTF-16"]) {
        convertedValue = NSFEncodingUTF16;
    }
    
    return convertedValue;
}

+ (NSString *)NSFEncodingTypeToNSString:(NSFEncodingType)value
{
    NSString *convertedValue = nil;
    
    if (NSFEncodingUTF8 == value) {
        convertedValue = @"UTF-8";
    } else if (NSFEncodingUTF16 == value) {
        convertedValue = @"UTF-16";
    }
    
    return convertedValue;
}

- (NSFSynchronousMode)synchronousMode
{
    NSFNanoResult* result = [self executeSQL:@"PRAGMA synchronous"];
    return [[[result valuesForColumn:@"synchronous"]lastObject]intValue];
}

- (void)setSynchronousMode:(NSFSynchronousMode)mode
{	
    switch (mode) {
        case SynchronousModeOff:
            [self executeSQL:@"PRAGMA synchronous = OFF;"];
            break;
        case SynchronousModeFull:
            [self executeSQL:@"PRAGMA synchronous = FULL;"];
            break;
        default:
            [self executeSQL:@"PRAGMA synchronous = NORMAL;"];
            break;
    }
}

- (NSFTempStoreMode)tempStoreMode
{
    NSFNanoResult* result = [self executeSQL:@"PRAGMA temp_store"];
    
    return [[[result valuesForColumn:@"temp_store"]lastObject]intValue];
}

- (void)setTempStoreMode:(NSFTempStoreMode)mode
{	
    switch (mode) {
        case TempStoreModeFile:
            [self executeSQL:@"PRAGMA temp_store = FILE"];
            break;
        case TempStoreModeMemory:
            [self executeSQL:@"PRAGMA temp_store = MEMORY"];
            break;
        default:
            [self executeSQL:@"PRAGMA temp_store = DEFAULT"];
            break;
    }
}

- (NSFJournalModeMode)journalModeAndReturnError:(out NSError **)outError
{
    NSFNanoResult *result = [self executeSQL:@"PRAGMA journal_mode; "];
    if (nil != [result error]) {
        if (nil != outError) {
            *outError = [[result error]copy];
            return JournalModeDelete;
        }
    }
    
    NSString *journalModeString = [result firstValue];
    if ([journalModeString isEqualToString:@"TRUNCATE"]) return JournalModeDelete;
    else if ([journalModeString isEqualToString:@"TRUNCATE"]) return JournalModeTruncate;
    else if ([journalModeString isEqualToString:@"PERSIST"]) return JournalModePersist;
    else if ([journalModeString isEqualToString:@"MEMORY"]) return JournalModeMemory;
    else if ([journalModeString isEqualToString:@"WAL"]) return JournalModeWAL;
    else return JournalModeOFF;
}

- (BOOL)setJournalMode:(NSFJournalModeMode)theMode
{
    if (YES == [self isTransactionActive]) {
        return NO;
    }
    
    NSString *theModeString = nil;
    
    switch (theMode) {
        case JournalModeTruncate:
            theModeString = @"TRUNCATE";
            break;
        case JournalModePersist:
            theModeString = @"PERSIST";
            break;
        case JournalModeMemory:
            theModeString = @"MEMORY";
            break;
        case JournalModeWAL:
            theModeString = @"WAL";
            break;
        case JournalModeOFF:
            theModeString = @"OFF";
            break;
        default:
            theModeString = @"DELETE";
            break;
    }
    
    [self executeSQL:[NSString stringWithFormat:@"PRAGMA journal_mode = %@", theModeString]];
    
    NSFJournalModeMode verificationMode = [self journalModeAndReturnError:nil];
    
    return (verificationMode == theMode);
}

#pragma mark// ==================================
#pragma mark// Binary Data Methods
#pragma mark// ==================================

+ (NSString *)encodeDataToBase64:(NSData*)data
{
    if (nil == data)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: data is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSInteger decodedDataSize = [data length];
    unsigned char *bytes = (unsigned char *)malloc(decodedDataSize);
    
    // Extract the bytes
    [data getBytes:bytes];
    
    unsigned char inBuffer[3];
    unsigned char outBuffer[4];
    NSInteger i;
    NSInteger segments;
    char *outputBuffer;
    char *base64Buffer;
    
    base64Buffer = outputBuffer = (char *)malloc (decodedDataSize * 4 / 3 + 4);
    if (NULL == outputBuffer) {
        free (bytes);
        return nil;
    }
    
    while (decodedDataSize > 0) {
        for (i = segments = 0; i < 3; i++) {
            if (decodedDataSize > 0) {
                segments++;
                inBuffer[i] = *(bytes + i);
                decodedDataSize--;
            } else
                inBuffer[i] = 0;
        }
        
        outBuffer [0] = (inBuffer [0] & 0xFC) >> 2;
        outBuffer [1] = ((inBuffer [0] & 0x03) << 4) | ((inBuffer [1] & 0xF0) >> 4);
        outBuffer [2] = ((inBuffer [1] & 0x0F) << 2) | ((inBuffer [2] & 0xC0) >> 6);
        outBuffer [3] = inBuffer [2] & 0x3F;
        
        switch (segments) {
            case 1:
                sprintf(outputBuffer, "%c%c==",
                        __NSFP_base64Table[outBuffer[0]],
                        __NSFP_base64Table[outBuffer[1]]);
                break;
            case 2:
                sprintf(outputBuffer, "%c%c%c=",
                        __NSFP_base64Table[outBuffer[0]],
                        __NSFP_base64Table[outBuffer[1]],
                        __NSFP_base64Table[outBuffer[2]]);
                break;
            default:
                sprintf(outputBuffer, "%c%c%c%c",
                        __NSFP_base64Table[outBuffer[0]],
                        __NSFP_base64Table[outBuffer[1]],
                        __NSFP_base64Table[outBuffer[2]],
                        __NSFP_base64Table[outBuffer[3]] );
                break;
        }
        
        outputBuffer += 4;
    }
    
    *outputBuffer = 0;
    
    NSString  *myBase64Data = [NSString stringWithUTF8String:base64Buffer];
    
    free (base64Buffer);
    free (bytes);

    return myBase64Data;
}

+ (NSData*)decodeDataFromBase64:(NSString *)encodedData
{
    if (nil == encodedData)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: encodedData is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    const char* source = [encodedData UTF8String];
    NSUInteger sourceLength = strlen(source);
    char* destination = (char *)malloc(sourceLength * 3/4 + 8);
    char* destinationPtr = destination;
    
    NSInteger length = 0;
    NSInteger pivot = 0;
    NSInteger i;
    NSInteger numSegments;
    unsigned char lastSegment[3];
    NSUInteger decodedLength = 0;
    
    while ((source[length] != '=') && source[length])
        length++;
    while (source[length+pivot] == '=')
        pivot++;
    
    numSegments = (length + pivot) / 4;
    
    decodedLength = (numSegments * 3) - pivot;
    
    for (i = 0; i < numSegments - 1; i++) {
        [self NSFP_decodeQuantum:(unsigned char *)destination andSource:source];
        destination += 3;
        source += 4;
    }
    
    [self NSFP_decodeQuantum:lastSegment andSource:source];
    
    for (i = 0; i < 3 - pivot; i++)
        destination[i] = lastSegment[i];
    
    // Construct a NSData with the decoded data
    NSData* myDummyData = [NSData dataWithBytes:destinationPtr length:decodedLength];
    
    // Cleanup
    free (destinationPtr);
    
    return myDummyData;
}

#pragma mark// ==================================
#pragma mark// NSFNanoEngine Private Methods
#pragma mark// ==================================

/** \cond */

+ (NSArray *)NSFP_sharedROWIDKeywords
{
    if (nil == __NSFPSharedROWIDKeywords)
        __NSFPSharedROWIDKeywords = [[NSArray alloc]initWithObjects:@"ROWID", @"OID", @"_ROWID_", nil];
    
    return __NSFPSharedROWIDKeywords;
}

- (NSString *)NSFP_cacheMethodToString
{
    switch (_cacheMethod) {
        case CacheAllData:
            return @"Cache all data";
            break;
        case CacheDataOnDemand:
            return @"Cache data on demand";
            break;
        default:
            return @"Do not cache data";
            break;
    }
    
    return @"<unknown cache method";
}

+ (int)NSFP_stripBitsFromExtendedResultCode:(int)extendedResult
{
    return (extendedResult & 0x00FF);
}

+ (NSDictionary *)_plistToDictionary:(NSString *)aPlist
{
    if (nil == aPlist)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: aPlist is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ([aPlist length] == 0)
        return nil;
    
    // Some sanity check...
    if ([NSPropertyListSerialization propertyList:aPlist isValidForFormat:NSPropertyListXMLFormat_v1_0] == NO)
        return nil;
    
    NSString *errorString = nil;
    NSPropertyListFormat *format = nil;
    NSData *data = [aPlist dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *dict = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:format errorDescription:&errorString];
    
    if (nil == dict) {
        NSLog(@"*** -[%@ %@]: [NSPropertyListSerialization propertyListFromData] failure. %@", [self class], NSStringFromSelector(_cmd), errorString);
        NSLog(@"     Plist data: %@", aPlist);
        return nil;
    }
    
    return dict;
}

+ (void)NSFP_decodeQuantum:(unsigned char*)dest andSource:(const char *)src
{
    if (nil == dest)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: dest is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == src)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: src is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSUInteger x = 0;
    NSInteger i;
    for (i = 0; i < 4; i++) {
        if (src[i] >= 'A' && src[i] <= 'Z')
            x = (x << 6) + (NSUInteger)(src[i] - 'A' + 0);
        else if (src[i] >= 'a' && src[i] <= 'z')
            x = (x << 6) + (NSUInteger)(src[i] - 'a' + 26);
        else if (src[i] >= '0' && src[i] <= '9')
            x = (x << 6) + (NSUInteger)(src[i] - '0' + 52);
        else if (src[i] == '+')
            x = (x << 6) + 62;
        else if (src[i] == '/')
            x = (x << 6) + 63;
        else if (src[i] == '=')
            x = (x << 6);
    }
    
    dest[2] = (unsigned char)(x & 255);
    x >>= 8;
    dest[1] = (unsigned char)(x & 255);
    x >>= 8;
    dest[0] = (unsigned char)(x & 255);
}

- (NSFNanoDatatype)NSFP_datatypeForColumn:(NSString *)tableAndColumn
{
    if (nil == tableAndColumn)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: tableAndColumn is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSString  *table = [self NSFP_prefixWithDotDelimiter:tableAndColumn];
    NSString  *column = [self NSFP_suffixWithDotDelimiter:tableAndColumn];
    
    return [self NSFP_datatypeForTable:(NSString *)table column:(NSString *)column];
}

- (NSFNanoDatatype)NSFP_datatypeForTable:(NSString *)table column:(NSString *)column
{
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == column)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: column is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSString  *datatype = nil;
    
    // Check to see if the schema has been cached; take advantage of it if possible...
    if (nil != _schema) {
        datatype = [[_schema objectForKey:table]objectForKey:column];
        if (nil == datatype) datatype = NSFStringFromNanoDataType(NSFNanoTypeUnknown);
    } else {
        NSString  *theSQLStatement = [NSString stringWithFormat:@"SELECT %@ from %@ WHERE %@ = '%@' AND %@ = '%@';", NSFP_DatatypeIdentifier, NSFP_SchemaTable, NSFP_TableIdentifier, table, NSFP_ColumnIdentifier, column];
        
        NSFNanoResult* result = [self executeSQL:theSQLStatement];
        
        datatype = [[result valuesForColumn:NSFP_FullDatatypeIdentifier]lastObject];
                    
        if (nil == datatype) datatype = NSFStringFromNanoDataType(NSFNanoTypeUnknown);

        NSMutableDictionary *tempSchema = [_schema objectForKey:table];
        if (nil != tempSchema)
            tempSchema = [[NSMutableDictionary alloc]init];
        else
            ;
        
        [tempSchema setObject:datatype forKey:column];
        [_schema setObject:tempSchema forKey:table];
        
        tempSchema = nil;
    }

    return NSFNanoDatatypeFromString(datatype);
}

- (void)NSFP_setFullColumnNamesEnabled
{
    [self executeSQL:@"PRAGMA short_column_names = OFF;"];
    [self executeSQL:@"PRAGMA full_column_names = ON;"];
}

- (NSArray *)NSFP_flattenAllTables
{
    NSMutableSet *flattenedTables = [[NSMutableSet alloc]init];
    NSDictionary *allTables = [self allTables];
    NSEnumerator *enumerator = [allTables keyEnumerator];
    NSString  *database;
    BOOL addPrefix = ([allTables count] > 1);

    while ((database = [enumerator nextObject])) {
        NSArray *databaseTables = [allTables objectForKey:database];
        
        if ((YES == addPrefix) && ([database hasPrefix:@"main"] == NO)) {
            for (NSString *table in databaseTables) {
                [flattenedTables addObject:[NSString stringWithFormat:@"%@.%@", database, table]];
            }
        } else {
            [flattenedTables addObjectsFromArray:databaseTables];
        }
    }
    
    NSArray *immutableValues = [flattenedTables allObjects];
    
    flattenedTables = nil;
    
    return immutableValues;
}

- (NSInteger)NSFP_prepareSQLite3Statement:(sqlite3_stmt **)aStatement theSQLStatement:(NSString *)aSQLQuery
{
    if (nil == aSQLQuery)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: aSQLQuery is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    // Prepare SQLite's VM. It's placed here so we can speed up stores...
    int status = SQLITE_OK;
    BOOL continueLooping = YES;
    const char *query = [aSQLQuery UTF8String];

    do {
        status = sqlite3_prepare_v2(self.sqlite, query, -1, aStatement, NULL);
        
        // Since we're operating with extended result code support, extract the bits
        // and obtain the regular result code
        // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
        
        status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
        
        continueLooping = ((SQLITE_LOCKED == status) || (SQLITE_BUSY == status));
    } while (continueLooping);
    
    return status;
}

- (BOOL)NSFP_beginTransactionMode:(NSString *)theSQLStatement
{
    if (nil == theSQLStatement)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theSQLStatement is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ([self isTransactionActive] == NO) {
        sqlite3_stmt *NSF_sqliteVM;
        const char *query_tail = [theSQLStatement UTF8String];
        
        int status = sqlite3_prepare_v2(self.sqlite, query_tail, -1, &NSF_sqliteVM, &query_tail);
        
        // Since we're operating with extended result code support, extract the bits
        // and obtain the regular result code
        // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
        
        status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
        
        if (SQLITE_OK == status) {
            BOOL continueTrying = YES;
            
            do {
                status = sqlite3_step(NSF_sqliteVM);
                
                // Since we're operating with extended result code support, extract the bits
                // and obtain the regular result code
                // For more info check: http://www.sqlite.org/c3ref/c_ioerr_access.html
                
                status = [NSFNanoEngine NSFP_stripBitsFromExtendedResultCode:status];
                
                switch (status) {
                    case SQLITE_OK:
                    case SQLITE_DONE:
                        continueTrying = NO;
                        break;
                    case SQLITE_BUSY:
                        [self rollbackTransaction];
                        sqlite3_reset(NSF_sqliteVM);
                        continueTrying = YES;
                        break;
                    default:
                        [self rollbackTransaction];
                        continueTrying = NO;
                        break;
                }
            } while (continueTrying);
            
            return (SQLITE_OK == sqlite3_finalize(NSF_sqliteVM));
        }
    }
    
    return NO;
}

- (BOOL)NSFP_createTable:(NSString *)table withColumns:(NSArray *)tableColumns datatypes:(NSArray *)tableDatatypes isTemporary:(BOOL)isTemporaryFlag
{
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == tableColumns)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: tableColumns is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == tableDatatypes)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: tableDatatypes is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if ([tableColumns count] != [tableDatatypes count])
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: number of columns and datatypes mismatch.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSSet *allowedDatatypes = [NSFNanoEngine sharedNanoStoreEngineDatatypes];
    NSSet *specifiedDatatypes = [NSSet setWithArray:tableDatatypes];
    
    if (NO == [specifiedDatatypes isSubsetOfSet:allowedDatatypes])
        return NO;
    
    // Make sure we have specified ROWID in the group of columns
    NSMutableArray *revisedColumns = [[NSMutableArray alloc]initWithArray:tableColumns];
    NSMutableArray *revisedDatatypes = [[NSMutableArray alloc]initWithArray:tableDatatypes];
    NSInteger ROWIDIndex = [self NSFP_ROWIDPresenceLocation:tableColumns datatypes:tableDatatypes];
    NSString *ROWIDDatatype = [[NSString alloc]initWithFormat:@"%@ PRIMARY KEY", NSFStringFromNanoDataType(NSFNanoTypeRowUID)];
    
    if (NSNotFound != ROWIDIndex) {
        // Even though the ROWID has been specified by the user, we make sure the datatype is correct
        [revisedDatatypes replaceObjectAtIndex:ROWIDIndex withObject:ROWIDDatatype];
    } else {
        // ROWID not found:add it manually
        [revisedColumns insertObject:NSFRowIDColumnName atIndex:0];
        [revisedDatatypes insertObject:ROWIDDatatype atIndex:0];
    }
    
    
    BOOL transactionSetHere = NO;
    if (NO == [self isTransactionActive])
        transactionSetHere = [self beginTransaction];
    
    BOOL everythingIsFine = YES;
    
    NSMutableString* theSQLStatement;
    if (YES == isTemporaryFlag)
        theSQLStatement = [[NSMutableString alloc]initWithString:[NSString stringWithFormat:@"CREATE TEMPORARY TABLE %@(", table]];
    else
        theSQLStatement = [[NSMutableString alloc]initWithString:[NSString stringWithFormat:@"CREATE TABLE %@(", table]];
    
    NSMutableArray *tableCreationDatatypes = [NSMutableArray arrayWithArray:revisedDatatypes];
    
    if (YES == [self NSFP_sqlString:theSQLStatement forTable:table withColumns:revisedColumns datatypes:tableCreationDatatypes]) {
        [theSQLStatement appendString:@");"];
        
        everythingIsFine = (nil == [[self executeSQL:theSQLStatement]error]);
        
        if (everythingIsFine) {
            // Now add the entries to NSFP_SchemaTable
            NSInteger i, count = [revisedDatatypes count];
            
            for (i = 0; i < count; i++) {
                if (NO == [self NSFP_insertStringValues:[NSArray arrayWithObjects:table, [revisedColumns objectAtIndex:i], [revisedDatatypes objectAtIndex:i], nil] forColumns:[NSArray arrayWithObjects:NSFP_TableIdentifier, NSFP_ColumnIdentifier, NSFP_DatatypeIdentifier, nil]table:NSFP_SchemaTable]) {
                    everythingIsFine = NO;
                    break;
                }
            }
        }
    } else {
        everythingIsFine = NO;
    }
    
    if (transactionSetHere) {
        if (everythingIsFine)
            [self commitTransaction];
        else
            [self rollbackTransaction];
    }
    
    if (everythingIsFine)
        [self NSFP_rebuildDatatypeCache];
    
    return everythingIsFine;
}

- (BOOL)NSFP_removeColumn:(NSString *)column fromTable:(NSString *)table
{
    // Obtain all current columns and datatypes for table
    NSArray *tableInfoDatatypes = [self datatypesForTable:table];
    
    if (nil == column)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: column is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSArray *tableInfoColumns = [self columnsForTable:table];
    
    NSInteger index = [tableInfoColumns indexOfObject:column];
    
    if (index == NSNotFound)
        return NO;
    
    // Add the new column and data type to the list
    NSMutableArray *tableColumns = [[NSMutableArray alloc]initWithArray:tableInfoColumns];
    NSMutableArray *tableDatatypes = [[NSMutableArray alloc]initWithArray:tableInfoDatatypes];
    [tableColumns removeObjectAtIndex:index];
    [tableDatatypes removeObjectAtIndex:index];
    
    BOOL transactionSetHere = NO;
    if (NO == [self isTransactionActive])
        transactionSetHere = [self beginTransaction];
    
    // Create a backup table with the columns and datatypes
    NSUInteger numberOfIssues = 0;
    
    BOOL isTableTemporary = [[self temporaryTables]containsObject:table];
    if ([self NSFP_createTable:[NSString stringWithFormat:@"%@_backup", table] withColumns:tableColumns datatypes:tableDatatypes isTemporary:isTableTemporary]) {
        // Insert all existing data
        NSMutableString* query = [NSMutableString stringWithString:[NSString stringWithFormat:@"INSERT INTO %@_backup(", table]];
        
        [self NSFP_sqlString:query appendingTags:tableColumns];
        [query appendString:@") SELECT "];
        [self NSFP_sqlString:query appendingTags:tableColumns];
        
        if (nil == [[self executeSQL:[NSString stringWithFormat:@"%@ FROM %@;", query, table]]error])
            numberOfIssues++;
        
        // Delete the old table
        if ([self dropTable:table] == NO)
            numberOfIssues++;
        
        // Create the new table with the columns and datatypes
        isTableTemporary = [[self temporaryTables]containsObject:table];
        if ([self NSFP_createTable:table withColumns:tableColumns datatypes:tableDatatypes isTemporary:isTableTemporary] == NO)
            numberOfIssues++;
        
        // Copy the data from the backup table
        query = [NSMutableString stringWithString:[NSString stringWithFormat:@"INSERT INTO %@(", table]];
        
        [self NSFP_sqlString:query appendingTags:tableColumns];
        [query appendString:@") SELECT "];
        [self NSFP_sqlString:query appendingTags:tableColumns];
        
        if (nil == [[self executeSQL:[NSString stringWithFormat:@"%@ FROM %@_backup;", query, table]]error])
            numberOfIssues++;
        
        // Delete the backup table
        if ([self dropTable:[NSString stringWithFormat:@"%@_backup", table]] == NO)
            numberOfIssues++;
    } else {
        numberOfIssues++;
    }
        
    if (transactionSetHere) {
        if (0 == numberOfIssues) {
            [self commitTransaction];
        } else {
            [self rollbackTransaction];
        }
    }
    
    if (0 == numberOfIssues)
        [self NSFP_rebuildDatatypeCache];
    
    return (0 == numberOfIssues);
}

- (void)NSFP_rebuildDatatypeCache
{
    // Cleanup
    _schema = nil;
    _schema = [[NSMutableDictionary alloc]init];
    
    NSArray *tables = [self NSFP_flattenAllTables];
    if ([tables count] == 0)
        return;
    
    for (NSString *table in tables) {
        NSArray *columns = [self columnsForTable:table];
        NSArray *datatypes = [self datatypesForTable:table];
        if ((nil == table) || (nil != columns) || (nil != datatypes)) {
            break;
        }
        
        // Build the dictionary
        NSMutableDictionary *tableDictionary = [[NSMutableDictionary alloc]init];
        NSInteger j, columnCount = [columns count];
        
        for (j = 0; j < columnCount; j++) {
            [tableDictionary setObject:[datatypes objectAtIndex:j] forKey:[columns objectAtIndex:j]];
        }
        
        [_schema setObject:tableDictionary forKey:table];
    }
}

- (BOOL)NSFP_insertStringValues:(NSArray *)values forColumns:(NSArray *)columns table:(NSString *)table
{
    if (nil == values)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: values is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == columns)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: columns is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    // Make sure we have specified ROWID in the group of columns
    NSMutableArray *revisedColumns = (NSMutableArray*)columns;
    
    // Escape all values except the one with type NSFNanoTypeRowUID
    NSMutableArray *escapedValues = [[NSMutableArray alloc]init];
    NSInteger i, count = [revisedColumns count];
    
    for (i = 0; i < count; i++) {
        NSString  *column = [revisedColumns objectAtIndex:i];
        NSString  *value = [values objectAtIndex:i];
        NSString  *escapedValue = nil;
        if (NO == [self NSFP_isColumnROWIDAlias:column forTable:table])
            escapedValue = [[NSString alloc]initWithFormat:@"'%@'", value];
        else
            escapedValue = [[NSString alloc]initWithFormat:@"%@", value];
        [escapedValues addObject:escapedValue];
    }
    
    NSMutableString* theSQLStatement = [[NSMutableString alloc]initWithString:[NSString stringWithFormat:@"INSERT INTO %@(", table]];
    
    [self NSFP_sqlString:theSQLStatement appendingTags:revisedColumns];
    [theSQLStatement appendString:@") VALUES("];
    [self NSFP_sqlString:theSQLStatement appendingTags:escapedValues];
    [theSQLStatement appendString:@");"];
    BOOL insertWasOK = (nil == [[self executeSQL:theSQLStatement]error]);
    
    return insertWasOK;
}

- (void)NSFP_sqlString:(NSMutableString*)theSQLStatement appendingTags:(NSArray *)tags quoteTags:(BOOL)flag
{
    if (nil == theSQLStatement)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theSQLStatement is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == tags)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: tags is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSInteger i, count = [tags count];
    
    if (flag) {
        for (i = 0; i < count; i++) {
            NSString  *tagName = [tags objectAtIndex:i];
            NSString  *escapedValue = [[NSString alloc]initWithFormat:@"'%@'", tagName];
            
            [theSQLStatement appendString:escapedValue];
            
            if (i != count - 1)
                [theSQLStatement appendString:@","];
        }
    } else {
        [theSQLStatement appendString:[tags componentsJoinedByString:@","]];
    }
}

- (void)NSFP_sqlString:(NSMutableString*)theSQLStatement appendingTags:(NSArray *)tags
{
    if (nil == theSQLStatement)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theSQLStatement is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == tags)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: tags is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    [self NSFP_sqlString:theSQLStatement appendingTags:tags quoteTags:NO];
}

- (BOOL)NSFP_sqlString:(NSMutableString*)theSQLStatement forTable:(NSString *)table withColumns:(NSArray *)columns datatypes:(NSArray *)datatypes
{
    if (nil == theSQLStatement)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: theSQLStatement is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == columns)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: columns is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == datatypes)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: datatypes is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    BOOL constructionSucceeded = YES;
    NSInteger i, count = [columns count];
    
    for (i = 0; i < count; i++) {
        NSString  *column = [columns objectAtIndex:i];
        NSString  *datatype = [datatypes objectAtIndex:i];
        
        if (nil != datatype) {
            // Some datatypes may be empty strings.
            // See NSFNanoEngine's header file for more info on datatypesForTable:.
            NSString  *columnAndDatatype = nil;
            
            if ([datatype isEqualToString:@""])
                columnAndDatatype = [[NSString alloc]initWithFormat:@"%@", column];
            else
                columnAndDatatype = [[NSString alloc]initWithFormat:@"%@ %@", column, datatype];
            
            [theSQLStatement appendString:columnAndDatatype];
            
            if (i != count - 1)
                [theSQLStatement appendString:@","];
        } else {
            constructionSucceeded = NO;
        }
    }
    
    return constructionSucceeded;
}

- (NSInteger)NSFP_ROWIDPresenceLocation:(NSArray *)tableColumns datatypes:(NSArray *)datatypes
{
    if (nil == tableColumns)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: tableColumns is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == datatypes)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: datatypes is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    // First check if we have a datatype of type NSFNanoTypeRowUID
    NSInteger ROWIDIndex = NSNotFound;
    
    if (nil != datatypes) {
        NSInteger i, count = [datatypes count];
        NSString *rowUIDDatatype = NSFStringFromNanoDataType(NSFNanoTypeRowUID);

        for (i = 0; i < count; i++) {
            if ([[[datatypes objectAtIndex:i] uppercaseString]isEqualToString:rowUIDDatatype]) {
                ROWIDIndex = i;
                break;
            }
        }
    }
    
    if (NSNotFound == ROWIDIndex) {
        // Make sure we have specified ROWID in the group of columns
        NSArray *reservedKeywords = [NSFNanoEngine NSFP_sharedROWIDKeywords];
        
        for (NSString *tableColumn in tableColumns) {
            NSInteger index = [reservedKeywords indexOfObject:tableColumn];
            
            if (NSNotFound != index) {
                ROWIDIndex = index;
                break;
            }
        }
    }
    
    return ROWIDIndex;
}

- (BOOL)NSFP_isColumnROWIDAlias:(NSString *)column forTable:(NSString *)table
{
    if (nil == column)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: column is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    if (nil == table)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: table is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSString *rowUIDDatatype = NSFStringFromNanoDataType(NSFNanoTypeRowUID);
    
    if (nil != _schema)
        return [[[_schema objectForKey:table]objectForKey:column]isEqualToString:rowUIDDatatype];
    
    NSString  *theSQLStatement = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = '%@' AND %@ = '%@';", NSFP_DatatypeIdentifier, NSFP_SchemaTable, NSFP_TableIdentifier, table, NSFP_ColumnIdentifier, column];
    NSFNanoResult* result = [self executeSQL:theSQLStatement];
    
    NSString  *columnFound = [[result valuesForColumn:NSFP_FullDatatypeIdentifier]lastObject];
    BOOL isROWIDAlias = [columnFound isEqualToString:rowUIDDatatype];
    
    return isROWIDAlias;
}

- (NSString *)NSFP_prefixWithDotDelimiter:(NSString *)tableAndColumn
{
    if (nil == tableAndColumn)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: tableAndColumn is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSRange range = [tableAndColumn rangeOfString:@"." options:NSBackwardsSearch];
    if (NSNotFound == range.location)
        return tableAndColumn;
    
    return [tableAndColumn substringToIndex:range.location];
}

- (NSString *)NSFP_suffixWithDotDelimiter:(NSString *)tableAndColumn
{
    if (nil == tableAndColumn)
        [[NSException exceptionWithName:NSFUnexpectedParameterException
                                 reason:[NSString stringWithFormat:@"*** -[%@ %@]: tableAndColumn is nil.", [self class], NSStringFromSelector(_cmd)]
                               userInfo:nil]raise];
    
    NSRange range = [tableAndColumn rangeOfString:@"." options:NSBackwardsSearch];
    if (NSNotFound == range.location)
        return tableAndColumn;
    
    range.location++;
    range.length = [tableAndColumn length] - range.location;
    
    return [tableAndColumn substringWithRange:range];
}

- (void)NSFP_installCommitCallback
{
    sqlite3_commit_hook( self.sqlite, NSFP_commitCallback, (__bridge void *)(self));
}

- (void)NSFP_uninstallCommitCallback
{
    sqlite3_commit_hook( self.sqlite, NULL, NULL);
}

int NSFP_commitCallback(void* nsfdb)
{
    return SQLITE_OK;
}

/** \endcond */

@end