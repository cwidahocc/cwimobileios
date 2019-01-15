//
//  CalendarViewDayGridView.m
//  Mobile
//
//  Created by Jason Hocker on 10/6/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import "CalendarViewDayGridView.h"

static const unsigned int HOURS_IN_DAY = 25; // Beginning and end of day is include twice

@implementation CalendarViewDayGridView

- (void)addEvent:(CalendarViewEvent *)event {
    CalendarViewDayEventView *eventView = [[CalendarViewDayEventView alloc] init];
    eventView.dayView = self.dayView;
    eventView.event = event;
    eventView.label1.text = event.line1;
    eventView.label2.text = event.line2;
    eventView.label3.text = event.line3;
    
    [self addSubview:eventView];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat maxTextWidth = 0, totalTextHeight = 0;
    CGSize hourSize[25];
    
    register unsigned int i;
    
    for (i=0; i < HOURS_IN_DAY; i++) {
        NSString *hourLabelText = [[CalendarViewDayView hourLabels] objectAtIndex:i ] ;

        
        hourSize[i] = [hourLabelText sizeWithAttributes:@{NSFontAttributeName: self.dayView.boldFont}];
        
        totalTextHeight += hourSize[i].height;
        
        if (hourSize[i].width > maxTextWidth) {
            maxTextWidth = hourSize[i].width;
        }
    }
    
    CGFloat y;
    const CGFloat spaceBetweenHours = (self.bounds.size.height - totalTextHeight) / (HOURS_IN_DAY - 1);
    CGFloat rowY = 0;
    
    for (i=0; i < HOURS_IN_DAY; i++) {
        if ([self isStandardLayout]) {
            textRect[i] = CGRectMake(CGRectGetMinX(self.bounds) + 8,
                                     
                                     rowY,
                                     maxTextWidth,
                                     hourSize[i].height);
            
            y = rowY + ((CGRectGetMaxY(textRect[i]) - CGRectGetMinY(textRect[i])) / 2.f);
            lineY[i] = y;
            dashedLineY[i] = CGRectGetMaxY(textRect[i]) + (spaceBetweenHours / 2.f);
            
            
            rowY += hourSize[i].height + spaceBetweenHours;
        } else {
            textRect[i] = CGRectMake(CGRectGetMaxX(self.bounds) - maxTextWidth - 8,
                                     
                                     rowY,
                                     maxTextWidth,
                                     hourSize[i].height);
            
            y = rowY + ((CGRectGetMaxY(textRect[i]) - CGRectGetMinY(textRect[i])) / 2.f);
            lineY[i] = y;
            dashedLineY[i] = CGRectGetMaxY(textRect[i]) + (spaceBetweenHours / 2.f);
            
            
            rowY += hourSize[i].height + spaceBetweenHours;
        }
    }
    
    if ([self isStandardLayout]) {
        _lineX = maxTextWidth + 16;
    } else {
        _lineX = CGRectGetMaxX(self.bounds) - maxTextWidth - 16;
    }
    
    NSArray *subviews = self.subviews;
    NSUInteger max = [subviews count];
    CalendarViewDayEventView *curEv = nil, *prevEv = nil, *firstEvent = nil;
    const CGFloat spacePerMinute = (lineY[1] - lineY[0]) / 60.f;

    
    for (i=0; i < max; i++) {
        if (![NSStringFromClass([[subviews objectAtIndex:i] class])isEqualToString:@"CalendarViewDayEventView"]) {
            continue;
        }
        
        prevEv = curEv;
        curEv = [subviews objectAtIndex:i];
        
        if ([self isStandardLayout]) {
            
            curEv.frame = CGRectMake((int) _lineX,
                                     (int) (spacePerMinute * [curEv.event minutesSinceMidnight] + lineY[0] + 1), //for 1px padding
                                     
                                     (int) (self.bounds.size.width - _lineX),
                                     (int) ((spacePerMinute * [curEv.event durationInMinutes])-1));
        } else {
            
            curEv.frame = CGRectMake(0,
                                     (int) (spacePerMinute * [curEv.event minutesSinceMidnight] + lineY[0] + 1), //for 1px padding
                                     (int) (_lineX),
                                     (int) ((spacePerMinute * [curEv.event durationInMinutes])-1));
        }
        
        /*
         * Layout intersecting events to two columns.
         */
        if (CGRectIntersectsRect(curEv.frame, prevEv.frame))
        {
            prevEv.frame = CGRectMake((int) (prevEv.frame.origin.x),
                                      (int) (prevEv.frame.origin.y),
                                      (int) (prevEv.frame.size.width / 2.f),
                                      (int) (prevEv.frame.size.height));
            
            curEv.frame = CGRectMake((int) (curEv.frame.origin.x + (curEv.frame.size.width / 2.f) + 1),
                                     (int) (curEv.frame.origin.y),
                                     (int) ((curEv.frame.size.width / 2.f) - 1),
                                     (int) (curEv.frame.size.height));
        }
        
        if(curEv.frame.size.height < 52) {
            curEv.label3.text = @"";
            if(curEv.frame.size.height < 37) {
                curEv.label2.text = @"";
                if(curEv.frame.size.height < 22) {
                    curEv.label1.text = @"";
                }
            }
        }
        
        [curEv setNeedsDisplay];
        
        if (!firstEvent || curEv.frame.origin.y < firstEvent.frame.origin.y) {
            firstEvent = curEv;
        }
    }
    
    if (self.dayView.autoScrollToFirstEvent) {
        if (!firstEvent || self.dayView.allDayGridView.hasAllDayEvents) {
            [self scrollToEvent:nil];
        } else {
            [self scrollToEvent:firstEvent];
        }
    }
}

