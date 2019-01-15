//
//  RegistrationCartViewController.h
//  Mobile
//
//  Created by jkh on 11/18/13.
//  Copyright (c) 2013 - 2014 Ellucian. All rights reserved.
//

#import "EllucianUITableViewController.h"
#import "DetailSelectionDelegate.h"
#import "Ellucian_GO-Swift.h"

@class Module;

@interface RegistrationCartViewController : EllucianUITableViewController<UITableViewDataSource, UITableViewDelegate, UISplitViewControllerDelegate, EllucianMobileLaunchableControllerProtocol, MasterWithDetailSelectionDelegateProtocol >

@property (strong, nonatomic) Module *module;
@property (nonatomic, strong) id<DetailSelectionDelegate> detailSelectionDelegate;

@end
