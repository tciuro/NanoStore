/*
     NSFNanoObjectProtocol.h
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

/*! @file NSFNanoObjectProtocol.h
 @brief A protocol declaring the interface that objects interfacing with NanoStore must implement.
 */

/** @protocol NSFNanoObjectProtocol
 * A protocol declaring the interface that objects interfacing with NanoStore must implement.
 *
 * @note
 * Check NSFNanoBag or NSFNanoObject to see a concrete example of how NSFNanoObjectProtocol is implemented.
 */

@class NSFNanoStore;

@protocol NSFNanoObjectProtocol

@required

/** * Initializes a newly allocated object containing a given key and value associated with a document store.
 * @param theDictionary the information associated with the object.
 * @param aKey the key associated with the information.
 * @param theStore the document store where the object is stored.
 * @return An initialized object upon success, nil otherwise.
 * @details <b>Example:</b>
 @code
 - (id)initFromDictionaryRepresentation:(NSDictionary *)aDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)aStore
 {
    if (self = [self init]) {
      info = [aDictionary retain];
      key = [aKey copy];
    }
 
    return self;
 }
 @endcode
 */

- (id)initNanoObjectFromDictionaryRepresentation:(NSDictionary *)theDictionary forKey:(NSString *)aKey store:(NSFNanoStore *)theStore;

/** * Returns a dictionary that contains the information stored in the object.
 * @see \link nanoObjectKey - (NSString *)nanoObjectKey \endlink
 */

- (NSDictionary *)nanoObjectDictionaryRepresentation;

/** * Returns the key associated with the object.
 * @note
 * The class NSFNanoEngine contains a convenience method for this purpose: \ref NSFNanoEngine::stringWithUUID "+(NSString*)stringWithUUID"
 *
 * @see \link nanoObjectDictionaryRepresentation - (NSDictionary *)nanoObjectDictionaryRepresentation \endlink
 */

- (NSString *)nanoObjectKey;

@end