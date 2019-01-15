//
//  CourseDetail.h
//  Mobile
//
//  Created by jkh on 2/19/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CourseDetailInstructor, CourseMeetingPattern;

@interface CourseDetail : NSManagedObject

@property (nonatomic, retain) NSString * ceus;
@property (nonatomic, retain) NSString * courseDescription;
@property (nonatomic, retain) NSString * courseName;
@property (nonatomic, retain) NSString * courseSectionNumber;
@property (nonatomic, retain) NSNumber * credits;
@property (nonatomic, retain) NSDate * firstMeetingDate;
@property (nonatomic, retain) NSDate * lastMeetingDate;
@property (nonatomic, retain) NSString * learningProvider;
@property (nonatomic, retain) NSString * learningProviderSiteId;
@property (nonatomic, retain) NSString * primarySectionId;
@property (nonatomic, retain) NSString * sectionId;
@property (nonatomic, retain) NSString * sectionTitle;
@property (nonatomic, retain) NSString * termId;
@property (nonatomic, retain) NSOrderedSet *instructors;
@property (nonatomic, retain) NSOrderedSet *meetingPatterns;
@end

@interface CourseDetail (CoreDataGeneratedAccessors)

- (void)insertObject:(CourseDetailInstructor *)value inInstructorsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromInstructorsAtIndex:(NSUInteger)idx;
- (void)insertInstructors:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeInstructorsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInInstructorsAtIndex:(NSUInteger)idx withObject:(CourseDetailInstructor *)value;
- (void)replaceInstructorsAtIndexes:(NSIndexSet *)indexes withInstructors:(NSArray *)values;
- (void)addInstructorsObject:(CourseDetailInstructor *)value;
- (void)removeInstructorsObject:(CourseDetailInstructor *)value;
- (void)addInstructors:(NSOrderedSet *)values;
- (void)removeInstructors:(NSOrderedSet *)values;
- (void)insertObject:(CourseMeetingPattern *)value inMeetingPatternsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMeetingPatternsAtIndex:(NSUInteger)idx;
- (void)insertMeetingPatterns:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMeetingPatternsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMeetingPatternsAtIndex:(NSUInteger)idx withObject:(CourseMeetingPattern *)value;
- (void)replaceMeetingPatternsAtIndexes:(NSIndexSet *)indexes withMeetingPatterns:(NSArray *)values;
- (void)addMeetingPatternsObject:(CourseMeetingPattern *)value;
- (void)removeMeetingPatternsObject:(CourseMeetingPattern *)value;
- (void)addMeetingPatterns:(NSOrderedSet *)values;
- (void)removeMeetingPatterns:(NSOrderedSet *)values;
@end
