//
//  CourseEvent.h
//  Mobile
//
//  Created by jkh on 6/3/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CourseEvent : NSManagedObject

@property (nonatomic, retain) NSDate   * endDate;
@property (nonatomic, retain) NSString * eventDescription;
@property (nonatomic, retain) NSNumber * isAllDay;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * sectionId;
@property (nonatomic, retain) NSString * courseName;
@property (nonatomic, retain) NSString * courseSectionNumber;
@property (nonatomic, retain) NSString * displayDateSectionHeader;
@property (nonatomic, retain) NSDate   * startDate;
@property (nonatomic, retain) NSString * title;


+ (NSDateFormatter *)myDisplayDateSectionHeaderDateFormatter;
@end
