/*
     NSFNanoGlobals.m
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

#import "NSFNanoGlobals.h"

static BOOL __NSFDebugIsOn = NO;

void NSFSetIsDebugOn (BOOL flag)
{
    __NSFDebugIsOn = flag;
}

BOOL NSFIsDebugOn (void)
{
    return __NSFDebugIsOn;
}

NSString * NSFStringFromNanoDataType (NSFNanoDatatype aNanoDatatype)
{
    NSString *value = nil;
    
    switch (aNanoDatatype) {
        case NSFNanoTypeUnknown: value = @"UNKNOWN"; break;
        case NSFNanoTypeData: value = @"BLOB"; break;
        case NSFNanoTypeString: value = @"TEXT"; break;
        case NSFNanoTypeDate: value = @"TEXT"; break;
        case NSFNanoTypeNumber: value = @"REAL"; break;
        case NSFNanoTypeRowUID: value = @"INTEGER"; break;
        case NSFNanoTypeNULL: value = @"NULL"; break;
        case NSFNanoTypeURL: value = @"URL"; break;
    }
    
    return value;
}

NSFNanoDatatype NSFNanoDatatypeFromString (NSString *aNanoDatatype)
{
    NSFNanoDatatype value = NSFNanoTypeUnknown;

    if ([aNanoDatatype isEqualToString:@"BLOB"]) value = NSFNanoTypeData;
    else if ([aNanoDatatype isEqualToString:@"TEXT"]) value = NSFNanoTypeString;
    else if ([aNanoDatatype isEqualToString:@"TEXT"]) value = NSFNanoTypeDate;
    else if ([aNanoDatatype isEqualToString:@"REAL"]) value = NSFNanoTypeNumber;
    else if ([aNanoDatatype isEqualToString:@"INTEGER"]) value = NSFNanoTypeRowUID;
    else if ([aNanoDatatype isEqualToString:@"NULL"]) value = NSFNanoTypeNULL;
    else if ([aNanoDatatype isEqualToString:@"URL"]) value = NSFNanoTypeURL;
    return value;
}

NSString * NSFStringFromMatchType (NSFMatchType aMatchType)
{
    NSString *value = nil;
    
    switch (aMatchType) {
        case NSFEqualTo: value = @"Equal to"; break;
        case NSFBeginsWith: value = @"Begins with"; break;
        case NSFContains: value = @"Contains"; break;
        case NSFEndsWith: value = @"Ends with"; break;
        case NSFInsensitiveEqualTo: value = @"Equal to (case insensitive)"; break;
        case NSFInsensitiveBeginsWith: value = @"Begins with (case insensitive)"; break;
        case NSFInsensitiveContains: value = @"Contains (case insensitive)"; break;
        case NSFInsensitiveEndsWith: value = @"Ends with (case insensitive)"; break;
        case NSFGreaterThan: value = @"Greater than"; break;
        case NSFLessThan: value = @"Less than"; break;
        case NSFNotEqualTo: value = @"Not equal to"; break;
    }
    
    return value;
}

void _NSFLog (NSString  *format, ...)
{
    if (__NSFDebugIsOn) {
        va_list args;
        va_start(args, format);
        NSString *string = [[NSString alloc]initWithFormat:format arguments:args];
        NSLog(@"%@", string);
        va_end(args);
    }
}

NSString * const NSFVersionKey                       = @"2.0a";
NSString * const NSFDomainKey                        = @"com.Webbo.NanoStore.ErrorDomain";

NSString * const NSFMemoryDatabase                              = @":memory:";
NSString * const NSFTemporaryDatabase                           = @"";
NSString * const NSFUnexpectedParameterException                = @"NSFUnexpectedParameterException";
NSString * const NSFNonConformingNanoObjectProtocolException    = @"NSFNonConformingNanoObjectProtocolException";
NSString * const NSFNanoObjectBehaviorException                 = @"NSFNanoObjectBehaviorException";
NSString * const NSFNanoStoreUnableToManipulateStoreException   = @"NSFNanoStoreUnableToManipulateStoreException";
NSString * const NSFKeys                                        = @"NSFKeys";
NSString * const NSFValues                                      = @"NSFValues";
NSString * const NSFKey                                         = @"NSFKey";
NSString * const NSFAttribute                                   = @"NSFAttribute";
NSString * const NSFValue                                       = @"NSFValue";
NSString * const NSFDatatype                                    = @"NSFDatatype";
NSString * const NSFCalendarDate                                = @"NSFCalendarDate";
NSString * const NSFObjectClass                                 = @"NSFObjectClass";
NSString * const NSFKeyedArchive                                = @"NSFKeyedArchive";

#pragma mark -

NSString * const NSF_Private_NSFKeys_NSFKey             = @"NSFKeys.NSFKey";
NSString * const NSF_Private_NSFKeys_NSFKeyedArchive    = @"NSFKeys.NSFKeyedArchive";
NSString * const NSF_Private_NSFValues_NSFKey           = @"NSFValues.NSFKey";
NSString * const NSF_Private_NSFValues_NSFAttribute     = @"NSFValues.NSFAttribute";
NSString * const NSF_Private_NSFValues_NSFValue         = @"NSFValues.NSFValue";
NSString * const NSF_Private_NSFNanoBag_Name            = @"NSF_Private_NSFNanoBag_Name";
NSString * const NSF_Private_NSFNanoBag_NSFKey          = @"NSF_Private_NSFNanoBag_NSFKey";
NSString * const NSF_Private_NSFNanoBag_NSFObjectKeys   = @"NSF_Private_NSFNanoBag_NSFObjectKeys";
NSString * const NSF_Private_ToDeleteTableKey           = @"NSF_Private_ToDeleteTableKey";

NSString * const NSFRowIDColumnName                     = @"ROWID";

NSInteger const NSF_Private_InvalidParameterDataCodeKey            = -10000;
NSInteger const NSF_Private_MacOSXErrorCodeKey                     = -10001;
NSInteger const NSFNanoStoreErrorKey                               = -10002;

#pragma mark Private section

NSString * const NSFP_SchemaTable                    = @"NSFP_SchemaTable";
NSString * const NSFP_TableIdentifier                = @"NSFP_TableIdentifier";
NSString * const NSFP_ColumnIdentifier               = @"NSFP_ColumnIdentifier";
NSString * const NSFP_DatatypeIdentifier             = @"NSFP_DatatypeIdentifier";

NSString * const NSFP_FullDatatypeIdentifier                = @"NSFP_SchemaTable.NSFP_DatatypeIdentifier";