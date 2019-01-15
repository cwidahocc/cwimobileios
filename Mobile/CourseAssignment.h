//
//  CourseAssignment.h
//  Mobile
//
//  Created by jkh on 6/3/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CourseAssignment : NSManagedObject

@property (nonatomic, retain) NSString * assignmentDescription;
@property (nonatomic, retain) NSDate   * dueDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * displayDateSectionHeader;
@property (nonatomic, retain) NSString * sectionId;
@property (nonatomic, retain) NSString * courseName;
@property (nonatomic, retain) NSString * courseSectionNumber;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * overDueWarningSectionHeader;

+(NSDateFormatter*) myDisplayDateSectionHeaderDateFormatter;

@end
