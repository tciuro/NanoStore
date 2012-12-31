/*
     NSFNanoStore.h
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

/*! @file NSFNanoStore.h
 @brief The document store is where the objects get saved. It can be file-based (permanent of temporary) or memory-backed.
 */

/** @class NSFNanoStore
 * The document store is where the objects get saved. It can be file-based (permanent of temporary) or memory-backed.
 *
 * @details <b>Example:</b>
 @code
 // Instantiate a NanoStore and open it
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Add some data to the document store
 NSDictionary *info = ...;
 NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:info];
 [nanoStore addObject:object error:nil];
 
 // Return all objects via NSFNanoSearch
 NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
 
 // Return the keys of all objects
 NSArray *keys = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
 
 // Search one or more objects with a series of keys via NSFNanoStore
 NSArray *objects = [nanoStore objectsWithKeysInArray:[NSArray arrayWithObject:@"ABC-123"]];
 
 // Search an object with a given key via NSFNanoSearch
 [search setKey:@"ABC-123"];
 objects = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
 
 // Remove an object from the document store
 [nanoStore removeObject:object error:nil];
 
 // Close the document store
 [nanoStore closeWithError:nil];
 @endcode
 */

#import <Foundation/Foundation.h>

#import <sqlite3.h>

@class NSFNanoEngine, NSFNanoResult, NSFNanoBag, NSFNanoSortDescriptor;

@interface NSFNanoStore : NSObject

/** * A reference to the engine used by the document store, which contains a reference to the SQLite database. */
@property (nonatomic, strong, readonly) NSFNanoEngine *nanoStoreEngine;
/** * The type of engine mode used by NanoStore to process data in the document store.
 The mode can be one of two options: <i>NSFEngineProcessingDefaultMode</i> and <i>NSFEngineProcessingFastMode</i>. See <i>NSFEngineProcessingMode</i>
 to learn more about how these options affect the engine behavior.
 
 In default mode, the pragmas are set as follows:
 
 - PRAGMA fullfsync = OFF;
 - PRAGMA synchronous = FULL;
 - PRAGMA journal_mode = DELETE;
 - PRAGMA temp_store = DEFAULT;
 
 In fast mode, the pragmas are set to:
 
 - PRAGMA fullfsync = OFF;
 - PRAGMA synchronous = OFF;
 - PRAGMA journal_mode = MEMORY;
 - PRAGMA temp_store = MEMORY;
 
 @note Set this property before you open the document store.
 @see - (BOOL)openWithError:(out NSError **)outError;
 */
@property (nonatomic, assign, readwrite) NSFEngineProcessingMode nanoEngineProcessingMode;
/** * Number of iterations that will trigger an automatic save. */
@property (nonatomic, assign, readwrite) NSUInteger saveInterval;
/** * Whether there are objects that haven't been saved to the store. */
@property (nonatomic, readonly) BOOL hasUnsavedChanges;

/** @name Creating and Initializing NanoStore
 */

//@{

/** * Creates and returns a document store of a specific type at a given file path.
 * @param theType the type of document store that will be created.
 * @param thePath the file path where the document store will be created. Can be nil (see warning for additional info).
 * @return A document store upon success, nil otherwise.
 * @note
 * To manipulate the document store, you must first open it. If you don't need to configure settings for the document store, you can use
 * \link createAndOpenStoreWithType:path:error: + (NSFNanoStore *)createAndOpenStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath error:(out NSError **)outError \endlink instead.
 * @warning
 * The path is only meaningful for document stores of type \link NSFGlobals::NSFPersistentStoreType NSFPersistentStoreType \endlink. It must not be nil.
 * @throws NSFUnexpectedParameterException is thrown if the file path is nil or empty and the type is set to @ref NSFPersistentStoreType "NSFPersistentStoreType".
 * @see \link openWithError: - (BOOL)openWithError:(out NSError **)outError \endlink
 * @see \link createAndOpenStoreWithType:path:error: + (NSFNanoStore *)createAndOpenStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath error:(out NSError **)outError \endlink
 */

