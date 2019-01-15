//
//  CalendarViewDayViewDataSource.h
//  Mobile
//
//  Created by Jason Hocker on 10/6/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

@class CalendarViewDayView;

@protocol CalendarViewDayViewDataSource <NSObject>

- (NSArray *)dayView:(CalendarViewDayView *)dayView eventsFor:(NSDate *)date;

@end
