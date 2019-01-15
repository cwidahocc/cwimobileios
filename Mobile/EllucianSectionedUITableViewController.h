//
//  EllucianSectionedUITableViewController.h
//  Mobile
//
//  Created by jkh on 2/12/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "EllucianUITableViewController.h"

@interface EllucianSectionedUITableViewController : EllucianUITableViewController

//The string value to show in the section header in an UITableView of an EllucianUITableViewController
-(NSString *)tableView:(UITableView *)tableView stringForTitleForHeaderInSection:(NSInteger)section;
@end
