/*
     NSFNanoObject.h
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

/*! @file NSFNanoObject.h
 @brief A generic class that implements all the basic behavior required of a NanoStore object.
 */

/** @class NSFNanoObject
 The basic unit of data in NanoStore is called NanoObject. A NanoObject is any object which conforms to the NSFNanoObjectProtocol protocol.
 
 @section notaflatworld_sec It's not a flat World
 
 Most database solutions force the developer to think in a two-dimensional space (rows and columns), forcing the developer to plan the schema ahead of
 time. This situation is not ideal because in most cases schema refinements could be required, oftentimes impacting the code as well.
 
 NanoStore goes beyond that allowing the developer to store objects in their natural form. These objects must conform to the NSFNanoObjectProtocol
 protocol, providing NanoStore with the NSDictionary that will be stored. By using a dictionary data can be inspected very quickly, and it also allows the
 structure to be defined in a hierarchical fashion as well, due to the fact that it includes support for nested collections (of type NSDictionary and NSArray.)
 Each inner-object is indexed automatically, thus allowing to quickly find objects which contain a specific key and/or value.
 
 By default, NanoStore allows objects to be stored without any sense of relationship to other objects. This simple format, while powerful, is limited because
 the developer has to keep track of the relationships among objects. Some applications may need to relate objects, some of them perhaps of different nature or class
 type. This is exactly what NanoBag (represented by the NSFNanoBag class) does: it allows any object conforming to the NSFNanoObjectProtocol protocol to be
 added to the bag. By saving the bag with one single call, the new and/or modified are taken care of seamlessly.
 
 The NSFNanoBag API is rich, allowing the developer to add, remove, reload and undo its changes, deflate it (thus saving memory) and inflate it whenever it's
 required. In addition, it provides methods to obtain all bags, specific bags matching some keys, and bags containing a specific object
 (see NSFNanoStore for more information).
 
 <b>Structure of a NanoObject object</b>
 
 At its core, a NanoObject is nothing more than a wrapper around two properties:
 
 - A dictionary which contains the metadata (provided by the developer)
 - A key (UUID) that identifies the object (provided by NanoStore)
 
 The dictionary <i>must</i> be serializable, which means that only the following data types are allowed:
 
 - NSArray
 - NSDictionary
 - NSString
 - NSData (*)
 - NSDate
 - NSNumber
 
 (*) The data type NSData is allowed, but it will be excluded from the indexing process.
 
 To save and retrieve objects from the document store, NanoStore moves the data around by encapsulating it in NanoObjects. In order to store the objects in
 NanoStore the developer has three options:
 
 - Use the NSFNanoObject class directly
 - Expand your custom classes by inheriting from NSFNanoObject
 - Expand your custom classes by implementing the NSFNanoObjectProtocol protocol
 
 Regardless of the route you decide to take, NanoStore will be able to store and retrieve objects from the document store seamlessly. The beauty of this system is that
 NanoStore returns the object as it was stored, that is, instantiating an object of the class that was originally stored.
 
 @note
 If the document store is opened by another application that doesn't implement the object that was stored, NanoStore will instantiate a
 NSFNanoObject instead, thus allowing the app to retrieve the data seamlessly. If the object is then updated by this application, the original
 class name will be honored.
 
 <b>Example:</b>
 
 - App A stores an object of class <i>Car</i>.
 - App B retrieves the object, but since it doesn't know anything about the class <i>Car</i>, NanoStore returns a NSFNanoObject.
 - App B updates the object, perhaps adding a timestamp or additional information. NanoStore saves it as a <i>Car</i>, not as a NSFNanoObject.
 - App A retrieves the updated object as a <i>Car</i> object, in exactly the same format as it was originally stored.
 
 @section workingwithnanoobject_sec Working with a NanoObject
 
 There are three basic operations that NanoStore can perform with a NanoObject:
 
 - Add it to the document store
 - Update an existing object in the document store
 - Remove it from the document store
 
 To add an object, instantiate a \link NSFNanoObject::nanoObject NanoObject, \endlink populate it and add it to the document store.
 
 @details <b>Example:</b>
 @code
 // Instantiate a NanoStore and open it
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Generate an empty NanoObject
 NSFNanoObject *object = [NSFNanoObject nanoObject];
 
 // Add some data
 [object setObject:@"Doe" forKey:@"kLastName"];
 [object setObject:@"John" forKey:@"kFirstName"];
 [object setObject:[NSArray arrayWithObjects:@"jdoe@foo.com", @"jdoe@bar.com", nil] forKey:@"kEmails"];
 
 // Add it to the document store
 [nanoStore addObject:object error:nil];
 
 // Close the document store
 [nanoStore closeWithError:nil];
 @endcode
 
 Alternatively, you can instantiate a \link NSFNanoObject::nanoObject NanoObject \endlink providing a dictionary via \link NSFNanoObject::nanoObjectWithDictionary: + (NSFNanoObject*)nanoObjectWithDictionary:(NSDictionary *)theDictionary. \endlink
 NanoStore will assign a UUID automatically when the \link NSFNanoObject::nanoObjectWithDictionary: NanoObject \endlink
 is instantiated. This means that requesting the key from the \link NSFNanoObject::nanoObjectWithDictionary: NanoObject \endlink will return a valid UUID.
 The same holds true for objects that inherit from NSFNanoObject. However, classes that implement the NSFNanoObjectProtocol protocol should
 make sure they return a valid key via \link NSFNanoObjectProtocol::nanoObjectKey - (NSString *)nanoObjectKey \endlink
 
 @warning
 If an attempt is made to add or remove an object without a valid key, an exception of type \ref NSFGlobals::NSFNanoObjectBehaviorException
 "NSFNanoObjectBehaviorException" will be raised.
 
 To update an object, simply modify the object and add it to the document store. NanoStore will replace the existing object with the one being added.
 
 @details <b>Example:</b>
 @code
 // Instantiate and open a NanoStore
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Assuming the dictionary exists, instantiate a NanoObject
 NSDictionary *info = ...;
 NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:info];
 
 // Add the NanoObject to the document store
 [nanoStore addObject:object error:nil];
 
 // Update the NanoObject with new data
 [object setObject:@"foo" forKey:@"SomeKey"];
 
 // Update the NanoObject in the document store
 [nanoStore addObject:object error:nil];
 @endcode
 
 To remove an object, there are several options available. The most common methods are found in NSFNanoStore:
 
 - \link NSFNanoStore::removeObject:error: - (BOOL)removeObject:(id <NSFNanoObjectProtocol>)theObject error:(out NSError **)outError \endlink
 - \link NSFNanoStore::removeObjectsWithKeysInArray:error: - (BOOL)removeObjectsWithKeysInArray:(NSArray *)theKeys error:(out NSError **)outError \endlink
 - \link NSFNanoStore::removeObjectsInArray:error: - (BOOL)removeObjectsInArray:(NSArray *)theObjects error:(out NSError **)outError \endlink
 
 @details <b>Example:</b>
 @code
 // Instantiate and open a NanoStore
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Assuming the dictionary exists, instantiate a NanoObject
 NSDictionary *info = ...;
 NSFNanoObject *object = [NSFNanoObject nanoObjectWithDictionary:info];
 
 // Add the NanoObject to the document store
 [nanoStore addObject:object error:nil];
 
 // Remove the object
 [nanoStore removeObject:object error:nil];
 
 // ... or you could pass the key instead
 [nanoStore removeObjectsWithKeysInArray:[NSArray arrayWithObjects:[object nanoObjectKey], nil] error:nil];
 @endcode
 */

