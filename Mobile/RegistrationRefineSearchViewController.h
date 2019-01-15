//
//  RegistrationRefineSearchViewController.h
//  Mobile
//
//  Created by Jason Hocker on 8/20/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EllucianSectionedUITableViewController.h"

@protocol RegistrationRefineSearchDelegate <NSObject>
-(void) registrationRefindSearchViewControllerSelectedLocations:(NSArray *)locations acadLevels:(NSArray *)levels;
@end


@interface RegistrationRefineSearchViewController : EllucianSectionedUITableViewController

@property (nonatomic, assign) id<RegistrationRefineSearchDelegate> refineSearchDelegate;
@property (nonatomic,strong) NSArray *locations;
@property (nonatomic,strong) NSArray *academicLevels;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@end
