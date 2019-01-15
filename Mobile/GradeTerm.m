//
//  GradeTerm.m
//  Mobile
//
//  Created by Jason Hocker on 9/24/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import "GradeTerm.h"
#import "GradeCourse.h"


@implementation GradeTerm

@dynamic endDate;
@dynamic name;
@dynamic startDate;
@dynamic termId;
@dynamic courses;

//http://openradar.appspot.com/10114310
- (void)addCoursesObject:(GradeCourse *)value
{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.courses];
    [tempSet addObject:value];
    [tempSet sortUsingComparator:^(id obj1, id obj2) {
        return [[obj1 valueForKey:@"courseName" ] localizedCaseInsensitiveCompare:[obj2 valueForKey:@"courseName" ]];
    }];
    self.courses = tempSet;
}

@end
