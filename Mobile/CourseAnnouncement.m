//
//  CourseAnnouncement.m
//  Mobile
//
//  Created by jkh on 6/4/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "CourseAnnouncement.h"
@interface CourseAnnouncement()

@property (nonatomic) NSString *primitiveDisplayDateSectionHeader;

@end


@implementation CourseAnnouncement

@dynamic content;
@dynamic date;
@dynamic displayDateSectionHeader;
@dynamic courseName;
@dynamic courseSectionNumber;
@dynamic sectionId;
@dynamic title;
@dynamic website;

@dynamic primitiveDisplayDateSectionHeader;

#pragma mark - Transient properties

- (NSString *)displayDateSectionHeader
{
    // Create and cache the section identifier on demand.
    
    [self willAccessValueForKey:@"displayDateSectionHeader"];
    NSString *tmpHeaderName = [self primitiveDisplayDateSectionHeader];
    [self didAccessValueForKey:@"displayDateSectionHeader"];

    if (!tmpHeaderName)
    {
        if ( [self date] != nil) {
            tmpHeaderName = [CourseAnnouncement.myDisplayDateSectionHeaderDateFormatter stringFromDate:[self date]];
        } else {
            NSDate *today = [NSDate date];
            tmpHeaderName = [CourseAnnouncement.myDisplayDateSectionHeaderDateFormatter stringFromDate:today];
        }
        [self setPrimitiveDisplayDateSectionHeader:tmpHeaderName];
    }
    return tmpHeaderName;
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
