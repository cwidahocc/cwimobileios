//
//  CourseAssignmentDetailViewController.h
//  Mobile
//
//  Created by Jason Hocker on 6/6/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Module.h"
#import "DetailSelectionDelegate.h"
#import "CourseAssignment.h"
@import EventKitUI;


@interface CourseAssignmentDetailViewController : UIViewController <DetailSelectionDelegate, EKEventEditViewDelegate>

@property (nonatomic, strong) CourseAssignment *courseAssignment;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *courseNameLabel;

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIToolbar *padToolBar;

@property (strong, nonatomic) NSString *courseName;
@property (strong, nonatomic) NSString *courseSectionNumber;
@property (strong, nonatomic) NSString *itemTitle;
@property (strong, nonatomic) NSString *itemContent;
@property (strong, nonatomic) NSString *itemLink;
@property (strong, nonatomic) NSDate *itemPostDateTime;

@property (strong, nonatomic) Module *module;

@end
