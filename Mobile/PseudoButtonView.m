//
//  PseudoButtonView.m
//  Mobile
//
//  Created by jkh on 9/6/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "PseudoButtonView.h"

@interface PseudoButtonView ()

@property (strong, nonatomic) UIColor *originalColor;
@property (weak, nonatomic) id target;
@property (assign, nonatomic) SEL action;

@end

@implementation PseudoButtonView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void) setAction:(SEL)action withTarget:(id)target
{
    _target = target;
    _action = action;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    _originalColor = self.backgroundColor;
    self.backgroundColor = [UIColor grayColor];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    self.backgroundColor = _originalColor;
    self.originalColor = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_action withObject:self];
#pragma clang diagnostic pop

}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.backgroundColor =  self.originalColor;
    self.originalColor = nil;
}


@end
