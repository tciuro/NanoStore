/*
     NSFNanoGlobals.h
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

#import <Foundation/Foundation.h>

/*! @file NSFNanoGlobals.h
 @brief Public available constants to be used in NanoStore.
 */

/** * If turned on, NanoStore will log debugging information to Console. */
extern void NSFSetIsDebugOn (BOOL flag);

/** * Determine whether NanoStore debugging services are turned on. */
extern BOOL NSFIsDebugOn (void);

/** * The mode used by NSFNanoEngine to manipulate data in the document store.
 * If FastMode is activated, the document store is opened with all performance turned on (more risky in case of failure). Deactivating it makes it slower,
 * but safer.
 * 
 * When FastMode is activated NanoStore continues without pausing as soon as it has handed data off to the operating system.
 * If the application running NanoStore crashes, the data will be safe, but the database might become corrupted if the operating system crashes
 * or the computer loses power before that data has been written to the disk surface.
 * On the other hand, some operations are as much as 50 or more times faster with FastMode activated.
 * 
 * If FastMode is deactivated, NanoStore will pause at critical moments to make sure that data has actually been written to the disk surface
 * before continuing. This ensures that if the operating system crashes or if there is a power failure, the database will be uncorrupted after rebooting.
 * Deactivating FastMode is very safe, but it is also slower.
 */
typedef enum {
    /** * The default mode is slower but safer. */
    NSFEngineProcessingDefaultMode = 1,
    /** * The fast mode is very quick but unsafe. */
    NSFEngineProcessingFastMode
} NSFEngineProcessingMode;

/** * Datatypes used by NanoStore.
 @note Additional information can be found on the SQLite website: http://www.sqlite.org/datatype3.html
 */
typedef enum {
    /** * Used when NanoStore doesn't know the datatype it has read back from the document store. Its string value equivalent is <b>UNKNOWN</b>.*/
    NSFNanoTypeUnknown = -1,
    /** * Used to define the <i>RowID</i> column type in SQLite tables. Only used if you create your own table via NSFNanoEngine. Its string equivalent is <b>INTEGER</b>. */
    NSFNanoTypeRowUID,
    /** * Used to store NSData elements. Its string equivalent is <b>BLOB</b>. */          
    NSFNanoTypeData,
    /** * Used to store NSString elements. Its string equivalent is <b>BLOB</b>. */
    NSFNanoTypeString,
    /** * Used to store NSDate elements in the format <i>yyyy-MM-dd HH:mm:ss:SSS</i>. Its string equivalent is <b>TEXT</b>. */
    NSFNanoTypeDate,
    /** * Used to store NSNumber elements. Its string equivalent is <b>REAL</b>. */
    NSFNanoTypeNumber,
    /** * Used to store NSNull elements. Its string equivalent is <b>NULL</b>. */
    NSFNanoTypeNULL,
    /** * Used to store NSURL elements. Its string equivalent is <b>URL</b>. */
    NSFNanoTypeURL
} NSFNanoDatatype;

/** * Returns the name of a NSFNanoDatatype datatype as a string. */
extern  NSString * NSFStringFromNanoDataType (NSFNanoDatatype aNanoDatatype);

/** * Obtains a NSFNanoDatatype datatype by name. */
extern  NSFNanoDatatype NSFNanoDatatypeFromString (NSString *aNanoDatatype);

/** * Types of backing store supported by NanoStore.
 * These values represent the storage options available when generating a NanoStore.
 @see NSFNanoStore
*/
typedef enum {
    /** * Create the transient backing store in RAM. Its contents are lost when the process exits. Fastest, uses more RAM. */
    NSFMemoryStoreType = 1,
    /** * Create a transient temporary backing store on disk. Its contents are lost when the process exits. Slower, uses less RAM than NSFMemoryStoreType. */
    NSFTemporaryStoreType,
    /** * Create a persistant backing store on disk. Its contents are lost when the process exits. Slower, uses less RAM than NSFMemoryStoreType. */
    NSFPersistentStoreType
} NSFNanoStoreType;

/** * Aggregate functions.
 * These functions represent the options available to obtain aggregate results quickly and efficiently.
 * @note Instead of sum(), total() is invoked instead because sum() will throw an "integer overflow" exception
 * if all inputs are integers or NULL and an integer overflow occurs at any point during the computation. On
 * the other hand, total() never throws an integer overflow.
 @see \link NSFNanoSearch::aggregateOperation:onAttribute: -(NSNumber *)aggregateOperation:(NSFAggregateFunctionType)theFunctionType onAttribute:(NSString *)theAttribute \endlink
 */

typedef enum {
    /** * It invokes the avg() function. */
    NSFAverage = 1,
    /** * It invokes the count() function. */
    NSFCount,
    /** * It invokes the max() function. */
    NSFMax,
    /** * It invokes the min() function. */
    NSFMin,
    /** * It invokes the total() function. See note above for additional information. */
    NSFTotal
} NSFAggregateFunctionType;

