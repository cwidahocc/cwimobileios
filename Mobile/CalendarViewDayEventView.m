//
//  CalendarViewDayEventView
//  Mobile
//
//  Created by Jason Hocker on 9/18/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import "CalendarViewDayEventView.h"
#import "CalendarViewDayGridView.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kCornerRadius = 6.0;

@implementation CalendarViewDayEventView
@dynamic backgroundColor;

- (IBAction)eventTapped:(UIGestureRecognizer *)sender {
    [self.dayView.delegate dayView:self.dayView eventTapped:self.event];
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        NSArray *theView =  [[NSBundle mainBundle] loadNibNamed:@"CalendarViewDayEventView" owner:self options:nil];
        UIView *nv = [theView objectAtIndex:0];
        self = (CalendarViewDayEventView *)nv;
        
        UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget: self
                                                action: @selector(eventTapped:)];
        [self addGestureRecognizer: tap];

        CALayer *layer = [self layer];
        layer.masksToBounds = YES;
        [layer setCornerRadius:kCornerRadius];
        
        self.isAccessibilityElement = YES;
        self.accessibilityTraits |= UIAccessibilityTraitButton;
    }
    return self;
}

- (void)setFontColor:(UIColor *)fontColor
{
    self.label1.textColor = fontColor;
    self.label2.textColor = fontColor;
    self.label3.textColor = fontColor;
}

-(NSString *) accessibilityLabel {
    return [NSString stringWithFormat:@"%@, %@, %@", self.label3.text, self.label1.text, self.label2.text];
}

- (void)accessibilityElementDidBecomeFocused
{
    [self.dayView.gridView scrollToEvent:self];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

@end
