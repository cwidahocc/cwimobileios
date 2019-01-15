//
//  CalendarViewDayView
//  Mobile
//
//  Created by Jason Hocker on 9/18/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CalendarViewDayView.h"
#import "CalendarViewEvent.h"

@class CalendarViewDayView;

@interface CalendarViewDayEventView : UIView {

}

@property (nonatomic, strong) CalendarViewDayView *dayView;
@property (nonatomic, strong) CalendarViewEvent *event;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
@property (weak, nonatomic) IBOutlet UILabel *label3;

@property (nonatomic, retain) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, retain) UIColor *fontColor UI_APPEARANCE_SELECTOR;

@end
