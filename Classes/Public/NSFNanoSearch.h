/*
     NSFNanoSearch.h
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

/*! @file NSFNanoSearch.h
 @brief A unit that provides an API to retrieve data from the document store.
 */

/** @class NSFNanoSearch
 * A unit that provides an API to retrieve data from the document store.
 *
 * The search can be conducted in two ways: programatically via setters or by providing a SQL statement. In both cases,
 * it's necessary to indicate which object type should be returned. The type \link Globals::NSFReturnType NSFReturnType \endlink provides two options: \link Globals::NSFReturnObjects NSFReturnObjects \endlink and \link Globals::NSFReturnKeys NSFReturnKeys \endlink.
 *
 *           -  \link Globals::NSFReturnObjects NSFReturnObjects \endlink will return a dictionary with the key of the NanoObject (key) and the NanoObject itself (value).
 *           -  \link Globals::NSFReturnKeys NSFReturnKeys \endlink will return an array of NanoObjects.
 *
 * @par <b>Some observations about retrieving data</b><br>
 * 
 * Given the following data set:
 * 
 *           - Number of dictionaries:    3.956
 *           - Number of attributes:    593.862
 * 
 * The table describing different timings to perform a simple value search (i.e. 'Barcelona') is included below, ordered from fastest to slowest:
 *
 *<table border="1" cellpadding="5">
 *<tr>
 *<th>Match type</th>
 *<th>Seconds</th>
 *</tr>
 *<tr><td>Equal to</td><td>0.295</td></tr>
 *<tr><td>Begins with</td><td>0.295</td></tr>
 *<tr><td>Contains</td><td>1.295</td></tr>
 *<tr><td>Contains (insensitive)</td><td>1.339</td></tr>
 *<tr><td>Ends with (insensitive)</td><td>1.341</td></tr>
 *<tr><td>Ends with</td><td>1.351</td></tr>
 *<tr><td>Equal to (insensitive)</td><td>1.890</td></tr>
 *<tr><td>Begins with (insensitive)</td><td>2.412</td></tr>
 *<tr><td>Greater than</td><td>18.246</td></tr>
 *<tr><td>Less than</td><td>27.677</td></tr>
 *</table>
 
 @section wherearetheobjects_sec Where are my objects?
 
 While NSFNanoStore provides some convenience methods to obtain standard objects (such as objects of type NSFNanoBag), the bulk of the search mechanism is handled by NSFNanoSearch.
 The steps involved to perform a search are quite simple:
 
 - 1) Instantiate a search object
 - 2) Configure the search via its accessors
 - 3) Obtain the results specifying whether objects or keys should be returned (*)
 
 (*) Request objects if you're interested in the data. Otherwise, you should request keys if you need to feed the result to another method, such as NSFNanoStore
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
 
 * @details <b>Example:</b>
 @code
 // Instantiate a NanoStore and open it
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Generate a NanoObject with a dictionary and a key
 NSString *key = @"ABC-123";
 NSDictionary *info = ...;
 NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:info];
 
 // Add it to the document store
 [nanoStore addObject:nanoObject error:nil];
 
 // Instantiate a search and specify the attribute(s) we want to search for
 NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 search.key = key;
 
 // Perform the search and obtain the results
 NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
 
 // Close the document store
 [nanoStore closeWithError:nil];
 @endcode
 */

#import <Foundation/Foundation.h>

#import "NSFNanoGlobals.h"

@class NSFNanoStore, NSFNanoResult;

@interface NSFNanoSearch : NSObject

