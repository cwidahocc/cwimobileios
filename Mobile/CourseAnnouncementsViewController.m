//
//  CourseAnnouncementsViewController.m
//  Mobile
//
//  Created by jkh on 6/4/13.
//  Copyright (c) 2013-2014 Ellucian. All rights reserved.
//

#import "CourseAnnouncementsViewController.h"
#import "CourseAnnouncement.h"
#import "CourseAnnouncementDetailViewController.h"
#import "Ellucian_GO-Swift.h"

@interface CourseAnnouncementsViewController () <CourseDetailViewControllerProtocol>

@property (strong, nonatomic) NSDateFormatter *datetimeFormatter;
@property (strong, nonatomic) NSDateFormatter *datetimeOutputFormatter;

@end

@implementation CourseAnnouncementsViewController

@synthesize module_;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.translucent = NO;
    
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    self.navigationItem.title = self.courseNameAndSectionNumber;
    [self fetchAnnouncements:self];
}

-(NSString *)courseNameAndSectionNumber
{
    return [NSString stringWithFormat:@"%@-%@", self.courseName, self.courseSectionNumber];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self sendView:@"Course activity list" moduleName:self.module.name];
    
}
- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"CourseAnnouncement" inManagedObjectContext:self.module.managedObjectContext];
    [fetchRequest setEntity:entity];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"sectionId == %@", self.sectionId];
    NSArray *sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc]
                                                          initWithKey:@"date" ascending:YES]];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.module.managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
    
}

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 66;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id  sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    NSInteger numberOfObjects = [sectionInfo numberOfObjects];
    
    if(numberOfObjects == 0 ){
        [self showNoDataView:NSLocalizedString(@"No Announcements Recorded", @"no course announcements recorded message")];
    } else {
        [self hideNoDataView];
    }
    return numberOfObjects;
}


#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Announcement Cell"];
    CourseAnnouncement *announcement = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:1];
    titleLabel.text = announcement.title;
    UILabel *contentLabel = (UILabel *)[cell viewWithTag:2];
    contentLabel.text = announcement.content;
    UILabel *dateLabel = (UILabel *)[cell viewWithTag:3];
    dateLabel.text = [self.datetimeOutputFormatter stringFromDate:announcement.date];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self performSegueWithIdentifier:@"Show Announcement Detail" sender:self.tableView];
    
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - fetch announcements
- (void) fetchAnnouncements:(id)sender {
    
    NSManagedObjectContext *importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    importContext.parentContext = self.module.managedObjectContext;

    NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@/announcements?term=%@", [self.module propertyForKey:@"ilp"], [[[CurrentUser sharedInstance] userid] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]], [self.sectionId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]], [self.termId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    
    [importContext performBlock: ^{
        
        NSError *error;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        });
        AuthenticatedRequest *authenticatedRequest = [AuthenticatedRequest new];
        NSData *responseData = [authenticatedRequest requestURL:[NSURL URLWithString:urlString] fromView:self];

        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
        if(responseData) {
            NSArray* json = [NSJSONSerialization
                             JSONObjectWithData:responseData
                             options:kNilOptions
                             error:&error];
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CourseAnnouncement"];
            //request.predicate = [NSPredicate predicateWithFormat:@"termId == %@ && sectionId == %@", self.termId, self.sectionId];
            request.predicate = [NSPredicate predicateWithFormat:@"sectionId == %@", self.sectionId];
            
            NSArray * oldObjects = [importContext executeFetchRequest:request error:&error];
            for (CourseAnnouncement* oldObject in oldObjects) {
                [importContext deleteObject:oldObject];
            }
            
            for(NSDictionary *jsonDictionary in [json valueForKey:@"items"]) {
                CourseAnnouncement *entry = [NSEntityDescription insertNewObjectForEntityForName:@"CourseAnnouncement" inManagedObjectContext:importContext];
                
                entry.sectionId = self.sectionId;
                entry.title = [jsonDictionary objectForKey:@"title"];
                entry.courseName = [jsonDictionary objectForKey:@"courseName"];
                entry.courseSectionNumber = [jsonDictionary objectForKey:@"courseSectionNumber"];
                if([jsonDictionary objectForKey:@"content"] != [NSNull null]) {
                    entry.content = [jsonDictionary objectForKey:@"content"];
                }
                if([jsonDictionary objectForKey:@"date"] != [NSNull null]) {
                    entry.date = [self.datetimeFormatter dateFromString:[jsonDictionary objectForKey:@"date"]];
                }
                entry.website = [jsonDictionary objectForKey:@"website"];
            }
        }
        
        if (![importContext save:&error]) {
            NSLog(@"Could not save to main context after update to course events: %@", [error userInfo]);
        }
        
        [importContext.parentContext performBlock:^{
            NSError *parentError = nil;
            if(![importContext.parentContext save:&parentError]) {
                NSLog(@"Could not save to store after update to course events: %@", [error userInfo]);
            }
        }];
    }
     ];
    
}

- (NSDateFormatter *)datetimeFormatter {
    if (_datetimeFormatter == nil) {
        _datetimeFormatter = [[NSDateFormatter alloc] init];
        [_datetimeFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [_datetimeFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    return _datetimeFormatter;
}

- (NSDateFormatter *)datetimeOutputFormatter {
    if (_datetimeOutputFormatter == nil) {
        _datetimeOutputFormatter = [[NSDateFormatter alloc] init];
        [_datetimeOutputFormatter setDateStyle:NSDateFormatterShortStyle];
        [_datetimeOutputFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return _datetimeOutputFormatter;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"Show Announcement Detail"])
    {
        UITableView *tableView = sender;
        NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
        CourseAnnouncement *announcement = [self.fetchedResultsController objectAtIndexPath:indexPath];
        CourseAnnouncementDetailViewController *detailController = [segue destinationViewController];
        detailController.courseName = announcement.courseName;
        detailController.courseSectionNumber = announcement.courseSectionNumber;
        detailController.itemTitle = announcement.title;
        detailController.itemContent = announcement.content;
        detailController.itemLink = [announcement.website stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        detailController.itemPostDateTime = announcement.date;
        detailController.module = self.module;
    }
}


@end
