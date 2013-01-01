/*
     NSFNanoGlobals_Private.h
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

/** \cond */

/*
 The following types are supported by Property Lists:
 
 CFArray
 CFDictionary
 CFData
 CFString
 CFDate
 CFNumber
 CFBoolean
 
 Since NanoStore associates an attribute with an atomic value (i.e. non-collection),
 the following data types are recognized:
 
 CFData
 CFString
 CFDate
 CFNumber
 
 Note: there isn't a dedicated data type homologous to CFBoolean in Cocoa. Therefore,
 NSNumber will be used for that purpose.
 
 */

extern NSDictionary * safeJSONDictionaryFromDictionary (NSDictionary *dictionary);
extern NSArray * safeJSONArrayFromArray (NSArray *array);
extern id safeJSONObjectFromObject (id object);

extern NSString * NSFStringFromMatchType (NSFMatchType aMatchType);

extern void _NSFLog (NSString  *format, ...);

extern NSString * const NSFVersionKey;
extern NSString * const NSFDomainKey;

extern NSString * const NSFKeys;
extern NSString * const NSFValues;
extern NSString * const NSFKey;
extern NSString * const NSFValue;
extern NSString * const NSFDatatype;
extern NSString * const NSFCalendarDate;
extern NSString * const NSFObjectClass;
extern NSString * const NSFKeyedArchive;
extern NSString * const NSFAttribute;

#pragma mark -

extern NSString * const NSF_Private_NSFKeys_NSFKey;
extern NSString * const NSF_Private_NSFKeys_NSFKeyedArchive;
extern NSString * const NSF_Private_NSFValues_NSFKey;
extern NSString * const NSF_Private_NSFValues_NSFAttribute;
extern NSString * const NSF_Private_NSFValues_NSFValue;
extern NSString * const NSF_Private_NSFNanoBag_Name;
extern NSString * const NSF_Private_NSFNanoBag_NSFKey;
extern NSString * const NSF_Private_NSFNanoBag_NSFObjectKeys;
extern NSString * const NSF_Private_ToDeleteTableKey;

extern NSInteger const NSF_Private_InvalidParameterDataCodeKey;
extern NSInteger const NSF_Private_MacOSXErrorCodeKey;

#pragma mark -

extern NSString * const NSFP_TableIdentifier;
extern NSString * const NSFP_ColumnIdentifier;
extern NSString * const NSFP_DatatypeIdentifier;
extern NSString * const NSFP_FullDatatypeIdentifier;

extern NSString * const NSFRowIDColumnName;         // SQLite's standard UID property

extern NSString * const NSFP_SchemaTable;           // Private, reserved NSF table name to store datatypes

/** \endcond */