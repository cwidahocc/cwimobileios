//
//  RegistrationDropResultsViewController.h
//  Mobile
//
//  Created by Jason Hocker on 8/22/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RegistrationTabBarController, Module;

@interface RegistrationDropResultsViewController : UITableViewController

@property (nonatomic, strong) NSArray *importantMessages;
@property (nonatomic, strong) NSArray *registeredMessages;
@property (nonatomic, strong) NSArray *warningMessages;
@property (nonatomic, strong) RegistrationTabBarController* delegate;
@property (strong, nonatomic) Module *module;
- (IBAction)dismiss:(id)sender;
@end
