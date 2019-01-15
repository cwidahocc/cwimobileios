//
//  CalendarViewEvent.h
//  Mobile
//
//  Created by Jason Hocker on 10/6/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import "CalendarViewEvent.h"

static const NSUInteger MINUTES_IN_HOUR = 60;
static const NSUInteger DAY_IN_MINUTES = 1440;

@implementation CalendarViewEvent

#define DATE_CMP(X, Y) ([X year] == [Y year] && [X month] == [Y month] && [X day] == [Y day])

- (NSUInteger)minutesSinceMidnight {
	NSUInteger fromMidnight = 0;
	
	NSDateComponents *displayComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:_displayDate];
	NSDateComponents *startComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:_start];
	
	if (DATE_CMP(startComponents, displayComponents)) {
		fromMidnight = [startComponents hour] * MINUTES_IN_HOUR + [startComponents minute];
	}

	return fromMidnight;
}

- (NSUInteger)durationInMinutes {
	NSUInteger duration = 0;
	
	NSDateComponents *displayComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:_displayDate];
	NSDateComponents *startComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:_start];
	NSDateComponents *endComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:_end];
	
	if (DATE_CMP(endComponents, displayComponents)) {
		if (DATE_CMP(startComponents, displayComponents)) {
			duration = (int) (([_end timeIntervalSince1970] - [_start timeIntervalSince1970]) / (double) MINUTES_IN_HOUR);
		} else {
			duration = [endComponents hour] * MINUTES_IN_HOUR + [endComponents minute];
		}
	} else {
		duration = DAY_IN_MINUTES - [self minutesSinceMidnight];
	}
	return duration;
}

-(BOOL) isAllDayForDisplayDate {
    NSDateComponents *displayComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:_displayDate];
    NSDateComponents *startComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal) fromDate:_start];
    
    return DATE_CMP(startComponents, displayComponents) && self.allDay;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![other isKindOfClass:[self class]])
        return NO;
    return [self isEqualToCalendarViewEvent:other];
}

- (BOOL)isEqualToCalendarViewEvent:(CalendarViewEvent *)event {
    if (self == event)
        return YES;
    
    if (!([self.line1 isEqual:[event line1]] || (!self.line1 && ![event line1])))
        return NO;
    if (!([self.line2 isEqual:[event line2]] || (!self.line2 && ![event line2])))
        return NO;
    if (!([self.line3 isEqual:[event line3]] || (!self.line3 && ![event line3])))
        return NO;
    if (!([self.start isEqualToDate:[event start]] || (!self.start && ![event start])))
        return NO;
    if (!([self.end isEqualToDate:[event end]] || (!self.end && ![event end])))
        return NO;
    if (self.allDay != [event allDay])
        return NO;
    if(![self.userInfo isEqualToDictionary:[event userInfo]])
        return NO;

    return YES;
}

- (NSUInteger)hash {
    return [self.line1 hash];
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p, %@, %@, %@>",
            NSStringFromClass([self class]), self, self.line1, self.line2, self.line3];
}

#undef DATE_CMP


@end