/** * The document store used for searching. */
@property (nonatomic, weak, readonly) NSFNanoStore *nanoStore;
/** * The set of attributes to be returned on matching objects. */
@property (nonatomic, strong, readwrite) NSArray *attributesToBeReturned;
/** * The key used for searching. */
@property (nonatomic, copy, readwrite) NSString *key;
/** * The attribute used for searching. */
@property (nonatomic, copy, readwrite) NSString *attribute;
/** * The value used for searching. */
@property (nonatomic, copy, readwrite) id value;
/** * The comparison operator used for searching. */
@property (nonatomic, assign, readwrite) NSFMatchType match;
/** * The list of NSFNanoExpression objects used for searching. */
@property (nonatomic, strong, readwrite) NSArray *expressions;
/** * If set to YES, specifying NSFReturnKeys applies the DISTINCT function and groups the values. */
@property (nonatomic, assign, readwrite) BOOL groupValues;
/** * The SQL statement used for searching. Set when executeSQL: is invoked. */
@property (nonatomic, copy, readonly) NSString *sql;
/** * The sort holds an array of one or more sort descriptors of type \link NSFNanoSortDescriptor NSFNanoSortDescriptor \endlink. */
@property (nonatomic, strong, readwrite) NSArray *sort;
/** * The filterClass allows to filter the results based on a specific object class. */
@property (nonatomic, copy, readwrite) NSString *filterClass;
/** * If an expression has an offset clause, then the first M rows are omitted from the result set returned by the search operation and the next N rows are returned, where M and N are the values that the offset and limit clauses evaluate to, respectively. Or, if the search would return less than M+N rows if it did not have a limit clause, then the first M rows are skipped and the remaining rows (if any) are returned. */
@property (nonatomic, assign, readwrite) NSUInteger offset;
/** * The limit clause is used to place an upper bound on the number of rows returned by a Search operation. */
@property (nonatomic, assign, readwrite) NSUInteger limit;
/** * limit a Search to a particular bag. */
@property (nonatomic, assign, readwrite) NSFNanoBag *bag;

/** @name Creating and Initializing a Search
 */

//@{

/** * Creates and returns a search element for a given document store.
 * @param theNanoStore the document store where the search will be performed. Must not be nil.
 * @return An search element upon success, nil otherwise.
 * @see \link initWithStore: - (id)initWithStore:(NSFNanoStore *)theNanoStore \endlink
 */

+ (NSFNanoSearch *)searchWithStore:(NSFNanoStore *)theNanoStore;

/** * Initializes a newly allocated search element for a given document store.
 * @param theNanoStore the document store where the search will be performed. Must not be nil.
 * @return An search element upon success, nil otherwise.
 * @see \link searchWithStore: + (NSFNanoSearch *)searchWithStore:(NSFNanoStore *)theNanoStore \endlink
 */

- (id)initWithStore:(NSFNanoStore *)theNanoStore;

//@}

/** @name Searching
 */

//@{

/** * Performs a search using the values of the properties.
 * @param theReturnType the type of object to be returned. Can be \link Globals::NSFReturnObjects NSFReturnObjects \endlink or \link Globals::NSFReturnKeys NSFReturnKeys \endlink.
 * @param outError is used if an error occurs. May be NULL.
 * @return An array is returned if: 1) the sort has been specified or 2) the return type is \link Globals::NSFReturnKeys NSFReturnKeys \endlink. Otherwise, a dictionary is returned.
 * @note The sort descriptor will be ignored when the return type is NSFReturnKeys.
 * @see \link searchObjectsAdded:date:returnType:error: - (id)searchObjectsAdded:(NSFDateMatchType)theDateMatch date:(NSDate *)theDate returnType:(NSFReturnType)theReturnType error:(out NSError **)outError \endlink
 */

- (id)searchObjectsWithReturnType:(NSFReturnType)theReturnType error:(out NSError **)outError;

/** * Performs a search using the values of the properties before, on or after a given date.
 * @param theDateMatch the type of date comparison. Can be \link Globals::NSFBeforeDate NSFBeforeDate \endlink, \link Globals::NSFOnDate NSFOnDate \endlink or \link Globals::NSFAfterDate NSFAfterDate \endlink.
 * @param theDate the date to use as a pivot during the search.
 * @param theReturnType the type of object to be returned. Can be \link Globals::NSFReturnObjects NSFReturnObjects \endlink or \link Globals::NSFReturnKeys NSFReturnKeys \endlink.
 * @param outError is used if an error occurs. May be NULL.
 * @return If theReturnType is \link Globals::NSFReturnObjects NSFReturnObjects \endlink, a dictionary is returned. Otherwise, an array is returned.
 * @note The sort descriptor will be ignored when the return type is NSFReturnKeys.
 * @see \link searchObjectsWithReturnType:error: - (id)searchObjectsWithReturnType:(NSFReturnType)theReturnType error:(out NSError **)outError \endlink
 */

