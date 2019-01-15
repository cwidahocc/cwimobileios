//
//  RegistrationPlannedSection.m
//  Mobile
//
//  Created by jkh on 11/18/13.
//  Copyright (c) 2013 - 2014 Ellucian. All rights reserved.
//

#import "RegistrationPlannedSection.h"
#import "RegistrationPlannedSectionInstructor.h"
#import "RegistrationPlannedSectionMeetingPattern.h"

@interface RegistrationPlannedSection()
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSDateFormatter *displayDateFormatter;
@property (nonatomic, strong) NSDateFormatter *displayTimeFormatter;
@end


@implementation RegistrationPlannedSection



-(NSString *) facultyNames
{
    NSMutableArray *names = [NSMutableArray new];
    for(RegistrationPlannedSectionInstructor *instructor in self.instructors) {
        if(instructor.lastName && instructor.firstName && [instructor.firstName length]) {
            NSString *name = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"faculty last name, first initial", @"Localizable", [NSBundle mainBundle], @"%@, %@", @"faculty last name, first initial"), instructor.lastName, [instructor.firstName substringToIndex:1]];
            [names addObject:name];
        } else if (instructor.lastName) {
            [names addObject:instructor.lastName];
        } else if (instructor.formattedName) {
            [names addObject:instructor.formattedName];
        }
    }
    if([names count] == 0) return nil;
    return [names componentsJoinedByString:@"; "];
}

-(NSString *)meetingPatternDescription
{
    NSMutableArray *patterns = [NSMutableArray new];
    for(RegistrationPlannedSectionMeetingPattern *mp in self.meetingPatterns) {
        
        NSMutableArray *daysOfClass = [NSMutableArray new];
        NSArray *localizedDays = [self.dateFormatter shortStandaloneWeekdaySymbols];
        NSArray *daysOfWeek = mp.daysOfWeek;
        for(int i = 0; i < [daysOfWeek count]; i++) {
            NSInteger value = [[mp.daysOfWeek objectAtIndex:i] intValue] - 1;
            [daysOfClass addObject:[localizedDays objectAtIndex:value]];
        }

        NSString *line = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course days: start time - end", @"Localizable", [NSBundle mainBundle], @"%@: %@ - %@", @"course days: start time - end"), [daysOfClass componentsJoinedByString:@", "], [self.displayTimeFormatter stringFromDate: mp.startTime], [self.displayTimeFormatter stringFromDate:mp.endTime]];
        [patterns addObject:line];
    }
    if([patterns count] == 0) return nil;
    return [patterns componentsJoinedByString:@"; "];
}

-(NSString *)instructionalMethod
{
    NSMutableSet *types = [NSMutableSet new];
    for(RegistrationPlannedSectionMeetingPattern *mp in self.meetingPatterns) {
        if(mp.instructionalMethodCode) {
            [types addObject:mp.instructionalMethodCode];
        }
    }
    if([types count] == 0) return nil;
    return [[types allObjects] componentsJoinedByString:@", "];

}

-(NSDateFormatter *)dateFormatter
{
    if(_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd"];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    return _dateFormatter;
}

-(NSDateFormatter *)timeFormatter
{
    if(_timeFormatter == nil) {
        _timeFormatter = [[NSDateFormatter alloc] init];
        [_timeFormatter setDateFormat:@"HH:mm'Z'"];
        [_timeFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    return _timeFormatter;
}

-(NSDateFormatter *)displayDateFormatter
{
    if(_displayDateFormatter == nil) {
        _displayDateFormatter = [[NSDateFormatter alloc] init];
        [_displayDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_displayDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_displayDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    return _displayDateFormatter;
}

-(NSDateFormatter *)displayTimeFormatter
{
    if(_displayTimeFormatter == nil) {
        _displayTimeFormatter = [[NSDateFormatter alloc] init];
        [_displayTimeFormatter setDateStyle:NSDateFormatterNoStyle];
        [_displayTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return _displayTimeFormatter;
}

- (void) setGradingType:(NSString *)gradingType
{
    _gradingType = gradingType;
    
    if ([_gradingType caseInsensitiveCompare:kAudit] == NSOrderedSame){
        _isAudit = YES;
    } else if ([_gradingType caseInsensitiveCompare:kPassNoPass] == NSOrderedSame){
        _isPassFail = YES;
    } else {
        _isGraded = YES;
    }
}

-(BOOL) isVariableCredit
{
    if(_variableCreditOperator) {
        return YES;
    } else if (_minimumCredits && _maximumCredits) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[RegistrationPlannedSection class]]) {
        return NO;
    }
    
    RegistrationPlannedSection *other = (RegistrationPlannedSection *)object;
    
    return [self.sectionId isEqualToString:other.sectionId] && [self.termId
                                                         isEqualToString:other.termId];
}

@end
