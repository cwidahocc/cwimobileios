//
//  CalendarViewAllDayGridView.m
//  Mobile
//
//  Created by Jason Hocker on 10/6/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import "CalendarViewAllDayGridView.h"

static const unsigned int ALL_DAY_VIEW_EMPTY_SPACE       = 3;

@implementation CalendarViewAllDayGridView


- (BOOL)hasAllDayEvents {
    return eventCount > 0;
}

- (void)resetCachedData {
    eventCount = 0;
}

- (void)setDay:(NSDate *)day {
    [self resetCachedData];    
    [self setNeedsLayout];
    [self.dayView.gridView setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    int height = 0;
    
    self.dayView.gridView.frame =  CGRectMake(self.dayView.gridView.frame.origin.x, self.frame.size.height,
                                              self.dayView.gridView.frame.size.width, self.dayView.gridView.frame.size.height);
    
    self.dayView.scrollView.contentSize = CGSizeMake(self.dayView.scrollView.contentSize.width,
                                                     CGRectGetHeight(self.bounds) + CGRectGetHeight(self.dayView.gridView.bounds));
    int events = 0;
    for (id view in self.subviews) {

        if ([NSStringFromClass([view class])isEqualToString:@"CalendarViewDayEventView"]) {

            CalendarViewDayEventView *ev = view;

            CGFloat x = (int)self.dayView.gridView.lineX;
            CGFloat y = ALL_DAY_VIEW_EMPTY_SPACE + (ALL_DAY_VIEW_EMPTY_SPACE + ev.frame.size.height) * events;
            CGFloat w = (int)((self.frame.size.width - self.dayView.gridView.lineX) * 0.99);
            CGFloat h = (int)ev.frame.size.height;
            
            ev.frame = CGRectMake(x, y, w, h);
            events++;
            height += h + ALL_DAY_VIEW_EMPTY_SPACE;
            [ev setNeedsDisplay];
        }
    }
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width,
                            height);

}

- (void)addEvent:(CalendarViewEvent *)event {
    CalendarViewDayEventView *eventView = [[CalendarViewDayEventView alloc] init];
    eventView.dayView = self.dayView;
    eventView.event = event;
    eventView.label1.text = event.line1;
    eventView.label2.text = event.line2;
    eventView.label3.text = event.line3;
    
    
    [self addSubview:eventView];
    
    eventCount++;

    [self setNeedsLayout];
    [self.dayView.gridView setNeedsLayout];
}

@end