- (id)searchObjectsAdded:(NSFDateMatchType)theDateMatch date:(NSDate *)theDate returnType:(NSFReturnType)theReturnType error:(out NSError **)outError;

/** * Returns the result of the aggregate function.
 * @param theFunctionType is the function type to be applied.
 * @param theAttribute is the attribute used in the function.
 * @returns An NSNumber containing the result of the aggregate function.
 * @details <b>Example:</b>
 @code
 * NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 *
 * // Assume we have saved data to the document store
 * ...
 * ...
 *
 * // Get the average for the attribute named 'SomeNumber'
 * NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 * NSNumber *result = [search aggregateOperation:NSFAverage onAttribute:@"SomeNumber"];
 @endcode
 @note The sort descriptor will be ignored when executing aggregate operations.
 */

- (NSNumber *)aggregateOperation:(NSFAggregateFunctionType)theFunctionType onAttribute:(NSString *)theAttribute;

/** * Performs a search with a given SQL statement.
 * @param theSQLStatement is the SQL statement to be executed. Must not be nil or an empty string.
 * @param theReturnType the type of object to be returned. Can be \link Globals::NSFReturnObjects NSFReturnObjects \endlink or \link Globals::NSFReturnKeys NSFReturnKeys \endlink.
 * @param outError is used if an error occurs. May be NULL.
 * @return If theReturnType is \link Globals::NSFReturnObjects NSFReturnObjects \endlink, a dictionary is returned. Otherwise, an array is returned.
 * @note
 * Use this method when performing search on NanoObjects. If you need to perform more advanced SQL statements, you may want to use
 * \link executeSQL: - (NSFNanoResult *)executeSQL:(NSString *)theSQLStatement \endlink instead.
 * @par
 * The key difference between this method and \link executeSQL: - (NSFNanoResult *)executeSQL:(NSString *)theSQLStatement \endlink is that this method performs
 * a check to make sure the columns specified match the ones required by the \link Globals::NSFReturnType NSFReturnType \endlink type selected. If the column selection is wrong,
 * NanoStore rewrites the query by specifying the right set of columns while honoring the rest of the query.
 * @details <b>Example:</b>
 * @code
 * // Prepare a document store
 * NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 *
 * // Prepare some data and wrap it in a NanoObject
 * NSString *key = @"ABC-123";
 * NSDictionary *info = ...;
 * NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:info];
 *
 * // Add it to the document store
 * [nanoStore addObjectsFromArray:[NSArray arrayWithObject:nanoObject] error:nil];
 *
 * // Instantiate a search and specify the attribute(s) we want to search for
 * NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 *
 * // Perform the search
 * // The query will be rewritten as @"SELECT NSFKey, NSFKeyedArchive, NSFObjectClass FROM NSFKeys"
 * NSDictionary *results = [search executeSQL:@"SELECT foo, bar FROM NSFKeys" returnType:NSFReturnObjects error:nil];
 * @endcode
 * @note The sort descriptor will be ignored when executing custom SQL statements.
 * @see \link executeSQL: - (NSFNanoResult *)executeSQL:(NSString *)theSQLStatement \endlink
 */

- (id)executeSQL:(NSString *)theSQLStatement returnType:(NSFReturnType)theReturnType error:(out NSError **)outError;

