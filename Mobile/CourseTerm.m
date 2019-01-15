//
//  CourseTerm.m
//  Mobile
//
//  Created by jkh on 2/4/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "CourseTerm.h"
#import "CourseSection.h"


@implementation CourseTerm

@dynamic name;
@dynamic startDate;
@dynamic termId;
@dynamic endDate;
@dynamic sections;


//http://openradar.appspot.com/10114310
- (void)addSectionsObject:(CourseSection *)value
{
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.sections];
    [tempSet addObject:value];
    [tempSet sortUsingComparator:^(id obj1, id obj2) {
        return [[NSString stringWithFormat:@"%@-%@", [obj1 valueForKey:@"courseName" ],[obj1 valueForKey:@"courseSectionNumber" ]] localizedCaseInsensitiveCompare:[NSString stringWithFormat:@"%@-%@", [obj2 valueForKey:@"courseName" ],[obj2 valueForKey:@"courseSectionNumber" ]]];
    }];
    self.sections = tempSet;
}

@end
