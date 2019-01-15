//
//  EllucianSectionedUITableViewController.m
//  Mobile
//
//  Created by jkh on 2/12/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "EllucianSectionedUITableViewController.h"
#import "Ellucian_GO-Swift.h"

@interface EllucianSectionedUITableViewController ()

@end

@implementation EllucianSectionedUITableViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"Header"];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView* h = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"Header"];

    if (![h.backgroundColor isEqual: [UIColor accent]]) {
        
        h.contentView.backgroundColor = [UIColor accent];
        
        UILabel* headerLabel = [UILabel new];
        headerLabel.tag = 1;
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.textColor = [UIColor subheaderText];
        headerLabel.font = [UIFont boldSystemFontOfSize:16];
        [headerLabel setMinimumScaleFactor:.5f];

        [h.contentView addSubview:headerLabel];
        
        headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [h.contentView addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[headerLabel]"
                                                     options:0 metrics:nil
                                                       views:@{@"headerLabel":headerLabel}]];
        [h.contentView addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[headerLabel]|"
                                                 options:0 metrics:nil
                                                   views:@{@"headerLabel":headerLabel}]];
        
        
    }
    UILabel* headerLabel = (UILabel*)[h.contentView viewWithTag:1];
    headerLabel.text = [self tableView:tableView stringForTitleForHeaderInSection:section];
    
    return h;
}
    
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([tableView.dataSource tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0;
    } else {
        return 18;
    }
}

//Override in children
-(NSString *)tableView:(UITableView *)tableView stringForTitleForHeaderInSection:(NSInteger)section;
{
    return @"";
}

@end
