//
//  EllucianUITableViewController.m
//  Mobile
//
//  Created by Jason Hocker on 12/12/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import "EllucianUITableViewController.h"

@interface EllucianUITableViewController ()

@property (strong, nonatomic) UILabel *noMatchesLabel;
@property (strong, nonatomic) NSString *message;
@end

@implementation EllucianUITableViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"Header"];
}

-(UIView *) noDataView
{
    if(_noDataView == nil) {
        _noDataView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 60.f)];
        
        UIView *constrainedView = [UIView new];
        [constrainedView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_noDataView addSubview:constrainedView];
        
        [_noDataView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[constrainedView]|" options:0 metrics:nil views:@{@"constrainedView":constrainedView}]];
        [_noDataView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[constrainedView]|" options:0 metrics:nil views:@{@"constrainedView":constrainedView}]];

        
        self.noMatchesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,60)];
        self.noMatchesLabel.font = [UIFont systemFontOfSize:16];
        self.noMatchesLabel.numberOfLines = 3;
        self.noMatchesLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.noMatchesLabel.textAlignment =  NSTextAlignmentCenter;
        if(self.message) {
            self.noMatchesLabel.text = self.message;
        } else {
            self.noMatchesLabel.text = NSLocalizedString(@"No Data", @"generic message for no data present");
        }
        constrainedView.backgroundColor = [UIColor whiteColor];
        _noDataView.hidden = YES;
        
        self.noMatchesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [constrainedView addSubview:self.noMatchesLabel];
        
        [constrainedView addConstraint:[NSLayoutConstraint constraintWithItem:self.noMatchesLabel
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:constrainedView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0]];
        [constrainedView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[label]-10-|"
                                                                                 options:NSLayoutFormatAlignAllCenterY metrics:nil
                                                                                   views:@{@"label":self.noMatchesLabel}]];

        
        [self.tableView insertSubview:_noDataView belowSubview:self.tableView];
        
        
    }
    return _noDataView;
}

-(void) showNoDataView:(NSString *) message
{
    self.noDataView.hidden = NO;
    
    if(message) {
        self.message = message;
        self.noMatchesLabel.text = message;
    }
}
-(void) hideNoDataView
{
    self.noDataView.hidden = YES;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
        if(self.noDataView && self.noDataView.hidden == NO) {
            [self->_noDataView removeFromSuperview];
            self->_noDataView = nil;
            self.noDataView.hidden = NO;
        }
    }];
}

@end