+ (NSFNanoStore *)createStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath;

/** * Creates, opens and returns a document store of a specific type at a given file path.
 * @param theType the type of document store that will be created.
 * @param thePath the file path where the document store will be created. Can be nil (see warning for additional info).
 * @param outError is used if an error occurs. May be NULL.
 * @return A document store upon success, nil otherwise.
 * @note
 * If you need to configure settings for the document store, you can use \link createStoreWithType:path: + (NSFNanoStore *)createStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath \endlink instead.
 * @warning
 * The path is only meaningful for document stores of type @ref NSFPersistentStoreType "NSFPersistentStoreType". It must not be nil.
 * @throws NSFUnexpectedParameterException is thrown if the file path is nil or empty and the type is set to @ref NSFPersistentStoreType "NSFPersistentStoreType".
 * @see \link openWithError: - (BOOL)openWithError:(out NSError **)outError \endlink
 * @see \link createStoreWithType:path: + (NSFNanoStore *)createStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath \endlink
 */

+ (NSFNanoStore *)createAndOpenStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath error:(out NSError **)outError;

/** * Initializes a newly allocated document store of a specific type at a given file path.
 * @param theType the type of document store that will be created.
 * @param thePath the file path where the document store will be created. Can be nil (see note for additional info).
 * @return A document store upon success, nil otherwise.
 * @note
 * To manipulate the document store, you must first open it. If you don't need to configure settings for the document store, you can use
 * \link createAndOpenStoreWithType:path:error: + (NSFNanoStore *)createAndOpenStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath error:(out NSError **)outError \endlink instead.
 * @warning
 * The path is only meaningful for document stores of type @ref NSFPersistentStoreType "NSFPersistentStoreType". It must not be nil.
 * @throws NSFUnexpectedParameterException is thrown if the file path is nil and the type is set to @ref NSFPersistentStoreType "NSFPersistentStoreType".
 * @see \link openWithError: - (BOOL)openWithError:(out NSError **)outError \endlink
 * @see \link createAndOpenStoreWithType:path:error: + (NSFNanoStore *)createAndOpenStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath error:(out NSError **)outError \endlink
 */

- (id)initStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath;

//@}

/** @name Opening and Closing
 */

//@{

/** * Opens the document store, making it ready for manipulation.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @note The document store needs to be opened only after opening a document store via
 * \link createStoreWithType:path: + (NSFNanoStore *)createStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath\endlink.
 * The property nanoEngineProcessingMode allows to set the type of engine mode used by NanoStore to process data in the document store. Set this property before you open the document store.
 * @see \link createStoreWithType:path: + (NSFNanoStore *)createStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath \endlink
 */

- (BOOL)openWithError:(out NSError **)outError;

/** * Closes the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @see \link isClosed - (BOOL)isClosed \endlink
 */

- (BOOL)closeWithError:(out NSError **)outError;

//@}

/** @name Accessors
 */

//@{

/** * Location where the document store is found.
 * @note If the document store is file-based, its path will be returned. If it's a memory-backed document store, \link :Globals::NSFMemoryDatabase NSFMemoryDatabase \endlink will be returned instead.
 */

- (NSString *)filePath;

/** * Checks whether the document store is closed or open.
 * @see \link close - (void)close \endlink
 */

- (BOOL)isClosed;

//@}

/** @name Adding and Removing Objects
 */

//@{

/** * Adds an \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant object to the document store.
 * @param theObject is added to the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @warning This value cannot be nil and it must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @throws NSFNonConformingNanoObjectProtocolException is thrown if the object is non-\link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink compliant.
 * @see \link addObjectsFromArray:error: - (BOOL)addObjectsFromArray:(NSArray *)theObjects error:(out NSError **)outError \endlink
 */

