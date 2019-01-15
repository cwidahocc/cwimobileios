//
//  CalendarViewDayViewDelegate.h
//  Mobile
//
//  Created by Jason Hocker on 10/6/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//


@class CalendarViewEvent;

@protocol CalendarViewDayViewDelegate <NSObject>

@optional
- (void)dayView:(CalendarViewDayView *)dayView eventTapped:(CalendarViewEvent *)event;

@end