#import "NanoStore.h"

@interface NSFNanoObject : NSObject <NSFNanoObjectProtocol, NSCopying>

/** * The store where the object is saved.  */
@property (nonatomic, weak, readonly) NSFNanoStore *store;
/** * The UUID of the NanoObject.  */
@property (nonatomic, copy, readonly) NSString *key;
/** * The user-supplied information of the NanoObject.  */
@property (nonatomic, copy, readonly) NSDictionary *info;
/** * The class name used to store the NanoObject.  */
@property (nonatomic, copy, readonly) NSString *originalClassString;

/** @name Creating and Initializing a NanoObject
 */

//@{

/** * Creates and returns an empty NanoObject.
 * @return An empty NanoObject upon success, nil otherwise.
 */

+ (NSFNanoObject*)nanoObject;

/** * Creates and returns a NanoObject with the given dictionary.
 * @param theDictionary the information associated with the object. Must not be nil.
 * @return An initialized object upon success, nil otherwise.
 * @attention The dictionary must be serializable. For more information, please read the Property List Programming Guide.
 * @see \link initFromDictionaryRepresentation: - (id)initFromDictionaryRepresentation:(NSDictionary *)theDictionary \endlink
 */

+ (NSFNanoObject*)nanoObjectWithDictionary:(NSDictionary *)theDictionary;

/** * Creates and returns a NanoObject with the given dictionary and key.
 * @param theDictionary the information associated with the object. Must not be nil.
 * @param theKey the object key associated with the object. If nil, a new key will be assigned.
 * @return An initialized object upon success, nil otherwise.
 * @attention The dictionary must be serializable. For more information, please read the Property List Programming Guide.
 * @see \link initFromDictionaryRepresentation: - (id)initFromDictionaryRepresentation:(NSDictionary *)theDictionary \endlink
 */

