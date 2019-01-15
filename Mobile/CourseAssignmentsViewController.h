//
//  CourseAssignmentsViewController.h
//  Mobile
//
//  Created by jkh on 6/4/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "EllucianUITableViewController.h"
#import "EllucianUITableViewController.h"
#import "Module.h"
#import "Ellucian_GO-Swift.h"

@protocol CourseDetailViewControllerProtocol;

@interface CourseAssignmentsViewController : EllucianUITableViewController<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSString *termId;
@property (strong, nonatomic) NSString *sectionId;
@property (strong, nonatomic) NSString *courseNameAndSectionNumber;
@property (strong, nonatomic) Module *module;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSString *courseName;
@property (strong, nonatomic) NSString *courseSectionNumber;
- (IBAction)dismiss:(id)sender;

@end
