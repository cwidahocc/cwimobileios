//
//  ImportantNumbersViewController
//  Mobile
//
//  Created by Jason Hocker on 9/28/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImportantNumbersDirectoryEntry.h"
#import "EllucianSectionedUITableViewController.h"
#import "Module.h"
#import "Ellucian_GO-Swift.h"

@interface ImportantNumbersViewController : EllucianSectionedUITableViewController<NSFetchedResultsControllerDelegate, UISearchBarDelegate, EllucianMobileLaunchableControllerProtocol, UISearchResultsUpdating>

@property (strong, nonatomic) Module *module;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *searchFetchedResultsController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end
