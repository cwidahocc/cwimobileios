//
//  RegistrationSearchResultsViewController.h
//  Mobile
//
//  Created by Jason Hocker on 1/13/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailSelectionDelegate.h"
#import "EllucianSectionedUITableViewController.h"
#import "Ellucian_GO-Swift.h"

@class Module;
@interface RegistrationSearchResultsViewController : EllucianUITableViewController <UITableViewDataSource, UITableViewDelegate, UISplitViewControllerDelegate, UITextFieldDelegate, MasterWithDetailSelectionDelegateProtocol >

@property (strong, nonatomic) Module *module;

@property (nonatomic, strong) NSMutableArray *courses;
@property (nonatomic, strong) id<DetailSelectionDelegate> detailSelectionDelegate;
@property (nonatomic, assign) BOOL  allowAddToCart;

@end
