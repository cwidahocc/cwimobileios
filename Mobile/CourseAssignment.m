//
//  CourseAssignment.m
//  Mobile
//
//  Created by jkh on 6/3/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "CourseAssignment.h"

@interface CourseAssignment ()

@property (nonatomic) NSString *primitiveDisplayDateSectionHeader;
@property (nonatomic) NSString *primitiveOverDueWarningSectionHeader;

@end

@implementation CourseAssignment

@dynamic assignmentDescription;
@dynamic dueDate;
@dynamic name;
@dynamic displayDateSectionHeader;
@dynamic overDueWarningSectionHeader;
@dynamic sectionId;
@dynamic courseName;
@dynamic courseSectionNumber;
@dynamic url;

@dynamic primitiveDisplayDateSectionHeader;
@dynamic primitiveOverDueWarningSectionHeader;

#pragma mark - Transient properties

- (NSString *)displayDateSectionHeader
{
    // Create and cache the section identifier on demand.
    [self willAccessValueForKey:@"displayDateSectionHeader"];
    NSString *tmp = [self primitiveDisplayDateSectionHeader];
    [self didAccessValueForKey:@"displayDateSectionHeader"];
    
    if (!tmp)
    {
        if ( [self dueDate] != nil) {
            NSDate *currentDate = [NSDate new];
            if ( [[self dueDate] compare:currentDate] == NSOrderedAscending ) {
                tmp = NSLocalizedString(@"OVERDUE", @"overdue assignment indicator for ilp module");
            } else {
                tmp = [CourseAssignment.myDisplayDateSectionHeaderDateFormatter stringFromDate:[self dueDate]];
            }
        }
        [self setPrimitiveDisplayDateSectionHeader:tmp];
    }
    return tmp;
}


- (NSString *)overDueWarningSectionHeader
{
    // Create and cache the section identifier on demand.
    [self willAccessValueForKey:@"overDueWarningSectionHeader"];
    NSString *tmp = [self primitiveOverDueWarningSectionHeader];
    [self didAccessValueForKey:@"overDueWarningSectionHeader"];
    
    if (!tmp)
    {
        if ( [self dueDate] != nil) {
            NSDate *currentDate = [NSDate new];
            //The receiver is earlier in time than anotherDate,  NSOrderedAscending
            if ( [[self dueDate] compare:currentDate] == NSOrderedAscending ) {
                tmp = NSLocalizedString(@"OVERDUE", @"overdue assignment indicator for ilp module");
            } else {
                tmp = NSLocalizedString(@"DUE TODAY", @"assignment due today indicator for ilp module");
            }
            [self setPrimitiveOverDueWarningSectionHeader:tmp];
        }
       
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