//
//  RegistrationRefineSearchViewController.m
//  Mobile
//
//  Created by Jason Hocker on 8/20/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import "RegistrationRefineSearchViewController.h"
#import "RegistrationAcademicLevel.h"
#import "RegistrationLocation.h"

@interface RegistrationRefineSearchViewController ()

@end

@implementation RegistrationRefineSearchViewController

-(void) viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) return [self.locations count];
    if(section == 1) return [self.academicLevels count];
    return 0;
}

-(NSString *) labelText:(NSIndexPath *)indexPath
{
    if([indexPath section] == 0) {
        return [self.locations objectAtIndex:[indexPath row]];
    } else if([indexPath section] == 1) {
        return [self.academicLevels objectAtIndex:[indexPath row]];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath section] == 0) {
        return [self tableView:tableView locationCellForRow:[indexPath row]];
    } else if([indexPath section] == 1) {
        return [self tableView:tableView academicLevelCellForRow:[indexPath row]];
    }
    return nil;
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView locationCellForRow:(NSUInteger )row
{
    static NSString *CellIdentifier = @"Filter Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    RegistrationLocation *location = [self.locations objectAtIndex:row];
    
    UILabel *textLabel = (UILabel *)[cell viewWithTag:1];
    textLabel.text = location.name;
    
    cell.accessoryType = !location.unselected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView academicLevelCellForRow:(NSUInteger )row
{
    static NSString *CellIdentifier = @"Filter Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    RegistrationAcademicLevel *academicLevel = [self.academicLevels objectAtIndex:row];
    
    UILabel *textLabel = (UILabel *)[cell viewWithTag:1];
    textLabel.text = academicLevel.name;
    
    cell.accessoryType = !academicLevel.unselected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView stringForTitleForHeaderInSection:(NSInteger)section
{
    if(section == 0) return NSLocalizedString(@"Locations", "Locations label for registration filter");
    if(section == 1) return NSLocalizedString(@"Academic Levels", "Academic Levels label for registration filter");
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath section] == 0) {
        [self tableView:tableView didSelectLocationRowAtIndexPath:indexPath];
    } else if([indexPath section] == 1) {
        [self tableView:tableView didSelectAcademicLevelRowAtIndexPath:indexPath];
    }
    [self updateDoneButton];
}

- (void)tableView:(UITableView *)tableView didSelectLocationRowAtIndexPath:(NSIndexPath *)indexPath
{
    RegistrationLocation *location = [self.locations objectAtIndex:[indexPath row]];
    location.unselected = !location.unselected;

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = !location.unselected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectAcademicLevelRowAtIndexPath:(NSIndexPath *)indexPath
{
    RegistrationAcademicLevel *academicLevel = [self.academicLevels objectAtIndex:[indexPath row]];
    academicLevel.unselected = !academicLevel.unselected;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = !academicLevel.unselected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
    
- (IBAction)dismiss:(id)sender
{
    if([self.refineSearchDelegate respondsToSelector:@selector(registrationRefindSearchViewControllerSelectedLocations:acadLevels:)])
    {
        [self.refineSearchDelegate registrationRefindSearchViewControllerSelectedLocations:self.locations acadLevels:self.academicLevels];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) updateDoneButton
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"unselected == NO" ];
    NSArray *filteredLocations  = [self.locations filteredArrayUsingPredicate:predicate];
    NSArray *filteredAcademicLevels  = [self.academicLevels filteredArrayUsingPredicate:predicate];
    self.doneButton.enabled = ([filteredLocations count] > 0 || [self.locations count] == 0) && ([filteredAcademicLevels count] > 0 || [self.academicLevels count] == 0);
}

@end
