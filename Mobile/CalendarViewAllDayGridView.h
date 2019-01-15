//
//  CalendarViewAllDayGridView.h
//  Mobile
//
//  Created by Jason Hocker on 10/6/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Ellucian_GO-Swift.h"
#import "CalendarViewDayView.h"
#import "CalendarViewEvent.h"
#import "CalendarViewDayGridView.h"

@interface CalendarViewAllDayGridView : UIView {
    unsigned int eventCount;
}

@property (nonatomic, strong) CalendarViewDayView *dayView;
@property (readonly) BOOL hasAllDayEvents;

- (void)addEvent:(CalendarViewEvent *)event;
- (void)resetCachedData;

@end
