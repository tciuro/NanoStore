/*
     NSFNanoResult.h
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

/*! @file NSFNanoResult.h
 @brief A unit that describes the result of a search.
 */

/** @class NSFNanoResult
 * A unit that describes the result of a search.
 *
 * @note
 * The NanoResult is the object representation of a SQL result set. From it, you can obtain the number of rows, the column names and their
 * associated values.
 *
 * @par
 * After obtaining a NanoResult, it's always a good idea to check whether the <i>error</i> property is nil. If so, the result can be assumed to be
 * correct. Otherwise, <i>error</i> will point to the main cause of failure.
 *
 * @details <b>Example:</b>
 @code
 // Instantiate a NanoStore and open it
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Add some data to the document store
 NSDictionary *info = ...;
 NSFNanoBag *bag = [NSFNanoBag bag];
 NSFNanoObject *obj1 = [NSFNanoObject nanoObjectWithDictionary:info];
 NSFNanoObject *obj2 = [NSFNanoObject nanoObjectWithDictionary:info];
 [nanoStore addObjectsFromArray:[NSArray arrayWithObjects:obj1, obj2, nil] error:nil];
 
 // Instantiate a search and execute the SQL statement
 NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 NSFNanoResult *result = [search executeSQL:@"SELECT COUNT(*) FROM NSFKEYS"];
 
 // Obtain the result (given as an NSString)
 NSString *value = [result firstValue];
 
 // Close the document store
 [nanoStore closeWithError:nil];
 @endcode
 */

#import <Foundation/Foundation.h>

@class NSFNanoStore;

@interface NSFNanoResult : NSObject

/** * Number of rows contained in the result set. */
@property (nonatomic, assign, readonly) NSUInteger numberOfRows;
/** * A reference to the error encountered while processing the request, otherwise nil if the request was successful. */
@property (nonatomic, strong, readonly) NSError *error;

/** @name Accessors
 */

//@{

/** * Returns a new array containing the columns.
 * @returns An array with the columns retrieved from the result set.
 */

- (NSArray *)columns;

/** * Returns a new array containing the values for a given column.
 * @param theIndex is the index of the value in the result set.
 * @param theColumn is the name of the column in the result set.
 * @returns An array with the values associated with a given column.
 * @throws NSRangeException is thrown if the index is out of bounds.
 */

- (NSString *)valueAtIndex:(NSUInteger)theIndex forColumn:(NSString *)theColumn;

/** * Returns a new array containing the values for a given column.
 * @param theColumn is the name of the column in the result set.
 * @returns An array with the values associated with a given column.
 */

- (NSArray *)valuesForColumn:(NSString *)theColumn;

/** * Returns the first value.
 * @returns The value of the first element from the result set.
 */

- (NSString *)firstValue;

//@}

/** @name Exporting the Results to a File
 */

//@{

/** * Saves the result to a file.
 * @param thePath is the location where the result will be saved to a file.
 */

- (void)writeToFile:(NSString *)thePath;

//@}

/** @name Miscellaneous
 */

//@{

/** * Returns a string representation of the result.
 */

- (NSString *)description;

/** Returns a JSON representation of the result.
 */

- (NSString *)JSONDescription;

//@}

@end