- (BOOL)addObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError;

/** * Adds a series of \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant objects to the document store.
 * @param theObjects is an array of objects to be added to the document store. The objects must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @warning The objects of the array must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @throws NSFNonConformingNanoObjectProtocolException is thrown if the object is non-\link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink compliant.
 * @see \link addObject:error: - (BOOL)addObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError \endlink
 */

- (BOOL)addObjectsFromArray:(NSArray *)theObjects error:(out NSError **)outError;

/** * Removes an object from the document store.
 * @param theObject the object to be removed from the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @warning The objects of the array must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @see \link removeObjectsWithKeysInArray:error: - (BOOL)removeObjectsWithKeysInArray:(NSArray *)theKeys error:(out NSError **)outError \endlink
 * @see \link removeObjectsInArray:error: - (BOOL)removeObjectsInArray:(NSArray *)theObjects error:(out NSError **)outError \endlink
 * @see \link removeAllObjectsFromStoreAndReturnError: - (BOOL)removeAllObjectsFromStoreAndReturnError:(out NSError **)outError \endlink
 */

- (BOOL)removeObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError;

/** * Removes the list of objects with the specified keys from the document store.
 * @param theKeys the list of keys to be removed from the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @warning The objects of the array must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @see \link removeObject:error: - (BOOL)removeObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError \endlink
 * @see \link removeObjectsInArray:error: - (BOOL)removeObjectsInArray:(NSArray *)theObjects error:(out NSError **)outError \endlink
 * @see \link removeAllObjectsFromStoreAndReturnError: - (BOOL)removeAllObjectsFromStoreAndReturnError:(out NSError **)outError \endlink
 */

- (BOOL)removeObjectsWithKeysInArray:(NSArray *)theKeys error:(out NSError **)outError;

/** * Removes the list of objects from the document store.
 * @param theObjects the list of objects to be removed from the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @warning The objects of the array must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @see \link removeObject:error: - (BOOL)removeObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError \endlink
 * @see \link removeObjectsWithKeysInArray:error: - (BOOL)removeObjectsWithKeysInArray:(NSArray *)theKeys error:(out NSError **)outError \endlink
 * @see \link removeAllObjectsFromStoreAndReturnError: - (BOOL)removeAllObjectsFromStoreAndReturnError:(out NSError **)outError \endlink
 */

- (BOOL)removeObjectsInArray:(NSArray *)theObjects error:(out NSError **)outError;

/** * Removes all objects from the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @note Please note that the unoccupied space will not be reclaimed, so after clearing the cache use \link compactStoreAndReturnError: - (BOOL)compactStoreAndReturnError:(out NSError **)outError \endlink
 * if you want to decrease the database file size.
 * @see \link removeObject:error: - (BOOL)removeObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError \endlink
 * @see \link removeObjectsWithKeysInArray:error: - (BOOL)removeObjectsWithKeysInArray:(NSArray *)theKeys error:(out NSError **)outError \endlink
 * @see \link removeObjectsInArray:error: - (BOOL)removeObjectsInArray:(NSArray *)theObjects error:(out NSError **)outError \endlink
 */

- (BOOL)removeAllObjectsFromStoreAndReturnError:(out NSError **)outError;

//@}

/** @name Searching and Gathering Data
 */

//@{

/** * Returns a new array containing the bags found in the document store.
 * @returns An array with the bags found in the document store.
 * @see \link bagsWithKeysInArray: - (NSArray *)bagsWithKeysInArray:(NSArray *)theKeys \endlink
 * @see \link bagsContainingObjectWithKey: - (NSArray *)bagsContainingObjectWithKey:(NSString *)theKey \endlink
 */

- (NSArray *)bags;

/** * Retrieves the bag associated with the specified name.
 * @param theName the name of the bag.
 * @returns The bag that matches the specified name, nil otherwise.
 * @note Check properties savedObjects, unsavedObjects and removedObjects to find out the current state of the bag.
 */

