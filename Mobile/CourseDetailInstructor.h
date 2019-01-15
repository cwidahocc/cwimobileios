//
//  CourseDetailInstructor.h
//  Mobile
//
//  Created by jkh on 2/18/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CourseDetail;

@interface CourseDetailInstructor : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * middleInitial;
@property (nonatomic, retain) NSNumber * primary;
@property (nonatomic, retain) NSString * formattedName;
@property (nonatomic, retain) NSString * instructorId;
@property (nonatomic, retain) CourseDetail *course;

@end
