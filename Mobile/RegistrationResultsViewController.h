//
//  RegistrationResultsViewController.h
//  Mobile
//
//  Created by Jason Hocker on 12/6/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RegistrationTabBarController, Module;

@interface RegistrationResultsViewController : UITableViewController

@property (nonatomic, strong) NSArray *importantMessages;
@property (nonatomic, strong) NSArray *registeredMessages;
@property (nonatomic, strong) NSArray *warningMessages;
@property (nonatomic, strong) RegistrationTabBarController* delegate;
@property (strong, nonatomic) Module *module;
- (IBAction)dismiss:(id)sender;
@end