/** * Comparison options.
 * These values represent the options available to some of the classes’ search and comparison methods.
 @see NSFNanoPredicate, NSFNanoSearch
 */
typedef enum {
    /** * Equal to (case sensitive) */
    NSFEqualTo = 0,
    /** * Begins with (case sensitive) */
    NSFBeginsWith,
    /** * Contains (case sensitive) */
    NSFContains,
    /** * Ends with (case sensitive) */
    NSFEndsWith,
    
    /** * Equal to (case insensitive) */
    NSFInsensitiveEqualTo,
    /** * Begins with (case insensitive) */
    NSFInsensitiveBeginsWith,
    /** * Contains (case insensitive) */
    NSFInsensitiveContains,
    /** * Ends with (case insensitive) */
    NSFInsensitiveEndsWith,
    
    /** * Greater Ththanan */
    NSFGreaterThan,
    /** * Less than */
    NSFLessThan,
    /** * Not Equal to from */
    NSFNotEqualTo
} NSFMatchType;

/** * Column types for the Attributes table.
 * These values represent the columns available used for searching.
 @see NSFNanoPredicate
 */
typedef enum {
    /** * The key column. */
    NSFKeyColumn = 1,
    /** * The attribute column. */
    NSFAttributeColumn,
    /** * The value column. */
    NSFValueColumn
} NSFTableColumnType;

/** * Comparison criteria operators.
 * These values represent the operations available for concatenating predicates in an expression.
 @see NSFNanoExpression, NSFNanoPredicate
 */
typedef enum {
    /** * And */
    NSFAnd = 1,
    /** * Or */
    NSFOr,
} NSFOperator;

/** * Date comparison options.
 * These values represent the options available when searching and comparing dates.
 @see NSFNanoSearch, NSFNanoPredicate
 */
typedef enum {
    /** * Before the specified date */
    NSFBeforeDate = 1,
    /** * On the exact date */
    NSFOnDate,
    /** * After the specified date */
    NSFAfterDate
} NSFDateMatchType;

/** * Obtaining search results options.
 * These values represent the options used by the search mechanism to return results.
 @see NSFNanoSearch
 */
typedef enum {
    /** * Returns the objects. */
    NSFReturnObjects = 1,
    /** * Returns the keys */
    NSFReturnKeys,
} NSFReturnType;

/** * Caching mechanism options.
 * These values represent the options used by the search mechanism to cache results.
 @see NSFNanoEngine
 */
typedef enum {
    /** * Load data at as soon as it's available. Uses more memory, but data is available quicker. */
    CacheAllData = 1,
    /** * Loads data lazily. First access to data is slow because it retrieves it from disk, but is faster on subsequent requests because the data already exists in memory. */
    CacheDataOnDemand,
    /** * Don't cache data. Slowest mode, uses less memory because it retrieves data from disk every time it's needed. */
    DoNotCacheData,
} NSFCacheMethod;

/** * Text encoding options.
 * The following constants are provided by SQLite as possible string encodings.
 @see NSFNanoEngine
 */
typedef enum {
    /** * An 8-bit representation of Unicode characters. */
    NSFEncodingUTF8 = 1,
    /** * A 16-bit representation of Unicode characters. */
    NSFEncodingUTF16,
    /** * The encoding representation could not be determined. */
    NSFEncodingUnknown
} NSFEncodingType;

/** * Synchronous options.
 * These values represent the options used to manipulate the synchronous flag. In NSFNanoEngine it's obtained via
 * \link NSFNanoEngine::setSynchronousMode: - (void)setSynchronousMode:(NSFSynchronousMode)theSynchronousMode \endlink

 @see NSFNanoStore, NSFNanoEngine
 */
typedef enum {
    /** * SQLite continues without pausing as soon as it has handed data off to the operating system.
     If the application running SQLite crashes, the data will be safe, but the database might become corrupted if
     the operating system crashes or the computer loses power before that data has been written to the disk surface.
     On the other hand, some operations are as much as 50 or more times faster with synchronous OFF. */
    SynchronousModeOff = 0,
    /** * SQLite will still pause at the most critical moments, but less often than in FULL mode.
     There is a very small (though non-zero) chance that a power failure at just the wrong time could corrupt the database
     in NORMAL mode. But in practice, you are more likely to suffer a catastrophic disk failure or some other unrecoverable
     hardware fault. */
    SynchronousModeNormal,
    /** * SQLite will pause at critical moments to make sure that data has actually been written to
     the disk surface before continuing. This ensures that if the operating system crashes or if there is a power failure,
     the database will be uncorrupted after rebooting. FULL synchronous is very safe, but it is also slower. */
    SynchronousModeFull,
} NSFSynchronousMode;

/** * Temporary files location options.
 * These values represent the options used by SQLite to create the temporary files it creates.
 @see NSFNanoEngine
 */