- (NSFNanoBag *)bagWithName:(NSString *)theName;

/** * Retrieves all bags associated with the specified name.
 * @param theName the name of the bag.
 * @returns The bags that match the specified name, an empty array otherwise.
 */

- (NSArray *)bagsWithName:(NSString *)theName;

/** * Returns a new array containing the bags found in the document store matching the specified list of keys.
 * @param theKeys the list of bag keys.
 * @returns An array with the bags that match the specified list of keys.
 * @see \link bags - (NSArray *)bags \endlink
 * @see \link bagsContainingObjectWithKey: - (NSArray *)bagsContainingObjectWithKey:(NSString *)theKey \endlink
 */

- (NSArray *)bagsWithKeysInArray:(NSArray *)theKeys;

/** * Returns a new array containing the bags found in the document store which contain the object specified by the key.
 * @param theKey the key of the object.
 * @returns An array with the bags that contain the object matching the specified key.
 * @see \link bags - (NSArray *)bags \endlink
 * @see \link bagsWithKeysInArray: - (NSArray *)bagsWithKeysInArray:(NSArray *)theKeys \endlink
 */

- (NSArray *)bagsContainingObjectWithKey:(NSString *)theKey;

/** * Returns a new array containing the objects found in the document store matching the specified list of keys.
 * @param theKeys the list of \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant object keys.
 * @returns An array with the objects matching the specified list of keys.
 * @note The keys can belong to any object class: NSFNanoObject, NSFNanoBag or any \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant object.
 */

- (NSArray *)objectsWithKeysInArray:(NSArray *)theKeys;

/** * Returns a new array containing the objects classes in the document store.
 * @returns An array of the class names found in the document store.
 * @note The classes can be NSFNanoObject, NSFNanoBag or any \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant object.
 */

- (NSArray *)allObjectClasses;

/** * Returns an array containing the objects in the document store which match a specific class name.
 * @param theClassName the name of the class that will be used for searching. Cannot be NULL.
 * @returns An array of objects of the specified class name.
 * @note The classes can be NSFNanoObject, NSFNanoBag or any \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant object.
 * @throws NSFUnexpectedParameterException is thrown if the class name is nil or empty.
 */

- (NSArray *)objectsOfClassNamed:(NSString *)theClassName;

/** * Returns a sorted array containing the objects in the document store which match a specific class name.
 * @param theClassName the name of the class that will be used for searching. Cannot be NULL.
 * @param theSortDescriptors the array of descriptors used to sort the array. May be NULL.
 * @returns An array of objects of the specified class name sorted if the sort descriptor was specified.
 * @note The classes can be NSFNanoObject, NSFNanoBag or any \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant object.
 * @throws NSFUnexpectedParameterException is thrown if the class name is nil or empty.
 */

- (NSArray *)objectsOfClassNamed:(NSString *)theClassName usingSortDescriptors:(NSArray *)theSortDescriptors;

/** * Returns the number of objects in the document store which match a specific class name.
 * @param theClassName the name of the class that will be used for searching. Cannot be NULL.
 * @returns The count of objects of the specified class name.
 * @note The classes can be NSFNanoObject, NSFNanoBag or any \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant object.
 * @throws NSFUnexpectedParameterException is thrown if the class name is nil or empty.
 */

- (long long)countOfObjectsOfClassNamed:(NSString *)theClassName;

//@}

/** @name Saving and Maintenance
 */

//@{

/** * Saves the uncommitted changes to the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @note After storing several objects and depending on the save interval, some objects could be left in the cache in an unsaved state.
 * Therefore, it's always a good idea to call \link saveStoreAndReturnError: - (BOOL)saveStoreAndReturnError:(out NSError **)outError \endlink
 * @see \link discardUnsavedChanges - (void)discardUnsavedChanges \endlink
 */

