//
//  POIDetailViewController.h
//  Mobile
//
//  Created by Jason Hocker on 9/8/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Module.h"
#import "PseudoButtonView.h"

@interface POIDetailViewController : UIViewController

@property (strong, nonatomic) NSString *imageUrl;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray *types;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSString *poiDescription;
@property (strong, nonatomic) NSString *additionalServices;
@property (strong, nonatomic) NSString *buildingId;
@property (strong, nonatomic) NSString *campusName;

@property (strong, nonatomic) Module *module;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *campusLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet PseudoButtonView *addressView;
@property (weak, nonatomic) IBOutlet PseudoButtonView *directionsView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *directionsLabel;

@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorAfterAddressHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionTextViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;


@end
