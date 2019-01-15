//
//  CourseDetail.m
//  Mobile
//
//  Created by jkh on 2/19/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "CourseDetail.h"
#import "CourseDetailInstructor.h"
#import "CourseMeetingPattern.h"


@implementation CourseDetail

@dynamic ceus;
@dynamic courseDescription;
@dynamic courseName;
@dynamic courseSectionNumber;
@dynamic credits;
@dynamic firstMeetingDate;
@dynamic lastMeetingDate;
@dynamic learningProvider;
@dynamic learningProviderSiteId;
@dynamic primarySectionId;
@dynamic sectionId;
@dynamic sectionTitle;
@dynamic termId;
@dynamic instructors;
@dynamic meetingPatterns;

- (void)addMeetingPatternsObject:(CourseMeetingPattern *)value
{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.meetingPatterns];
    [tempSet addObject:value];
    self.meetingPatterns = tempSet;
}

- (void)addInstructorsObject:(CourseDetailInstructor *)value
{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.instructors];
    [tempSet addObject:value];
    self.instructors = tempSet;
}
@end
