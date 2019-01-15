//
//  CourseSection.h
//  Mobile
//
//  Created by jkh on 2/13/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CourseTerm;

@interface CourseSection : NSManagedObject

@property (nonatomic, retain) NSNumber * isInstructor;
@property (nonatomic, retain) NSString * sectionId;
@property (nonatomic, retain) NSString * sectionTitle;
@property (nonatomic, retain) NSString * courseName;
@property (nonatomic, retain) NSString * courseSectionNumber;
@property (nonatomic, retain) CourseTerm *term;

@end
