//
//  CourseAnnouncement.h
//  Mobile
//
//  Created by jkh on 6/4/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CourseAnnouncement : NSManagedObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate   * date;
@property (nonatomic, retain) NSString * sectionId;
@property (nonatomic, retain) NSString * displayDateSectionHeader;
@property (nonatomic, retain) NSString * courseName;
@property (nonatomic, retain) NSString * courseSectionNumber;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * website;


+ (NSDateFormatter *)myDisplayDateSectionHeaderDateFormatter;
@end
