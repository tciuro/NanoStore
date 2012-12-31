/*
     NSFNanoBag.h
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

/*! @file NSFNanoBag.h
 @brief A bag is a loose collection of objects stored in a document store.
 */

/** @class NSFNanoBag
 * A bag is a loose collection of objects stored in a document store.
 *
 * @note
 * The objects must conform to the \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink. For your convenience, NanoStore provides you with NSFNanoObject, which is the standard
 * way of storing and retrieving objects from/to a bag.
 *
 * @par
 * It's more efficient to make your storage objects \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant, thus eliminating the need to convert your objects to/from
 * objects of type NSFNanoObject.
 *
 * @details <b>Example:</b>
 @code
 // Instantiate a NanoStore and open it
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 [nanoStore removeAllObjectsFromStoreAndReturnError:nil];
 
 // Add some data to a bag
 NSFNanoBag *bag = [NSFNanoBag bag];
 NSDictionary *info = ...;
 NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:info];
 NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:info];
 NSFNanoObject *obj3 = [NSFNanoObject nanoObjectWithDictionary:info];
 [bag addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, obj3, nil] error:nil];
 
 // Add the bag and its objects to the document store
 [nanoStore addObject:bag error:nil];
 
 // Obtain the bags from the document store
 NSArray *bags = [nanoStore bags];
 
 // Close the document store
 [nanoStore closeWithError:nil];
 @endcode
*/

#import "NSFNanoObjectProtocol.h"

@interface NSFNanoBag : NSObject <NSFNanoObjectProtocol, NSCopying>

/** * The store where the bag is located.  */
@property (nonatomic, weak, readonly) NSFNanoStore *store;
/** * The name of the bag.  */
@property (nonatomic, copy, readwrite) NSString *name;
/** * The UUID of the bag.  */
@property (nonatomic, copy, readonly) NSString *key;
/** * Dictionary of NSString (key) and id<NSFNanoObjectProtocol> (value). */
@property (nonatomic, readonly) NSDictionary *savedObjects;
/** * Dictionary of NSString (key) and id<NSFNanoObjectProtocol> (value). */
@property (nonatomic, readonly) NSDictionary *unsavedObjects;
/** * Dictionary of NSString (key) and id<NSFNanoObjectProtocol> (value). */
@property (nonatomic, readonly) NSDictionary *removedObjects;
/** * To determine whether the bag has uncommited changes.  */
@property (nonatomic, assign, readonly) BOOL hasUnsavedChanges;

/** @name Creating and Initializing Bags
 */

//@{

/** * Creates and returns an empty bag.
 * @return An empty bag upon success, nil otherwise.
 */

+ (NSFNanoBag *)bag;

/** * Creates and returns a bag adding to it the objects contained in the given array.
 * @param theObjects an array of objects conforming to the \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink.
 * @return A bag only containing the objects with conform to the \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink upon success, nil otherwise.
 * @throws NSFUnexpectedParameterException is thrown if theObjects is nil.
 * @warning If theObjects is nil, an NSFUnexpectedParameterException will be thrown. Use + bag; instead.
 * @see \link initBagWithNanoObjects: - (NSFNanoBag*)initBagWithNanoObjects:(NSArray *)theObjects \endlink
 */

+ (NSFNanoBag *)bagWithObjects:(NSArray *)theObjects;

/** * Creates and returns an empty bag with the specified name
 * @param theName the name of the bag. Can be nil.
 * @return An empty bag upon success, nil otherwise.
 */

+ bagWithName:(NSString *)theName;

/** * Creates and returns a bag with the specified name adding to it the objects contained in the given array.
 * @param theName the name of the bag. Can be nil.
 * @param theObjects is a required array of objects conforming to the \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink.
 * @return A bag only containing the objects with conform to the \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink upon success, nil otherwise.
 * @throws NSFUnexpectedParameterException is thrown if theObjects is nil.
 * @warning If theObjects is nil, an NSFUnexpectedParameterException will be thrown.
 * @see \link initBagWithNanoObjects: - (NSFNanoBag*)initBagWithNanoObjects:(NSArray *)theObjects \endlink
 */

