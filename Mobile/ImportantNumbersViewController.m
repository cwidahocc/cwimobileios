//
//  ImportantNumbersViewController
//  Mobile
//
//  Created by Jason Hocker on 9/28/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import "ImportantNumbersViewController.h"
#import "ImportantNumbersDetailViewController.h"
#import "Ellucian_GO-Swift.h"

@interface ImportantNumbersViewController ()

@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation ImportantNumbersViewController

@synthesize module_;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.accessibilityIdentifier = @"Important Numbers";
    
    self.navigationController.navigationBar.translucent = NO;
    self.searchBar.translucent = NO;
    
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    self.title = self.module.name;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.definesPresentationContext = YES;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    UIView *hudView = self.view;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:hudView animated:YES];
    NSString *loadingString = NSLocalizedString(@"Loading", @"loading message while waiting for data to load");
    hud.label.text = loadingString;
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString);
    
    [self fetchImportantNumbers];
    
    // Ensure that searchController will not persist
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuOpened:) name:@"SlidingViewOpenMenuAppearsNotification" object:nil];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self sendView:@"Important Number List" moduleName:self.module.name];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    _fetchedResultsController = [self newFetchedResultsControllerWithSearch:self.searchController.searchBar.text];
    return _fetchedResultsController;
}

// Ensure that searchController will not persist
-(void) menuOpened:(id)sender
{
    [self.searchController setActive:NO];
    self.searchController.searchBar.showsCancelButton = NO;
    self.searchController.searchBar.text = @"";
}


#pragma mark Fetch results controller management


