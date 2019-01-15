//
//  CourseEvent.m
//  Mobile
//
//  Created by jkh on 6/3/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "CourseEvent.h"
@interface CourseEvent()

@property (nonatomic) NSString *primitiveDisplayDateSectionHeader;

@end


@implementation CourseEvent

@dynamic endDate;
@dynamic eventDescription;
@dynamic isAllDay;
@dynamic location;
@dynamic sectionId;
@dynamic courseName;
@dynamic courseSectionNumber;
@dynamic displayDateSectionHeader;
@dynamic startDate;
@dynamic title;

@dynamic primitiveDisplayDateSectionHeader;

#pragma mark - Transient properties

- (NSString *)displayDateSectionHeader
{
    // Create and cache the section identifier on demand.
    
    [self willAccessValueForKey:@"displayDateSectionHeader"];
    NSString *tmp = [self primitiveDisplayDateSectionHeader];
    [self didAccessValueForKey:@"displayDateSectionHeader"];
    
    if (!tmp)
    {
        if ( [self startDate] != nil) {
            tmp = [CourseEvent.myDisplayDateSectionHeaderDateFormatter stringFromDate:[self startDate]];
        } else {
            tmp = [CourseEvent.myDisplayDateSectionHeaderDateFormatter stringFromDate:[NSDate date]];
        }
        [self setPrimitiveDisplayDateSectionHeader:tmp];
    }
    return tmp;
}

+ (NSDateFormatter *)myDisplayDateSectionHeaderDateFormatter
{
    static NSDateFormatter* dateFormatter = nil;
    
    if(dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDoesRelativeDateFormatting:YES];
    }
    return dateFormatter;

}


@end