+ bagWithName:(NSString *)theName andObjects:(NSArray *)theObjects;

/** * Initializes a newly allocated bag with the specified name adding to it the objects contained in the given array.
 * @param theName the name of the bag. Can be nil.
 * @param theObjects is a required array of objects conforming to the \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink.
 * @return A bag only containing the objects with conform to the \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink upon success, nil otherwise.
 * @throws NSFUnexpectedParameterException is thrown if theObjects is nil.
 * @warning If theObjects is nil, an NSFUnexpectedParameterException will be thrown.
 * @see \link bagWithObjects: + (NSFNanoBag*)bagWithObjects:(NSArray *)theObjects \endlink
 */

- (id)initBagWithName:(NSString *)theName andObjects:(NSArray *)someObjects;

//@}

/** @name Adding and Removing Objects
 */

//@{

/** * Adds an \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant object to the bag.
 * @param theObject is added to the bag.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @warning This value cannot be nil and it must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @throws NSFNonConformingNanoObjectProtocolException is thrown if the object is non-\link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink compliant.
 * @see \link addObjectsFromArray:error: - (BOOL)addObjectsFromArray:(NSArray *)theObjects error:(out NSError **)outError \endlink
 */

- (BOOL)addObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError;

/** * Adds a series of \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant objects to the bag.
 * @param theObjects is an array of objects to be added to the bag. The objects must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @warning The objects of the array must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @throws NSFNonConformingNanoObjectProtocolException is thrown if the object is non-\link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink compliant.
 * @see \link addObject:error: - (BOOL)addObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError \endlink
 */

- (BOOL)addObjectsFromArray:(NSArray *)theObjects error:(out NSError **)outError;

/** * Removes the specified object from the bag.
 * @param theObject the object to be removed from the bag.
 * @warning The object must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @see \link removeObjectsInArray: - (void)removeObjectsInArray:(NSArray *)theObjects \endlink
 * @see \link removeObjectWithKey: - (void)removeObjectWithKey:(NSString *)theObjectKey \endlink
 * @see \link removeObjectsWithKeysInArray: - (void)removeObjectsWithKeysInArray:(NSArray *)theKeys \endlink
 * @see \link removeAllObjects - (void)removeAllObjects \endlink
 */

- (void)removeObject:(id <NSFNanoObjectProtocol>)theObject;

/** * Empties the bag of all its elements.
 * @see \link removeObject: - (void)removeObject:(id <NSFNanoObjectProtocol>)theObject \endlink
 * @see \link removeObjectsInArray: - (void)removeObjectsInArray:(NSArray *)theObjects \endlink
 * @see \link removeObjectWithKey: - (void)removeObjectWithKey:(NSString *)theObjectKey \endlink
 * @see \link removeObjectsWithKeysInArray: - (void)removeObjectsWithKeysInArray:(NSArray *)theKeys \endlink
 */

- (void)removeAllObjects;

/** * Removes the list of objects from the bag.
 * @param theObjects the list of objects to be removed from the bag.
 * @warning The objects of the array must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @see \link removeObject: - (void)removeObject:(id <NSFNanoObjectProtocol>)theObject \endlink
 * @see \link removeObjectWithKey: - (void)removeObjectWithKey:(NSString *)theObjectKey \endlink
 * @see \link removeObjectsWithKeysInArray: - (void)removeObjectsWithKeysInArray:(NSArray *)theKeys \endlink
 * @see \link removeAllObjects - (void)removeAllObjects \endlink
 */

- (void)removeObjectsInArray:(NSArray *)theObjects;

/** * Removes the object with a given key from the bag.
 * @param theObjectKey the key of the object to be removed from the bag.
 * @warning The object referenced by theObjectKey must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @see \link removeObject: - (void)removeObject:(id <NSFNanoObjectProtocol>)theObject \endlink
 * @see \link removeObjectsInArray: - (void)removeObjectsInArray:(NSArray *)theObjects \endlink
 * @see \link removeObjectsWithKeysInArray: - (void)removeObjectsWithKeysInArray:(NSArray *)theKeys \endlink
 * @see \link removeAllObjects - (void)removeAllObjects \endlink
 */

