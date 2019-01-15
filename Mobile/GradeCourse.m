//
//  GradeCourse.m
//  Mobile
//
//  Created by jkh on 2/4/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "GradeCourse.h"
#import "Grade.h"
#import "GradeTerm.h"


@implementation GradeCourse

@dynamic courseName;
@dynamic sectionId;
@dynamic sectionTitle;
@dynamic courseSectionNumber;
@dynamic grades;
@dynamic term;

//http://openradar.appspot.com/10114310
- (void)addGradesObject:(GradeCourse *)value
{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.grades];
    [tempSet addObject:value];
    self.grades = tempSet;
}

@end