- (BOOL)saveStoreAndReturnError:(out NSError **)outError;

/** * Discards the uncommitted changes that were added to the document store.
 * @see \link saveStoreAndReturnError: - (BOOL)saveStoreAndReturnError:(out NSError **)outError \endlink
 */

- (void)discardUnsavedChanges;

/** * Compact the database file size.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 */

- (BOOL)compactStoreAndReturnError:(out NSError **)outError;

/** * Remove all indexes from the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @note Clearing the indexes could speed up document store manipulations (insertions, updates and deletions).
 * @see \link rebuildIndexesAndReturnError: - (BOOL)rebuildIndexesAndReturnError:(out NSError **)outError \endlink
 */

- (BOOL)clearIndexesAndReturnError:(out NSError **)outError;

/** * Recreate all indexes from the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @note Rebuilding the indexes recreates the indexes previously removed with \link clearIndexesAndReturnError: - (BOOL)clearIndexesAndReturnError:(out NSError **)outError \endlink.
 * @see \link clearIndexesAndReturnError: - (BOOL)clearIndexesAndReturnError:(out NSError **)outError \endlink
 */

- (BOOL)rebuildIndexesAndReturnError:(out NSError **)outError;

/** * Makes a copy of the document store to a different location and optionally compacts it to its minimum size.
 * @param thePath is the location where the document store should be copied to.
 * @param shouldCompact is used to flag whether the document store should be compacted.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @note Works with both, file-based and memory-backed document stores.
 * @see \link clearIndexesAndReturnError: - (BOOL)clearIndexesAndReturnError:(out NSError **)outError \endlink
 */

- (BOOL)saveStoreToDirectoryAtPath:(NSString *)thePath compactDatabase:(BOOL)shouldCompact error:(out NSError **)outError;

//@}

/** @name Transactions
 */

//@{

/** * Start a transaction.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @attention Use this method instead of the ones provided by NSFNanoEngine.
 * @see \link clearIndexesAndReturnError: - (BOOL)clearIndexesAndReturnError:(out NSError **)outError \endlink
 * @see \link commitTransactionAndReturnError: - (BOOL)commitTransactionAndReturnError:(out NSError **)outError \endlink
 * @see \link rollbackTransactionAndReturnError: - (BOOL)rollbackTransactionAndReturnError:(out NSError **)outError \endlink
 */

- (BOOL)beginTransactionAndReturnError:(out NSError **)outError;

/** * Commit a transaction.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @attention Use this method instead of the ones provided by NSFNanoEngine.
 * @see \link rebuildIndexesAndReturnError: - (BOOL)rebuildIndexesAndReturnError:(out NSError **)outError \endlink
 * @see \link beginTransactionAndReturnError: - (BOOL)beginTransactionAndReturnError:(out NSError **)outError \endlink
 * @see \link rollbackTransactionAndReturnError: - (BOOL)rollbackTransactionAndReturnError:(out NSError **)outError \endlink
 */

- (BOOL)commitTransactionAndReturnError:(out NSError **)outError;

/** * Rollback a transaction.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @attention Use this method instead of the ones provided by NSFNanoEngine.
 * @see \link rebuildIndexesAndReturnError: - (BOOL)rebuildIndexesAndReturnError:(out NSError **)outError \endlink
 * @see \link beginTransactionAndReturnError: - (BOOL)beginTransactionAndReturnError:(out NSError **)outError \endlink
 * @see \link commitTransactionAndReturnError: - (BOOL)commitTransactionAndReturnError:(out NSError **)outError \endlink
 */

- (BOOL)rollbackTransactionAndReturnError:(out NSError **)outError;

//@}

/** @name Miscellaneous
 */

//@{

/** * Returns a string representation of the store.
 * @note Check properties nanoEngineProcessingMode and saveInterval to find out the current state of the object.
 */

- (NSString *)description;

/** Returns a JSON representation of the store.
 */

- (NSString *)JSONDescription;

//@}

@end