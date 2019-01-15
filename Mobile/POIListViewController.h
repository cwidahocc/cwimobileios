//
//  POIListViewController.h
//  Mobile
//
//  Created by Jason Hocker on 9/7/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Module.h"

@interface POIListViewController : UITableViewController<NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *searchFetchedResultsController;
@property (strong, nonatomic) Module *module;

@end
