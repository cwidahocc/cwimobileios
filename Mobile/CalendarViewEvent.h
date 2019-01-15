//
//  CalendarViewEvent.h
//  Mobile
//
//  Created by Jason Hocker on 10/6/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CalendarViewEvent : NSObject


@property (nonatomic,strong) NSString *line1;
@property (nonatomic,strong) NSString *line2;
@property (nonatomic,strong) NSString *line3;
@property (nonatomic,strong) NSDate *start;
@property (nonatomic,strong) NSDate *end;
@property (nonatomic,strong) NSDate *displayDate;
@property (readwrite,assign) BOOL allDay;
@property (nonatomic, strong) NSDictionary *userInfo;

- (NSUInteger)durationInMinutes;
- (NSUInteger)minutesSinceMidnight;
-(BOOL) isAllDayForDisplayDate;
@end