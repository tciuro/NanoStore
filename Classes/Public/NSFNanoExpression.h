/*
     NSFNanoExpression.h
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

#import "NSFNanoGlobals.h"

@class NSFNanoPredicate;

/*! @file NSFNanoExpression.h
 @brief A unit that describes a series of predicates and its operators.
 */

/** @class NSFNanoExpression
 * A unit that describes a series of predicates and its operators.
 * @details <b>Example:</b>
 @code
 // Instantiate a NanoStore and open it
 NSFNanoStore *nanoStore = [NSFNanoStore createAndOpenStoreWithType:NSFMemoryStoreType path:nil error:nil];
 
 // Prepare the expression
 NSFNanoPredicate *attribute = [NSFNanoPredicate predicateWithColumn:NSFAttributeColumn matching:NSFEqualTo value:@"FirstName"];
 NSFNanoPredicate *value = [NSFNanoPredicate predicateWithColumn:NSFValueColumn matching:NSFEqualTo value:@"Joe"];
 NSFNanoExpression *expression = [NSFNanoExpression expressionWithPredicate:attribute];
 [expression addPredicate:value withOperator:NSFAnd];
 
 // Setup the search with the document store and a given expression
 NSFNanoSearch *search = [NSFNanoSearch searchWithStore:nanoStore];
 [search setExpressions:[NSArray arrayWithObject:expression]];
 
 // Obtain the matching objects
 NSDictionary *searchResults = [search searchObjectsWithReturnType:NSFReturnObjects error:nil];
 
 // Close the document store
 [nanoStore closeWithError:nil];
 @endcode
 */

@interface NSFNanoExpression : NSObject

/** * Array of NSFNanoPredicate */
@property (nonatomic, readonly) NSArray      *predicates;
/** * Array of NSNumber wrapping \link NSFGlobals::NSFOperator NSFOperator \endlink */
@property (nonatomic, readonly) NSArray      *operators;

/** @name Creating and Initializing Expressions
 */

//@{

/** * Creates and returns an expression with a given predicate.
 * @param thePredicate the predicate used to initialize the expression. Must not be nil.
 * @return An expression upon success, nil otherwise.
 * @warning The parameter thePredicate must not be nil.
 * @throws NSFUnexpectedParameterException is thrown if the predicate is nil.
 * @see \link initWithPredicate: - (id)initWithPredicate:(NSFNanoPredicate *)aPredicate \endlink
 */

+ (NSFNanoExpression*)expressionWithPredicate:(NSFNanoPredicate *)thePredicate;

/** * Initializes a newly allocated expression with a given expression.
 * @param thePredicate the predicate used to initialize the expression. Must not be nil.
 * @return An expression upon success, nil otherwise.
 * @warning The parameter thePredicate must not be nil.
 * @throws NSFUnexpectedParameterException is thrown if the predicate is nil.
 * @see \link expressionWithPredicate: + (NSFNanoExpression*)expressionWithPredicate:(NSFNanoPredicate *)thePredicate \endlink
 */

- (id)initWithPredicate:(NSFNanoPredicate *)thePredicate;

//@}

/** @name Adding a Predicate
 */

//@{

/** * Adds a predicate to the expression.
 * @param thePredicate is added to the expression.
 * @param theOperator specifies the operation (AND/OR) to be applied.
 * @warning The parameter thePredicate must not be nil.
 * @throws NSFUnexpectedParameterException is thrown if the predicate is nil.
 */

- (void)addPredicate:(NSFNanoPredicate *)thePredicate withOperator:(NSFOperator)theOperator;

//@}

/** @name Miscellaneous
 */

//@{

/** * Returns a string representation of the expression.
 * @note Check properties predicates and operators to find out the current state of the expression.
 */

- (NSString *)description;

/** Returns a JSON representation of the expression.
 * @note Check properties predicates and operators to find out the current state of the expression.
 */

- (NSString *)JSONDescription;

//@}

@end