/** * Performs a search with a given SQL statement.
 * @param theSQLStatement is the SQL statement to be executed. Must not be nil or an empty string.
 * @return Returns a NSFNanoResult.
 * @note
 * Use this method when you need to perform more advanced SQL statements. If you just want to query NanoObjects using your own SQL statement,
 * you may want to use \link executeSQL:returnType:error: - (id)executeSQL:(NSString *)theSQLStatement returnType:(NSFReturnType)theReturnType error:(out NSError **)outError \endlink instead.
 * @par
 * The key difference between this method and \link executeSQL:returnType:error: - (id)executeSQL:(NSString *)theSQLStatement returnType:(NSFReturnType)theReturnType error:(out NSError **)outError \endlink
 * is that this method doesn't perform any check at all. The SQL statement will be sent verbatim to SQLite.
 * @details <b>Example:</b>
 * @code
 * // Prepare a document store
 * NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 *
 * // Prepare some data and wrap it in a NanoObject
 * NSString *key = @"ABC-123";
 * NSDictionary *info = ...;
 * NSFNanoObject *nanoObject = [NSFNanoObject nanoObjectWithDictionary:info];
 *
 * // Add it to the document store
 * [nanoStore addObjectsFromArray:[NSArray arrayWithObject:nanoObject] error:nil];
 *
 * // Instantiate a search and specify the attribute(s) we want to search for
 * NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 *
 * // Perform the search
 * NSFNanoResult *result = [search executeSQL:@"SELECT COUNT(*) FROM NSFKEYS"];
 * @endcode
 * @see \link executeSQL:returnType:error: - (id)executeSQL:(NSString *)theSQLStatement returnType:(NSFReturnType)theReturnType error:(out NSError **)outError \endlink
 * @note The sort descriptor will be ignored when executing custom SQL statements.
 */

- (NSFNanoResult *)executeSQL:(NSString *)theSQLStatement;

/** * Performs an analysis of the given SQL statement.
 * @param theSQLStatement is the SQL statement to be analyzed. Must not be nil or an empty string.
 * @return Returns a NSFNanoResult.
 * @note
 * Returns the sequence of virtual machine instructions with high-level information about what indices would have been used if the SQL statement had
 * been executed.
 *
 * @warning
 * The analysis generated by this method is intended for interactive analysis and troubleshooting only. The details of the output format
 * are subject to change from one release of SQLite to the next. Applications should not use this method in production code since the exact behavior
 * is undocumented, unspecified, and variable.
 *
 * For additional information about SQLite's Virtual Machine Opcodes, see http://www.sqlite.org/opcode.html
 *
 * The tutorial Virtual Database Engine of SQLite is available here: http://www.sqlite.org/vdbe.html
 *
 * @details <b>Example:</b>
 * @code
 * // Prepare a document store
 * NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 *
 * // Instantiate a search object
 * NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 *
 * // Perform the analysis
 * NSFNanoResult *results = [search explainSQL:@"SELECT * FROM NSFValues"];
 * @endcode
 * @see \link executeSQL: - (NSFNanoResult *)executeSQL:(NSString *)theSQLStatement \endlink
 * @see \link executeSQL:returnType:error: - (id)executeSQL:(NSString *)theSQLStatement returnType:(NSFReturnType)theReturnType error:(out NSError **)outError \endlink
 */

- (NSFNanoResult *)explainSQL:(NSString *)theSQLStatement;

//@}

/** @name Resetting Values
 */

//@{

/** * Resets the values to a know, default state.
 *      - key                 = nil;
 *      - attribute           = nil;
 *      - value               = nil;
 *      - match               = NSFContains;
 *      - object type         = NSFReturnObjects;
 *      - groupValues         = NO;
 *      - attributesReturned  = nil;
 *      - type returned       = NSFReturnObjects;
 *      - sql                 = nil;
 *      - sort                = nil;
 *
 * @note
 * When invoked, it sets the values of search to its initial state. Resetting and performing a search will select all records.
 */

- (void)reset;

//@}

/** Returns a string representation of the search.
 */

- (NSString *)description;

/** Returns a JSON representation of the search.
 */

- (NSString *)JSONDescription;

@end