//
//  RegistrationRegisteredSectionsViewController.h
//  Mobile
//
//  Created by Jason Hocker on 1/24/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EllucianSectionedUITableViewController.h"
#import "DetailSelectionDelegate.h"
#import "Ellucian_GO-Swift.h"

@class Module;

@interface RegistrationRegisteredSectionsViewController : EllucianSectionedUITableViewController<UITableViewDataSource, UITableViewDelegate, UISplitViewControllerDelegate, EllucianMobileLaunchableControllerProtocol, MasterWithDetailSelectionDelegateProtocol >

@property (strong, nonatomic) Module *module;
@property (nonatomic, strong) id<DetailSelectionDelegate> detailSelectionDelegate;

@end