- (NSFetchedResultsController *)newFetchedResultsControllerWithSearch:(NSString *)searchString
{

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ImportantNumbersDirectoryEntry"];
    NSMutableArray *subPredicates = [[NSMutableArray alloc] init];
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"(moduleName = %@)", self.module.internalKey];
    [subPredicates addObject:filterPredicate];
    
    if(searchString.length)
    {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@)", searchString];
        [subPredicates addObject:searchPredicate];
    }
    
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];
    
    request.sortDescriptors = [NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"category" ascending:YES ],[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES ],nil ];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                                managedObjectContext:self.module.managedObjectContext
                                                                                                  sectionNameKeyPath:@"category" cacheName:nil];
                                                                                                               
    
    aFetchedResultsController.delegate = self;
    
    
    NSError *error = nil;
    if (![aFetchedResultsController performFetch:&error])
    {
        NSLog(@"Error performing institution fetch with search string %@: %@", error, [error userInfo]);
    }
    
    return aFetchedResultsController;

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    NSArray *sections = self.fetchedResultsController.sections;
    if(sections.count > 0)
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        numberOfRows = [sectionInfo numberOfObjects];
    }
    return numberOfRows;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self sendEventToTracker1WithCategory:Analytics.UI_Action action:Analytics.List_Select label:@"Select Important Number" moduleName:self.module.name];
    [self performSegueWithIdentifier:@"Show Important Numbers Detail" sender:tableView];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Yellow Pages Directory Item Cell";
    
    UITableViewCell *cell =
    [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    ImportantNumbersDirectoryEntry *entry = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = entry.name;
    
    return cell;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            if (!(sectionIndex == 0 && [self.tableView numberOfSections] == 1))
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            if (!(sectionIndex == 0 && [self.tableView numberOfSections] == 1))
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - fetch ImportantNumbers

- (void) fetchImportantNumbers {
    
    NSManagedObjectContext *importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    importContext.parentContext = self.module.managedObjectContext;
    NSString *urlString = [self.module propertyForKey:@"numbers"];
    [importContext performBlock: ^{
        
        //download data
        NSError *error;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
        NSData *responseData = [NSData dataWithContentsOfURL: [NSURL URLWithString: urlString]];

        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
        if(responseData) {
            NSDictionary* json = [NSJSONSerialization
                                  JSONObjectWithData:responseData
                                  options:kNilOptions
                                  error:&error];
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ImportantNumbersDirectoryEntry"];
            request.predicate = [NSPredicate predicateWithFormat:@"moduleName = %@", self.module.internalKey];
            
            NSArray * oldObjects = [importContext executeFetchRequest:request error:&error];
            for (ImportantNumbersDirectoryEntry* oldObject in oldObjects) {
                [importContext deleteObject:oldObject];
            }
            
            //create/update objects
            for(NSDictionary *itemsDictionary in [json objectForKey:@"numbers"]) {
                ImportantNumbersDirectoryEntry *entity = [NSEntityDescription insertNewObjectForEntityForName:@"ImportantNumbersDirectoryEntry" inManagedObjectContext:importContext];
                entity.moduleName = self.module.internalKey;
                entity.name = [itemsDictionary objectForKey:@"name"];
                entity.category = [itemsDictionary objectForKey:@"category"];
                if([itemsDictionary objectForKey:@"phone"] != [NSNull null])
                    entity.phone = [itemsDictionary objectForKey:@"phone"];
                if([itemsDictionary objectForKey:@"extension"] != [NSNull null])    
                    entity.phoneExtension = [itemsDictionary objectForKey:@"extension"];
                if([itemsDictionary objectForKey:@"email"] != [NSNull null])
                    entity.email = [itemsDictionary objectForKey:@"email"];
                if([itemsDictionary objectForKey:@"buildingId"] != [NSNull null])
                    entity.buildingId = [itemsDictionary objectForKey:@"buildingId"];
                if([itemsDictionary objectForKey:@"latitude"] != [NSNull null])
                    entity.latitude = [itemsDictionary valueForKey:@"latitude"];
                if([itemsDictionary objectForKey:@"longitude"] != [NSNull null])
                    entity.longitude = [itemsDictionary valueForKey:@"longitude"];
                if([itemsDictionary objectForKey:@"campusId"] != [NSNull null])
                    entity.campusId = [itemsDictionary objectForKey:@"campusId"];
                if([itemsDictionary objectForKey:@"address"] != [NSNull null])
                    entity.address = [[itemsDictionary objectForKey:@"address"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                
                
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Poor Network Connection",@"title when data cannot load due to a poor netwrok connection") message:NSLocalizedString(@"Data could not be retrieved.",@"message when data cannot load due to a poor netwrok connection") preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* alertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
                [alert addAction:alertAction];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
        
        if (![importContext save:&error]) {
            NSLog(@"Could not save to main context after update to ImportantNumbers: %@", [error userInfo]);
        }
        
        //save to main context
        if (![importContext save:&error]) {
            NSLog(@"Could not save to main context after update to ImportantNumbers: %@", [error userInfo]);
        }
        
        //persist to store and update fetched result controllers
        [importContext.parentContext performBlock:^{
            NSError *parentError = nil;
            if(![importContext.parentContext save:&parentError]) {
                NSLog(@"Could not save to store after update to ImportantNumbers: %@", [error userInfo]);
               
            }
            [self.tableView reloadData];
        }];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    }];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([[segue identifier] isEqualToString:@"Show Important Numbers Detail"])
    {
        UITableView *tableView = sender;
        NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
        ImportantNumbersDirectoryEntry *directory = [self.fetchedResultsController objectAtIndexPath:indexPath];

        ImportantNumbersDetailViewController *vc = (ImportantNumbersDetailViewController *)[segue destinationViewController];
        vc.name = directory.name;
        vc.types = [NSArray arrayWithObject:directory.category];
        if([directory.latitude doubleValue] != 0 && [directory.longitude doubleValue] != 0) {
            vc.location = [[CLLocation alloc] initWithLatitude:[directory.latitude doubleValue] longitude:[directory.longitude doubleValue]];
        }
        vc.buildingId = directory.buildingId;
        vc.campusId = directory.campusId;
        vc.email = directory.email;
        vc.phone = directory.phone;
        vc.phoneExtension = directory.phoneExtension;
        vc.address = directory.address;
        vc.module = self.module;

        [self.searchController setActive:NO];
    }
}

-(NSString *)tableView:(UITableView *)tableView stringForTitleForHeaderInSection:(NSInteger)section
{
    NSFetchedResultsController *fetchController = self.fetchedResultsController;
    return [[[fetchController sections] objectAtIndex:section] name];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self sendEventToTracker1WithCategory:Analytics.UI_Action action:Analytics.Search label:@"Search" moduleName:nil];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    _fetchedResultsController = nil;
    [self.tableView reloadData];
}

@end