- (void)removeObjectWithKey:(NSString *)theObjectKey;

/** * Removes from the bag the objects specified by elements in a given array.
 * @param theKeys an array of objects specifying the keys to remove from the bag
 * @warning The objects referenced by theKeys must be \link NSFNanoObjectProtocol::initNanoObjectFromDictionaryRepresentation:forKey:store: NSFNanoObjectProtocol\endlink-compliant.
 * @see \link removeObject: - (void)removeObject:(id <NSFNanoObjectProtocol>)theObject \endlink
 * @see \link removeObjectsInArray: - (void)removeObjectsInArray:(NSArray *)theObjects \endlink
 * @see \link removeObjectWithKey: - (void)removeObjectWithKey:(NSString *)theObjectKey \endlink
 * @see \link removeAllObjects - (void)removeAllObjects \endlink
 */

- (void)removeObjectsWithKeysInArray:(NSArray *)theKeys;

//@}

/** @name Saving, Reloading and Undoing
 */

//@{

/** * Saves the bag and its contents. Also, saves all the changes made since the last save.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @note Check property hasUnsavedChanges to find out whether the bag has unsaved contents.
 * @see \link reloadBagWithError: - (BOOL)reloadBagWithError:(out NSError **)outError \endlink
 * @see \link undoChangesWithError: - (BOOL)undoChangesWithError:(out NSError **)outError \endlink
 */

- (BOOL)saveAndReturnError:(out NSError **)outError;

/** * Refreshes the bag to match the contents stored in the document store. The unsaved contents are preserved.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @note Check properties savedObjects, unsavedObjects and removedObjects to find out the current state of the bag.
 * @see \link saveAndReturnError: - (BOOL)saveAndReturnError:(out NSError **)outError \endlink
 * @see \link undoChangesWithError: - (BOOL)undoChangesWithError:(out NSError **)outError \endlink
 */

- (BOOL)reloadBagWithError:(out NSError **)outError;

/** * Discards the changes made in the bag.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 * @note Check properties savedObjects, unsavedObjects and removedObjects to find out the current state of the bag.
 * @see \link saveAndReturnError: - (BOOL)saveAndReturnError:(out NSError **)outError \endlink
 * @see \link reloadBagWithError: - (BOOL)reloadBagWithError:(out NSError **)outError \endlink
 */

- (BOOL)undoChangesWithError:(out NSError **)outError;

//@}

/** @name Inflating and Deflating
 */

//@{

/** * Inflates the bag by reconstructing the objects flattened with - (void)deflateBag;
 * @note Check properties savedObjects, unsavedObjects and removedObjects to find out the current state of the bag.
 * @see \link deflateBag - (void)deflateBag \endlink
 */

- (void)inflateBag;

/** * Releases memory by "flattening" the objects from the bag.
 * @note Check properties savedObjects, unsavedObjects and removedObjects to find out the current state of the bag.
 * @see \link inflateBag - (void)inflateBag \endlink
 */

- (void)deflateBag;

//@}

/** @name Miscellaneous
 */

//@{

/** * Returns the number of objects currently in the bag.
 * @return The number of objects currently in the bag.
 */

- (NSUInteger)count;

/** * Compares the receiving bag to another bag.
 * @param otherNanoBag is a bag.
 * @return YES if the contents of otherNanoBag are equal to the contents of the receiving bag, otherwise NO.
 */

- (BOOL)isEqualToNanoBag:(NSFNanoBag *)otherNanoBag;

/** * Returns a dictionary that contains the information stored in the bag.
 * @note Check properties savedObjects, unsavedObjects and removedObjects to find out the current state of the bag.
 * @see \link description - (NSString *)description \endlink
 */

- (NSDictionary *)dictionaryRepresentation;

/** * Returns a string representation of the bag.
 * @note Check properties savedObjects, unsavedObjects and removedObjects to find out the current state of the bag.
 */

- (NSString *)description;

/** Returns a JSON representation of the bag.
 * @note Check properties savedObjects, unsavedObjects and removedObjects to find out the current state of the bag.
 */

- (NSString *)JSONDescription;

//@}

@end