-(void) scrollToEvent:(CalendarViewDayEventView *)event {
    CGPoint autoScrollPoint;
    if(event) {
        
        CGFloat spacePerMinute = (lineY[1] - lineY[0]) / 60.f;
        int minutesSinceLastHour = ([event.event minutesSinceMidnight] % 60);
        CGFloat padding = minutesSinceLastHour * spacePerMinute + 7.5;
        
        autoScrollPoint = CGPointMake(0, event.frame.origin.y - padding);
        CGFloat maxY = self.dayView.scrollView.contentSize.height - CGRectGetHeight(self.dayView.scrollView.bounds);
        
        if (autoScrollPoint.y > maxY) {
            autoScrollPoint.y = maxY;
        }
        
    } else {
        autoScrollPoint = CGPointMake(0, 0);
    }
    [self.dayView.scrollView setContentOffset:autoScrollPoint animated:YES];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, event);
}

- (void)drawRect:(CGRect)rect {
    register unsigned int i;
    
    const CGContextRef c = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(c, [[UIColor lightGrayColor] CGColor]);
    CGContextSetLineWidth(c, 0.5);
    CGContextBeginPath(c);
    
    for (i=0; i < HOURS_IN_DAY; i++) {
        NSString *hourLabelText = [[CalendarViewDayView hourLabels] objectAtIndex:i ] ;

        NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        textStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        textStyle.alignment = NSTextAlignmentRight;
        [hourLabelText drawInRect:textRect[i] withAttributes:@{NSFontAttributeName:self.dayView.boldFont, NSParagraphStyleAttributeName:textStyle}];
        
        CGContextMoveToPoint(c, self.lineX, lineY[i]);
        if ([self isStandardLayout]) {
            CGContextAddLineToPoint(c, self.bounds.size.width, lineY[i]);
        } else {
            CGContextAddLineToPoint(c, 0, lineY[i]);
        }

    }
    
    CGContextClosePath(c);
    CGContextSaveGState(c);
    CGContextDrawPath(c, kCGPathFillStroke);
    CGContextRestoreGState(c);
    
    CGContextSetLineWidth(c, 0.5);
    CGFloat dash1[] = {2.0, 1.0};
    CGContextSetLineDash(c, 0.0, dash1, 2);
    
    CGContextBeginPath(c);
    
    for (i=0; i < (HOURS_IN_DAY - 1); i++) {
        CGContextMoveToPoint(c, self.lineX, dashedLineY[i]);
        if ([self isStandardLayout]) {
            CGContextAddLineToPoint(c, self.bounds.size.width, dashedLineY[i]);
        } else {
            CGContextAddLineToPoint(c, 0, dashedLineY[i]);
        }

    }
    
    CGContextClosePath(c);
    CGContextSaveGState(c);
    CGContextDrawPath(c, kCGPathFillStroke);
    CGContextRestoreGState(c);
}

-(BOOL) isStandardLayout {
    if ([UIView instancesRespondToSelector:@selector(userInterfaceLayoutDirectionForSemanticContentAttribute:)]) {
        return [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute] == UIUserInterfaceLayoutDirectionLeftToRight;
    } else {
        return YES;
    }
}

@end
