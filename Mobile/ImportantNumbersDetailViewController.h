//
//  ImportantNumbersDetailViewController
//  Mobile
//
//  Created by Jason Hocker on 7/5/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Module.h"
#import "PseudoButtonView.h"

@interface ImportantNumbersDetailViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray *types;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSString *buildingId;
@property (strong, nonatomic) NSString *campusId;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic) NSString *phoneExtension;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

@property (strong, nonatomic) Module *module;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet PseudoButtonView *phoneView;
@property (weak, nonatomic) IBOutlet PseudoButtonView *emailView;
@property (weak, nonatomic) IBOutlet UIView *addressView;
@property (weak, nonatomic) IBOutlet PseudoButtonView *directionsView;

@property (weak, nonatomic) IBOutlet UIView *separatorAfterPhoneView;
@property (weak, nonatomic) IBOutlet UIView *separatorAfterEmailView;
@property (weak, nonatomic) IBOutlet UIView *separatorAfterAddressView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorAfterPhoneHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorAfterEmailHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorAfterAddressHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabelLabel;

@property (weak, nonatomic) IBOutlet UILabel *emailLabelLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabelLabel;
@property (weak, nonatomic) IBOutlet UILabel *getDirectionsLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end
