/*
     NanoStore.h
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

#import "NSFNanoObjectProtocol.h"
#import "NSFNanoObject.h"
#import "NSFNanoGlobals.h"
#import "NSFNanoStore.h"
#import "NSFNanoPredicate.h"
#import "NSFNanoExpression.h"
#import "NSFNanoSearch.h"
#import "NSFNanoSortDescriptor.h"
#import "NSFNanoResult.h"
#import "NSFNanoBag.h"
#import "NSFNanoEngine.h"
#import "NSFNanoGlobals.h"

/**
 @mainpage Welcome To NanoStore
 
 @section whatis_sec What is NanoStore?
 
 NanoStore is an open source, lightweight schema-less local key-value document store written in Objective-C for Mac OS X and iOS.
 
 Relational databases tend to have a rich understanding of the structure of your data, but requires some planing beforehand and some level of
 maintenance as well. NanoStore provides the flexibility that comes with key-value document stores, but still understands something about your data.
 Because the data is key-value based, it can be accessed quickly and can grow as much as needed... all without ever worrying about the schema.
 
 @section mainadv_sec Main advantages
 
 - No SQL knowledge required
 - Schema-less
 - Key-value based storage
 - Store your own custom objects
 - Bags, a free-form relational system
 - Fast, direct object manipulation
 - Dynamic queries
 - Full index support, inner-objects, embedded arrays and dictionaries
 - Convenience methods to access, manipulate and maintain SQLite databases
 - Full SQLite access available
 - Mac OS X Lion 10.7 and iOS 5 ready
 - iOS library runs on the device and simulator
 - ARC compliant
 
 @section latest_changes Latest changes
 v2.5 - January 1, 2013
 
 Starting with v2.5, the plist mechanism has been replaced with NSKeyedArchiver. There are several reasons for it: it's more compact, faster and uses less memory. Perhaps the most important reason is that it opens the possibility to store other data types.
 
 NSNull is now supported. Big thanks to Wanny (https://github.com/mrwanny) for taking the time to improve this section of NanoStore.
 
 @section installation_sec Installation
 
 Building NanoStore is very easy. Just follow these steps:
 
 - 1) Download NanoStore
 - 2) Open the NanoStore.xcodeproj file
 - 3) Select Universal > My Mac 64-bit or 32-bit from the Scheme popup
 - 4) Build (Command-B)
 
 Now you should have a new <i>Distribution</i> directory within the NanoStore project directory which contains the Universal static library (armv6/armv7/i386)
 as well as the header files. To add it in your project, do the following:
 
 - 1) Drag the Distribution directory to the Project Navigator panel
 - 2) Include #import "NanoStore.h" in your code
 
 @details <b>Example:</b>
 @code
 #import "NanoStore.h"
 
 @implementation MyDemoAppDelegate
 
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
 {
     // Override point for customization after application launch.
     // Instantiate a NanoStore and open it
 
     NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
     ...
 @endcode
 
 @note
 If you want to add a dependency between your project and NanoStore so that it gets automatically rebuilt when
 you update NanoStore, do the following (we'll assume your app is called "MyDemoApp"):
 
 - 1) Select the MyDemoApp project in the Project Navigator
 - 2) Select the MyDemoApp target
 - 3) Expand the Target Dependencies box
 - 4) Click "+" and add NanoStore
 
 @section howitworks_sec How does NanoStore work?
 
 The basic unit of data in NanoStore is called NanoObject. A NanoObject is any object which conforms to the NSFNanoObjectProtocol protocol.
 
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
 
 @section typesofdocumentstores Types of Document Stores

 There are three types of document stores available in NanoStore: in-memory, temporary and file-based. These document stores are defined by the \link NSFGlobals::NSFNanoStoreType NSFNanoStoreType \endlink type:
 
 - NSFMemoryStoreType: create the transient backing store in RAM. Its contents are lost when the process exits. Fastest, uses more RAM (*).
 - NSFTemporaryStoreType: create a transient temporary backing store on disk. Its contents are lost when the process exits. Slower, uses less RAM than NSFMemoryStoreType.
 - NSFPersistentStoreType:create a persistant backing store on disk. Slower, uses less RAM than NSFMemoryStoreType (*).
 
 @note
 Until the limit set by NSFNanoEngine's \link NSFNanoEngine::cacheSize - (NSUInteger)cacheSize \endlink has been reached, memory usage would be the same for in-memory store and on-disk store. When the size
 of the store grows beyond \link NSFNanoEngine::cacheSize - (NSUInteger)cacheSize \endlink in-memory stores start to consume more memory than on-disk ones, because it has nowhere to push pages out of the cache.
 
 Typically, most developers may want to create and open the document store. To do that, use NSFNanoStore's \link createAndOpenStoreWithType:path:error: + (NSFNanoStore *)createAndOpenStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath error:(out NSError **)outError \endlink method.
 
 @details <b>Example:</b>
 @code
 // Instantiate an in-memory document store and open it. The path parameter is unused.
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Instantiate a temporary document store and open it. The path parameter is unused.
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFTemporaryStoreType path:nil error:nil];
 
 // Instantiate a file-based document store and open it. The path parameter must be specified.
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFPersistentStoreType path:@"~/Desktop/myDatabase.database" error:nil];
 @endcode
 
 @note
 In the case of file-based document stores, the file gets created automatically if it doesn't exist and then opened. If it already exists, it gets opened and made available for use right away.
 
 There are instances where you may want to fine-tune the engine. Tunning the engine has to be performed before the document store is opened. Another method is available In NSFNanoStore for this
 purpose: \link createStoreWithType:path: + (NSFNanoStore *)createStoreWithType:(NSFNanoStoreType)theType path:(NSString *)thePath \endlink.
 
 @details <b>Example:</b>
 @code
 // Instantiate a file-based document store but don't open it right away. The path parameter must be specified.
 NSFNanoStore *nanoStore = [NSFNanoStore createStoreWithType:NSFPersistentStoreType path:@"~/Desktop/myDatabase.database" error:nil];
 
 // Obtain the engine
 NSFNanoEngine *nanoStoreEngine = [nanoStore nanoStoreEngine];
 
 // Set the synchronous mode setting
 [nanoStoreEngine setSynchronousMode:SynchronousModeOff];
 [nanoStoreEngine setEncodingType:NSFEncodingUTF16];
 
 // Open the document store
 [nanoStore openWithError:nil];
 @endcode
 
 @note
 Check the section Performance Tips below for important information about how to get the most out of NanoStore.
 
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
 [nanoStore removeObjectsWithKeysInArray:[NSArray arrayWithObject:[object nanoObjectKey]] error:nil];
 @endcode
 
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
 
 @section wherearetheobjects_sec Where are my objects?
 
 While NSFNanoStore provides some convenience methods to obtain standard objects such as bags, the bulk of the search mechanism is handled by NSFNanoSearch.
 The steps involved to perform a search are quite simple:
 
 - 1) Instantiate a search object
 - 2) Configure the search via its accessors
 - 3) Obtain the results specifying whether objects or keys should be returned (*)
 
 (*) If introspecting the data is needed, request objects. You should request keys if you need to feed the result to another method, such as NSFNanoStore
 \link NSFNanoStore::removeObjectsWithKeysInArray:error: -(BOOL)removeObjectsWithKeysInArray:(NSArray *)theKeys error:(out NSError **)outError \endlink method.
 
 @details <b>Example: finding all objects with the attribute 'LastName' and value 'Doe'.</b>
 @code
 NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 
 search.attribute = @"LastName";
 search.match = NSFEqualTo;
 search.value = @"Doe";
 
 // Returns a dictionary with the UUID of the object (key) and the NanoObject (value).
 NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
 @endcode
 
 @details <b>Example: removing all objects with the attribute 'LastName' and value 'Doe'.</b>
 @code
 NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 
 search.attribute = @"LastName";
 search.match = NSFEqualTo;
 search.value = @"Doe";
 
 // Returns an array of matching UUIDs
 NSArray *matchingKeys = [search searchObjectsWithReturnType:NSFReturnKeys error:nil];
 
 // Remove the NanoObjects matching the selected UUIDs
 NSError *outError = nil;
 if (YES == [nanoStore removeObjectsWithKeysInArray:matchingKeys error:&outError]) {
    NSLog(@"The matching objects have been removed.");
 } else {
    NSLog(@"An error has occurred while removing the matching objects. Reason: %@", [outError localizedDescription]);
 }
 @endcode
 
 Another cool feature is the possibility to invoke aggregated functions (count, avg, min, max and total) on the search results. Using the search snippet above,
 calculating the average salary of all people with last name equal to 'Doe' is very easy.
 
 @details <b>Example: calculating the average salary of all objects with the attribute 'LastName' and value 'Doe'.</b>
 @code
 NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 
 search.attribute = @"LastName";
 search.match = NSFEqualTo;
 search.value = @"Doe";
 
 float averageSalary = [[search aggregateOperation:NSFAverage onAttribute:@"Salary"]floatValue];
 @endcode
 
 @section sorting_sec Sorting
 
 Combining search and sort is an extremely easy operation. There are two simple parts:
 
 - 1) Preparing your classes for sorting
 - 2) Setup a search operation and set its sort descriptors
 
 @section preparesorting_sec Preparing your classes for sorting
 
 Since NanoStore relies on KVC to perform the sorts, a hint of the location where the data lives within the object is required. Since KVC uses a key path to reach the element being sorted, we need a way to "point" to it. Most custom classes will return <i>self</i>, as is the case for NSFNanoBag:
 
 @code
 - (id)rootObject
 {
     return self;
 }
 @endcode

 <i>Self</i> in this case represents the top level, the location where the variables <i>name</i>, <i>key</i> and <i>hasUnsavedChanges</i> are located:
 
 @code
 @interface NSFNanoBag : NSObject <NSFNanoObjectProtocol, NSCopying>
 {
      NSFNanoStore     *store;
      NSString         *name;
      NSString         *key;
      BOOL             hasUnsavedChanges;
 }
 @endcode
 
 Assume we have an object that represents a person and its root object is set to <i>self</i>, just as demonstrated above:
 
 @code
 @interface Person : NSFNanoObject
 {
       NSString        *firstName;
       NSString        *lastName;
       NSString        *email;
 }
 @endcode

 If we wanted to retrieve all the existing people with <i>firstName</i> equal to <i>John</i> sorted by <i>lastName</i> we would do the following:
 
 @code
 // Assume NanoStore has been opened elsewhere
 NSFNanoStore *nanoStore = ...;
 
 // Prepare the search
 NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 search.attribute = @"firstName";
 search.match = NSFEqualTo;
 search.value = @"John";
 
 // Prepare and set the sort descriptor
 NSFNanoSortDescriptor *sortByLastName = [[NSFNanoSortDescriptor alloc]initWithAttribute:@"lastName" ascending:YES];
 search.sort = [NSArray arrayWithObject:sortByLastName];
 
 // Perform the search
 NSArray *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
 
 // Cleanup
 [sortByLastName release];
 @endcode

 @section paging_limit_sec Paging using Limit and Offset
 SQLite provides a really cool feature called OFFSET that is usually used with a LIMIT clause.
 
 The LIMIT clause is used to limit the number of results returned in a SQL statement. So if you have 1000 rows in table, but only want to return the first 10, you would do something like this:
 @code
 SELECT column FROM table LIMIT 10
 @endcode
 Now suppose you wanted to show results 11-20. With the OFFSET keyword it's just as easy. The following query will do:
 @code
 SELECT column FROM table LIMIT 10 OFFSET 10
 @endcode
 Using pagination is also quite easy with NanoStore. This example based on one of the unit tests provided with the NanoStore distro:
 @code
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Assume we have added objects to the store
 
 NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 search.value = @"Barcelona";
 search.match = NSFEqualTo;
 search.limit = 5;
 search.offset = 3;
 
 NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
 
 // Assuming the query matches some results, NanoStore should have retrieved
 // the first 5 records right after the 3rd one from the result set.
 @endcode
 
 @section performancetips_sec Performance Tips
 
 NanoStore by defaults saves every object to disk one by one. To speed up inserts and edited objects, increase NSFNanoStore's \link NSFNanoStore::saveInterval saveInterval \endlink property.
 
 @details <b>Example:</b>
 @code
 // Instantiate and open a NanoStore
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Increase the save interval
 [nanoStore setSaveInterval:1000];
 
 // Do a bunch of inserts and/or edits
 
 // Don't forget that some objects could be lingering in memory. Force a save.
 [nanoStore saveStoreAndReturnError:nil];
 @endcode
 
 @note If you set the saveInterval value to anything other one, keep in mind that some objects may still be left unsaved after being added or modified. To make sure they're saved properly, call \link NSFNanoStore::saveStoreAndReturnError: - (BOOL)saveStoreAndReturnError:(out NSError **)outError \endlink.
 
 Choosing a good saveInterval value is more art than science. While testing NanoStore using a medium-sized dictionary (iTunes' MP3 dictionary) setting saveInterval to 1000 resulted in the best performance. You may want to test with different numbers and fine-tune it for your data set.
 
 @warning Setting saveInterval to a large number could result in decreased performance because SQLite's would have to spend more time reading the journal file and writing the changes to the database.
 
 @section needhelp_sec Need more help?
 There are two quick ways to find answers: reading the documentation and browsing the Unit tests.
 
 While several attempts have been made to make the documentation easy to read and understand, it's far from perfect. If you find that the documentation is
 incomplete, incorrect or needs some clarification, please file a bug. I'll appreciate it and correct it as soon as possible:
 
 - NanoStore Documentation: http://dl.dropbox.com/u/2601212/NanoStore%202.0/html/index.html
 - NanoStore Bug Tracker: https://github.com/tciuro/NanoStore/issues
 - Twitter: http://twitter.com/nanostoredev
 
 @section officialsourcerepo_sec Official Source Repository
 The official repository for NanoStore is hosted on GitHub: https://github.com/tciuro/NanoStore
 
 */
