//
//  RootViewController.h
//  iPhoneTest
//
//  Created by Tito Ciuro on 24/08/10.
//  Copyright 2010 Webbo, L.L.C. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController
{
    NSMutableArray *values;
}

@property (nonatomic,retain) NSMutableArray *values;

@end
