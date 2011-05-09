/*
 OCUnitExtensions.m
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

#import "OCUnitExtensions.h"
#import <SenTestingKit/SenTestRun.h>

@interface SenTestObserver(Internal)
+ (void)setCurrentObserver:(Class)observer;
@end

@implementation SenTestLogWithGrowl

#if defined(__MACH__)
+ (void)testSuiteDidStop:(NSNotification *)notification
{
    [super testSuiteDidStop:notification];
    [self notifyGrowlAboutTestRun:[notification run]];
}

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *registeredDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
        @"SenTestLogWithGrowl" , @"SenTestObserverClass",
        nil];
    [defaults registerDefaults:registeredDefaults];

    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"SenTestObserverClass"] isEqualToString:NSStringFromClass(self)]) {
        [self setCurrentObserver:self];
    }
}

+ (void)performGrowlRegistration
{
    NSMutableArray *notificationArray = [NSArray arrayWithObjects:@"OCUnit Test Passed Notification", @"OCUnit Test Failed Notification", nil];  
    
    NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
        @"OCUnit", @"ApplicationName",
        notificationArray, @"AllNotifications",
        notificationArray, @"DefaultNotifications",
        nil];
    
    [[NSDistributedNotificationCenter defaultCenter]
        postNotificationName:@"GrowlApplicationRegistrationNotification" 
                      object:nil userInfo:regDict];
    
}

+ (void)notifyGrowlAboutTestRun:(SenTestRun *)run
{
    [self performGrowlRegistration];
    
    NSString *title = nil;
    
    if ([run hasSucceeded]) {
        title = @"OCUnit Test Suite Passed";
    } else {
        title = @"OCUnit Test Suite Failed";
    }
    
    NSString *msg = [NSString stringWithFormat:@"Test Suite '%@'.\n\nPassed %d test%s, with %d failure%s (%d unexpected) in %.3f (%.3f) seconds\n",
        [[run test] name],
        [run testCaseCount], ([run testCaseCount] != 1 ? "s" : ""),
        [run totalFailureCount], ([run totalFailureCount] != 1 ? "s" : ""),
        [run unexpectedExceptionCount],
        [run testDuration],
        [run totalDuration]];
    
    NSMutableDictionary *notiInfo = [NSMutableDictionary dictionary];
    [notiInfo setObject:@"OCUnit" forKey:@"ApplicationName"];
    [notiInfo setObject:title forKey:@"NotificationTitle"];
    [notiInfo setObject:msg forKey:@"NotificationDescription"];
    
    NSString *iconPath = nil;
    
    if ([run hasSucceeded]) {
        iconPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Icon-Pass" ofType:@"tiff"];
        [notiInfo setObject:@"OCUnit Test Passed Notification" forKey:@"NotificationName"];
    } else {
        iconPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Icon-Fail" ofType:@"tiff"];
        [notiInfo setObject:@"OCUnit Test Failed Notification" forKey:@"NotificationName"];
        [notiInfo setObject:[NSNumber numberWithBool:YES] forKey:@"NotificationSticky"];
    }
    
    NSData *icon = [NSData dataWithContentsOfFile:iconPath];
    if (icon) {
        [notiInfo setObject:icon forKey:@"NotificationIcon"];
    }
    
    [[NSDistributedNotificationCenter defaultCenter]
        postNotificationName:@"GrowlNotification" 
                      object:nil userInfo:notiInfo];    
}
#endif

@end