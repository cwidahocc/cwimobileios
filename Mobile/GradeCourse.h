//
//  GradeCourse.h
//  Mobile
//
//  Created by jkh on 2/4/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Grade, GradeTerm;

@interface GradeCourse : NSManagedObject

@property (nonatomic, retain) NSString * courseName;
@property (nonatomic, retain) NSString * sectionId;
@property (nonatomic, retain) NSString * sectionTitle;
@property (nonatomic, retain) NSString * courseSectionNumber;
@property (nonatomic, retain) NSOrderedSet *grades;
@property (nonatomic, retain) GradeTerm *term;
@end

@interface GradeCourse (CoreDataGeneratedAccessors)

- (void)insertObject:(Grade *)value inGradesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromGradesAtIndex:(NSUInteger)idx;
- (void)insertGrades:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeGradesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInGradesAtIndex:(NSUInteger)idx withObject:(Grade *)value;
- (void)replaceGradesAtIndexes:(NSIndexSet *)indexes withGrades:(NSArray *)values;
- (void)addGradesObject:(Grade *)value;
- (void)removeGradesObject:(Grade *)value;
- (void)addGrades:(NSOrderedSet *)values;
- (void)removeGrades:(NSOrderedSet *)values;
@end
