//
//  RegistrationPlannedSectionDetailViewController.h
//  Mobile
//
//  Created by jkh on 1/6/14.
//  Copyright (c) 2014 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RegistrationPlannedSection.h"
#import "DetailSelectionDelegate.h"

@class Module;

@interface RegistrationPlannedSectionDetailViewController : UIViewController <DetailSelectionDelegate, UISplitViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIView *maskView;

@property (weak, nonatomic) IBOutlet UILabel *courseSectionNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *courseNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *meetingDateLabel;

@property (weak, nonatomic) IBOutlet UIView  *titleBackgroundView;

@property (weak, nonatomic) IBOutlet UILabel *sectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sectionContent;

@property (weak, nonatomic) IBOutlet UILabel *creditsLabel;
@property (weak, nonatomic) IBOutlet UILabel *creditsContent;

@property (weak, nonatomic) IBOutlet UILabel *gradingLabel;
@property (weak, nonatomic) IBOutlet UILabel *gradingContent;


@property (weak, nonatomic) IBOutlet UILabel *meetingLabel;
@property (weak, nonatomic) IBOutlet UIView  *meetingContent;

@property (weak, nonatomic) IBOutlet UILabel *facultyLabel;
@property (weak, nonatomic) IBOutlet UIView  *facultyContent;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionContent;

@property (weak, nonatomic) IBOutlet UILabel *academicLevelsLabel;



@property (strong, nonatomic) NSString *courseSectionNumber;
@property (strong, nonatomic) NSString *courseName;
@property (strong, nonatomic) NSString *courseSectionId;
@property (strong, nonatomic) NSString *courseMeetingInfo;
@property (strong, nonatomic) NSString *faculty;
@property (strong, nonatomic) NSString *courseDescription;
@property (strong, nonatomic) NSString *courseCredits;

@property (strong, nonatomic) RegistrationPlannedSection *registrationPlannedSection;

@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *meetingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *facultyConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *creditLabelConstraint;

@property (strong, nonatomic) Module *module;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *deleteFromCartToolbar;
- (IBAction)deleteFromCart:(id)sender;

-(void) clearView;
@property (strong, nonatomic) IBOutlet UIView *availableSeatsView;
@property (strong, nonatomic) IBOutlet UIImageView *availableSeatsMeterImage;
@property (strong, nonatomic) IBOutlet UILabel *availableSeatsLabel;
@property (strong, nonatomic) IBOutlet UILabel *availableSeatsLabelLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *availableSeatsSpacingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *availableSeatsViewHeightConstraint;

@end