typedef enum {
    /** * When temp_store is DEFAULT (0), the compile-time C preprocessor macro SQLITE_TEMP_STORE is used to determine
     where temporary tables and indices are stored. */
    TempStoreModeDefault = 0,
    /** * When temp_store is FILE (1) temporary tables and indices are stored in a file. The temp_store_directory pragma
     can be used to specify the directory containing temporary files when FILE is specified. When the temp_store setting is changed,
     all existing temporary tables, indices, triggers, and views are immediately deleted. */
    TempStoreModeFile,
    /** * When temp_store is MEMORY (2) temporary tables and indices are kept in as if they were pure in-memory databases memory. */
    TempStoreModeMemory,
} NSFTempStoreMode;

/** * Journal mode.
 * These values represent the options used by SQLite to the the journal mode for databases associated with the current database connection.
 @note Note that the journal_mode for an in-memory database is either MEMORY or OFF and can not be changed to a different value. An attempt to change
 the journal_mode of an in-memory database to any setting other than MEMORY or OFF is ignored. Note also that the journal_mode cannot be changed
 while a transaction is active.
 @see NSFNanoEngine
 */
typedef enum {
    /** * The DELETE journaling mode is the normal behavior. In the DELETE mode, the rollback journal is deleted at the conclusion
     of each transaction. Indeed, the delete operation is the action that causes the transaction to commit. (See the document titled
     Atomic Commit In SQLite for additional detail.) */
    JournalModeDelete = 0,
    /** * The TRUNCATE journaling mode commits transactions by truncating the rollback journal to zero-length instead of deleting it.
     On many systems, truncating a file is much faster than deleting the file since the containing directory does not need to be changed. */
    JournalModeTruncate,
    /** * The PERSIST journaling mode prevents the rollback journal from being deleted at the end of each transaction. Instead, the header
     of the journal is overwritten with zeros. This will prevent other database connections from rolling the journal back. The PERSIST
     journaling mode is useful as an optimization on platforms where deleting or truncating a file is much more expensive than overwriting
     the first block of a file with zeros. */
    JournalModePersist,
    /** * The MEMORY journaling mode stores the rollback journal in volatile RAM. This saves disk I/O but at the expense of database safety
     and integrity. If the application using SQLite crashes in the middle of a transaction when the MEMORY journaling mode is set, then
     the database file will very likely go corrupt. */
    JournalModeMemory,
    /** * The WAL journaling mode uses a write-ahead log instead of a rollback journal to implement transactions. The WAL journaling mode is
     persistent; after being set it stays in effect across multiple database connections and after closing and reopening the database. A database
     in WAL journaling mode can only be accessed by SQLite version 3.7.0 or later. */
    JournalModeWAL,
    /** * The OFF journaling mode disables the rollback journal completely. No rollback journal is ever created and hence there is never a
     rollback journal to delete. The OFF journaling mode disables the atomic commit and rollback capabilities of SQLite. The ROLLBACK command
     no longer works; it behaves in an undefined way. Applications must avoid using the ROLLBACK command when the journal mode is OFF.
     If the application crashes in the middle of a transaction when the OFF journaling mode is set, then the database file will very likely go corrupt. */
    JournalModeOFF
} NSFJournalModeMode;

/** * Memory-backed document store descriptor.
 * This value represents the descriptor used by NanoStore to identify memory-backed document stores. In NSFNanoStore is available via
 * \link NSFNanoStore::filePath - (NSString *)filePath \endlink (assuming the document store was
 * created as a memory-backed document store). In NSFNanoEngine, it's available via its <i>path</i> property.
 @see NSFNanoStore, NSFNanoEngine
 */
extern NSString * const NSFMemoryDatabase;

/** * Temporary store descriptor.
 * This value represents the descriptor used by NanoStore to identify temporary document stores. In NSFNanoStore is available via
 * \link NSFNanoStore::filePath - (NSString *)filePath \endlink (assuming the document store was
 * created as a temporary document store). In NSFNanoEngine, it's available via its \link NSFNanoEngine::path - (NSString *)path \endlink property.
 @see NSFNanoStore, NSFNanoEngine
 */
extern NSString * const NSFTemporaryDatabase;

/** * NanoStore's error code. This value is used by NanoStore when reporting errors.
 */
extern NSInteger const NSFNanoStoreErrorKey;

/** * Exception used when an unexpected parameter has been detected. */
extern NSString * const NSFUnexpectedParameterException;
/** * Exception used when a non-confirming NSFNanoObjectProtocol object has been detected. */
extern NSString * const NSFNonConformingNanoObjectProtocolException;
/** * Exception used when a NSFNanoObjectProtocol object is not behaving properly (i.e its <i>key</i> property does not return a correct value). */
extern NSString * const NSFNanoObjectBehaviorException;
/** * Exception used when a problem occurs while manipulating the document store
 * (adding, updating, deleting, opening a transaction, commit, etc.).
 */
extern NSString * const NSFNanoStoreUnableToManipulateStoreException;