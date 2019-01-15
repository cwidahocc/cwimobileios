//
//  GradeTerm.h
//  Mobile
//
//  Created by Jason Hocker on 9/24/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GradeCourse;

@interface GradeTerm : NSManagedObject

@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSString * termId;
@property (nonatomic, retain) NSOrderedSet *courses;
@end

@interface GradeTerm (CoreDataGeneratedAccessors)

- (void)insertObject:(GradeCourse *)value inCoursesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCoursesAtIndex:(NSUInteger)idx;
- (void)insertCourses:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCoursesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCoursesAtIndex:(NSUInteger)idx withObject:(GradeCourse *)value;
- (void)replaceCoursesAtIndexes:(NSIndexSet *)indexes withCourses:(NSArray *)values;
- (void)addCoursesObject:(GradeCourse *)value;
- (void)removeCoursesObject:(GradeCourse *)value;
- (void)addCourses:(NSOrderedSet *)values;
- (void)removeCourses:(NSOrderedSet *)values;
@end
