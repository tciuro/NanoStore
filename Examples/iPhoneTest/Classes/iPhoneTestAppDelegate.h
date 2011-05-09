//
//  iPhoneTestAppDelegate.h
//  iPhoneTest
//
//  Created by Tito Ciuro on 24/08/10.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iPhoneTestAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

