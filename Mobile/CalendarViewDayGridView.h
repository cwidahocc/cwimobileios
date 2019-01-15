//
//  CalendarViewDayGridView.h
//  Mobile
//
//  Created by Jason Hocker on 10/6/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalendarViewDayView.h"
#import "CalendarViewAllDayGridView.h"
#import "Ellucian_GO-Swift.h"

@interface CalendarViewDayGridView : UIView {
    CGFloat lineY[25];
    CGFloat dashedLineY[25];
    CGRect textRect[25];
}

- (void)addEvent:(CalendarViewEvent *)event;
-(void) scrollToEvent:(CalendarViewDayEventView *)event;

@property (nonatomic, strong) CalendarViewDayView *dayView;
@property (readonly) CGFloat lineX;

@end
