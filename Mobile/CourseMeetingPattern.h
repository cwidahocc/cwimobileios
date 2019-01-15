//
//  CourseMeetingPattern.h
//  Mobile
//
//  Created by jkh on 2/19/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CourseDetail;

@interface CourseMeetingPattern : NSManagedObject

@property (nonatomic, retain) NSString * building;
@property (nonatomic, retain) NSString * buildingId;
@property (nonatomic, retain) NSString * campusId;
@property (nonatomic, retain) NSString * daysOfWeek;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSDate * endTime;
@property (nonatomic, retain) NSString * frequency;
@property (nonatomic, retain) NSString * instructionalMethodCode;
@property (nonatomic, retain) NSString * room;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) CourseDetail *course;
@property (nonatomic, retain) NSString * campus;

@end