+ (NSFNanoObject*)nanoObjectWithDictionary:(NSDictionary *)theDictionary key:(NSString *)theKey;

/** * Initializes a newly allocated NanoObject with the given dictionary.
 * @param theDictionary the information associated with the object. Must not be nil.
 * @return An initialized object upon success, nil otherwise.
 * @attention The dictionary must be serializable. For more information, please read the Property List Programming Guide.
 * @see \link nanoObjectWithDictionary: + (NSFNanoObject*)nanoObjectWithDictionary:(NSDictionary *)theDictionary \endlink
 */

- (id)initFromDictionaryRepresentation:(NSDictionary *)theDictionary;

/** * Initializes a newly allocated NanoObject with the given dictionary and key.
 * @param theDictionary the information associated with the object. Must not be nil.
 * @param theKey the object key associated with the object. If nil, a new key will be assigned.
 * @return An initialized object upon success, nil otherwise.
 * @attention The dictionary must be serializable. For more information, please read the Property List Programming Guide.
 */

- (id)initFromDictionaryRepresentation:(NSDictionary *)theDictionary key:(NSString *)theKey;

//@}

/** @name Setting and Removing Contents
 */

//@{

/** * Adds the entries from a dictionary to the NanoObject.
 * @param otherDictionary The dictionary from which to add entries.
*/

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary;

/** * Adds a given key-value pair to the NanoObject.
 * @param anObject the value for key. Must not be nil.
 * @param aKey the key for value. Must not be nil.
 * @note Raises an NSInvalidArgumentException if <i>aKey</i> or <i>anObject</i> is nil. If you need to represent a nil value in the dictionary, use NSNull.
 * @see \link removeObjectForKey: - (void)removeObjectForKey:(NSString *)aKey \endlink
 */

- (void)setObject:(id)anObject forKey:(NSString *)aKey;

/** * Returns the value associated with a given key.
 * @param aKey the key for value. Must not be nil.
 * @note Raises an NSInvalidArgumentException if <i>aKey</i> or <i>anObject</i> is nil. If you need to represent a nil value in the dictionary, use NSNull.
 * @see \link setObject:forKey: - (void)setObject:(id)anObject forKey:(NSString *)aKey \endlink
 */

- (id)objectForKey:(NSString *)aKey;

/** * Removes a given key and its associated value from the NanoObject.
 * @param aKey the key to remove. Must not be nil.
 * @note Does nothing if <i>aKey</i> does not exist.
 * @see \link setObject:forKey: - (void)setObject:(id)anObject forKey:(NSString *)aKey \endlink
 */

- (void)removeObjectForKey:(NSString *)aKey;

/** * Empties the NanoObject of its entries.
 * @see \link removeObjectForKey: - (void)removeObjectForKey:(NSString *)aKey \endlink
 * @see \link removeObjectsForKeys: - (void)removeObjectsForKeys:(NSArray *)keyArray \endlink
 */

- (void)removeAllObjects;

/** * Removes from the NanoObject entries specified by elements in a given array.
 * @param keyArray An array of objects specifying the keys to remove.
 * @note If a key in <i>keyArray</i> does not exist, the entry is ignored.
 * @see \link removeAllObjects - (void)removeAllObjects \endlink
 * @see \link removeObjectForKey: - (void)removeObjectForKey:(NSString *)aKey \endlink
 */

- (void)removeObjectsForKeys:(NSArray *)keyArray;

//@}

/** @name Miscellaneous
 */

//@{

/** * Compares the receiving NanoObject to another NanoObject.
 * @param otherNanoObject is a NanoObject.
 * @return YES if the contents of otherNanoObject are equal to the contents of the receiving NanoObject, otherwise NO.
 */

- (BOOL)isEqualToNanoObject:(NSFNanoObject *)otherNanoObject;

/** * Saves the uncommitted changes to the document store.
 * @param outError is used if an error occurs. May be NULL.
 * @return YES upon success, NO otherwise.
 */

- (BOOL)saveStoreAndReturnError:(out NSError **)outError;

/** * Returns a dictionary that contains the information stored in the object.
 * @note Check properties info and key to find out the current state of the object.
 * @see \link description - (NSString *)description \endlink
 */

- (NSDictionary *)dictionaryRepresentation;

/** * Returns a string representation of the nano object.
 */

- (NSString *)description;

/** Returns a JSON representation of the nano object.
 */

- (NSString *)JSONDescription;

//@}

@end