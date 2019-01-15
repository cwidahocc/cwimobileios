//
//  EllucianUITableViewController.h
//  Mobile
//
//  Created by Jason Hocker on 12/12/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EllucianUITableViewController : UITableViewController

@property (strong, nonatomic) UIView *noDataView;

-(void) showNoDataView:(NSString *) message;
-(void) hideNoDataView;
@end
