//
//  RegistrationSearchViewController.h
//  Mobile
//
//  Created by jkh on 1/7/14.
//  Copyright (c) 2014 Ellucian. All rights reserved.
//

/*

In the iPad Storyboard, the first label has its width set, due to bug that it couldn't determine the correct width in the split view controller. 
 
*/

#import <UIKit/UIKit.h>
#import "RegistrationRefineSearchViewController.h"
#import "Ellucian_GO-Swift.h"

@class Module;

@interface RegistrationSearchViewController : UIViewController<UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UISplitViewControllerDelegate, RegistrationRefineSearchDelegate, EllucianMobileLaunchableControllerProtocol>

@property (strong, nonatomic) Module *module;

@property (weak, nonatomic) IBOutlet UITextField *termTextField;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (nonatomic, assign) BOOL  allowAddToCart;
@property (weak, nonatomic) IBOutlet UIButton *refineSearchButton;


- (IBAction)search:(id)sender;
- (IBAction)updateSearchButton:(id)sender;

@end
