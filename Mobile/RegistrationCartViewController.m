//
//  RegistrationCartViewController.m
//  Mobile
//
//  Created by jkh on 11/18/13.
//  Copyright (c) 2013 - 2014 Ellucian. All rights reserved.
//

#import "RegistrationCartViewController.h"
#import "MBProgressHUD.h"
#import "RegistrationPlannedSection.h"
#import "RegistrationPlannedSectionInstructor.h"
#import "RegistrationPlannedSectionMeetingPattern.h"
#import "RegistrationTerm.h"
#import <AddressBook/AddressBook.h>
#import "MBProgressHUD.h"
#import "RegistrationResultsViewController.h"
#import "RegistrationTabBarController.h"
#import "RegistrationPlannedSectionDetailViewController.h"
#import "Ellucian_GO-Swift.h"

@interface RegistrationCartViewController ()
@property (strong, nonatomic) UIBarButtonItem *registerButton;
@property (nonatomic, strong) NSNumberFormatter *creditsFormatter;
@property (nonatomic, strong) NSString *termNeedingPIN;
@end

@implementation RegistrationCartViewController

@synthesize module_;

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self sendView:@"Registration Cart list" moduleName:self.module.name];
    [self updateStatusBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    
    if ([self traitCollection].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    }

    UINib *cellNib = [UINib nibWithNibName:@"RegistrationCartTermHeaderView" bundle:nil];
    [self.tableView registerNib:cellNib forHeaderFooterViewReuseIdentifier:@"RegistrationCartTermHeaderView"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable:) name:kRegistrationPlanDataReloaded object:nil];

    self.navigationItem.title = [self.module name];

    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    self.registerButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Register", "Register button") style:UIBarButtonItemStylePlain target:self action:@selector(startRegistration:)];

    UIImage *registerButtonImage = [UIImage imageNamed:@"Registration Button"];
    [self.navigationController.toolbar setBackgroundImage:registerButtonImage forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
    self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    
    self.toolbarItems = [NSArray arrayWithObjects:flexibleItem, self.registerButton, flexibleItem, nil];
    self.navigationController.navigationBar.translucent = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable:) name:kRegistrationItemRemovedFromCart object:nil];
}

#pragma mark - variables from tab
-(RegistrationTabBarController *) registrationTabController
{
    return  (RegistrationTabBarController *)[self tabBarController];
}

-(NSString *) planId
{
    return self.registrationTabController.planId;
}

-(BOOL) registrationAllowed
{
    return self.registrationTabController.registrationAllowed;
}

#pragma mark - table

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // rows in section 0 should not be selectable
    if ( indexPath.section == 0 ) return nil;
    return indexPath;
}


- (UITableViewCell *)tableView:(UITableView *)tableView configureCell:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Registration Ineligible Cell"];
        UILabel *label = (UILabel *)[cell viewWithTag:20];
        label.text = self.registrationTabController.ineligibleMessage;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.contentView setNeedsLayout];
        [cell.contentView layoutIfNeeded];
        return cell;
    }
    RegistrationTerm *term = [self registrationTermForSection:indexPath.section];
    NSArray *plannedSections = [self sectionsForTerm: term filteredByAuthorizationCodeRequired:(indexPath.section <= self.registrationTabController.terms.count)];
    RegistrationPlannedSection *plannedSection = [plannedSections objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"Registration Planned Course Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UILabel *line1aLabel = (UILabel *)[cell viewWithTag:1];
    line1aLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course name-section number", @"Localizable", [NSBundle mainBundle], @"%@-%@", @"course name-section number"), plannedSection.courseName, plannedSection.courseSectionNumber];
    NSString *cellLabel = line1aLabel.accessibilityLabel;
    
    UILabel *line1bLabel = (UILabel *)[cell viewWithTag:6];
    if(plannedSection.instructionalMethod) {
        line1bLabel.text = [NSString stringWithFormat:@"(%@)", plannedSection.instructionalMethod];
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line1bLabel.accessibilityLabel];
    } else
    {
        line1bLabel.text = nil;
    }
    UILabel *line2Label = (UILabel *)[cell viewWithTag:2];
    line2Label.text = plannedSection.sectionTitle;
    cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line2Label.accessibilityLabel];
    UILabel *line3Label = (UILabel *)[cell viewWithTag:3];
    UILabel *line3bLabel = (UILabel *)[cell viewWithTag:5];
    NSString *faculty = [plannedSection facultyNames];
    
    NSString *credits = [self.creditsFormatter stringFromNumber:plannedSection.credits];
    NSString *ceus = [self.creditsFormatter stringFromNumber:plannedSection.ceus];
    NSString *gradingType = @"";
    if (plannedSection.isAudit) {
        gradingType = [NSString stringWithFormat: @"%@", NSLocalizedString(@"| Audit", @"Audit label for registration")];
    }
    else if (plannedSection.isPassFail) {
        gradingType = [NSString stringWithFormat: @"%@", NSLocalizedString(@"| P/F", @"PassFail abbrev label for registration cart")];
    }

    
    if(faculty) {
        line3Label.text = [NSString stringWithFormat:@"%@", faculty];
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3Label.accessibilityLabel];
        if (credits) {
            line3bLabel.text = [NSString stringWithFormat:NSLocalizedString(@" | %@ Credits %@", @"| credits and Credits label and grading type for registration"), credits, gradingType ];
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3bLabel.accessibilityLabel];
        } else if (ceus) {
            line3bLabel.text = [NSString stringWithFormat:NSLocalizedString(@" | %@ CEUs %@", @"| ceus and CEUs label and grading type for registration"), ceus, gradingType ];
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3bLabel.accessibilityLabel];
        }
    } else {
        if (credits) {
            line3Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Credits %@", @"credits and Credits label and grading type for registration"), credits, gradingType];
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3Label.accessibilityLabel];
        } else if (ceus) {
            line3Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ CEUs %@", @"ceus and CEUs label and grading type for registration"), ceus, gradingType];
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3Label.accessibilityLabel];
        }
        line3bLabel.text = nil;
    }
    UILabel *line4Label = (UILabel *)[cell viewWithTag:4];
    if(plannedSection.meetingPatternDescription) {
        line4Label.text = [NSString stringWithFormat:@"%@", plannedSection.meetingPatternDescription];
        cellLabel = [NSString stringWithFormat:@"%@, %@", cellLabel, line4Label.accessibilityLabel];
    } else {
        line4Label.text = nil;
    }
    
    UIImageView *checkmarkImageView = (UIImageView *)[cell viewWithTag:100];
    if(plannedSection.selectedInCart) {
        checkmarkImageView.image = [UIImage imageNamed:@"Registration Checkmark"];
    } else {
        checkmarkImageView.image = [UIImage imageNamed:@"Registration Circle"];
    }

    UIImage *image = [UIImage imageNamed:@"Registration Detail"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.accessibilityLabel = NSLocalizedString(@"Course detail", @"VoiceOver label for button that displays course details");
    CGRect frame = CGRectMake(0.0, 0.0, 44.0f, 44.0f);
    button.frame = frame;
    [button setImage:image forState:UIControlStateNormal];
    
    [button addTarget: self
               action: @selector(accessoryButtonTapped:withEvent:)
     forControlEvents: UIControlEventTouchUpInside];
    cell.accessoryView = button;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section <= self.registrationTabController.terms.count) {
        cell.backgroundColor = [UIColor colorWithRed:0.98 green:0.68 blue:0.09 alpha:.2];
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    
    cellLabel = [cellLabel stringByReplacingOccurrencesOfString:@"|" withString:@""];
    [cell setAccessibilityLabel:cellLabel];

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView configureCell:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RegistrationTerm *term = [self registrationTermForSection:indexPath.section];
    if(term.requiresAltPin && !term.userEnteredPIN) {
        [self promptForPIN:term.termId];
    }
    NSArray *plannedSections = [self sectionsForTerm: term filteredByAuthorizationCodeRequired:(indexPath.section <= self.registrationTabController.terms.count)];
    RegistrationPlannedSection *plannedSection = [plannedSections objectAtIndex:indexPath.row];
    if(plannedSection.authorizationCodeRequired && !plannedSection.authorizationCode) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Authorization Code", @"Authorization Code Heading")
                                              message:NSLocalizedString(@"Enter your authorization code.", @"Enter your authorization code message")
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
         {
             textField.placeholder = NSLocalizedString(@"Authorization Code", @"Authorization Code placeholder text");
             textField.keyboardType = UIKeyboardTypeNumberPad;
             [textField addTarget:self
                           action:@selector(alertAuthorizationCodeTextFieldDidChange:)
                 forControlEvents:UIControlEventEditingChanged];

         }];
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                       style:UIAlertActionStyleCancel
                                       handler:^(UIAlertAction *action)
                                       {
                                           plannedSection.selectedInCart = NO;
                                           [self refreshTable:self];
                                       }];
        
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       plannedSection.authorizationCode = alertController.textFields.firstObject.text;
                                    }];
        okAction.enabled = NO;
        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    plannedSection.selectedInCart = !plannedSection.selectedInCart;
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self updateStatusBar];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return self.registrationTabController.ineligibleMessage ? 1 : 0;
    }
    RegistrationTerm *term = [self registrationTermForSection:section];
    NSArray *plannedSections = [self sectionsForTerm: term filteredByAuthorizationCodeRequired:(section <= self.registrationTabController.terms.count)];
    return [plannedSections count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([self.registrationTabController.terms count] * 2) + 1;
}

- (void) accessoryButtonTapped: (UIControl *) button withEvent: (UIEvent *) event
{
    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint: [[[event touchesForView: button] anyObject] locationInView: self.tableView]];
    if ( indexPath == nil )
        return;
    
    [self.tableView.delegate tableView: self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    RegistrationTerm *term = [self registrationTermForSection:indexPath.section];
        NSArray *plannedSections = [self sectionsForTerm: term filteredByAuthorizationCodeRequired:(indexPath.section <= self.registrationTabController.terms.count)];
    RegistrationPlannedSection *plannedSection = [plannedSections objectAtIndex:indexPath.row];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UISplitViewController *split = [self.registrationTabController childViewControllers][0];
        split.presentsWithGesture = YES;
    
        UINavigationController *controller = split.viewControllers[0];
        UINavigationController *detailNavController = split.viewControllers[1];
    
        UIViewController *masterController = controller.topViewController;
        UIViewController *detailController = detailNavController.topViewController;
    
        if([masterController conformsToProtocol:@protocol(UISplitViewControllerDelegate)]) {
            split.delegate = (id)masterController;
        }
        if([detailController conformsToProtocol:@protocol(UISplitViewControllerDelegate)]) {
            split.delegate = (id)detailController;
        }
        if( [detailController conformsToProtocol:@protocol(DetailSelectionDelegate)]) {
            if ( [masterController respondsToSelector:@selector(detailSelectionDelegate) ])
            {
                [masterController setValue:detailController forKey:@"detailSelectionDelegate"];
            }
        }
        if (_detailSelectionDelegate) {
            [_detailSelectionDelegate selectedDetail:plannedSection withIndex:indexPath withModule:self.module withController:self];
        }
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self performSegueWithIdentifier:@"Show Section Detail" sender:plannedSection];
    }
    
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    switch(section) {
//        case 0:
//            return 0.0f;
//        default:
//            return [super tableView:tableView heightForHeaderInSection:section];
//    }
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            return UITableViewAutomaticDimension;
        }
        default:
            return 86.0f;
    }
}


#pragma mark - logic
-(void) updateBadge
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        int count = [self.registrationTabController itemsInCartCount];
        
        if(!self.registrationTabController.ineligibleMessage && count == 0){
            [self showNoDataView:NSLocalizedString(@"Registration Cart Empty", @"empty registration cart message")];
        } else {
            [self hideNoDataView];
        }
        
        NSString *badgeValue = [NSString stringWithFormat:@"%d", count];
        [[[[[self tabBarController] tabBar] items] objectAtIndex:0] setBadgeValue:badgeValue];
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.navigationController setToolbarHidden:YES animated:YES];
    if ([[segue identifier] isEqualToString:@"Show Section Detail"]) {
        RegistrationPlannedSection *courseSection = sender;
        RegistrationPlannedSectionDetailViewController *detailController = [segue destinationViewController];
        detailController.registrationPlannedSection = courseSection;
        detailController.module = self.module;
    } else if ([[segue identifier] isEqualToString:@"Register"]) {
        NSDictionary *messages = (NSDictionary *)sender;
        id detailController = [segue destinationViewController];
        if([detailController isKindOfClass:[UINavigationController class]]) {
            detailController = ((UINavigationController *)detailController).childViewControllers[0];
        }
        
        RegistrationResultsViewController *resultsViewController = (RegistrationResultsViewController *)detailController;
        resultsViewController.module = self.module;
        resultsViewController.importantMessages = [messages objectForKey:@"messages"];
        resultsViewController.registeredMessages = [messages objectForKey:@"successes"];
        resultsViewController.warningMessages = [messages objectForKey:@"failures"];
        resultsViewController.delegate = self.registrationTabController;
        
        for(NSDictionary *registeredMessage in [messages objectForKey:@"successes"]) {
            NSString *section = [registeredMessage objectForKey:@"sectionId"];
            NSString *term = [registeredMessage objectForKey:@"termId"];
            RegistrationTabBarController *tab = self.registrationTabController;
            [tab removeSearchedSection:section term:term];
        }
        if([[messages objectForKey:@"messages"] count] || [[messages objectForKey:@"failures"] count]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userEnteredPIN.length > 0"];
            NSArray *filteredArray = [self.registrationTabController.terms filteredArrayUsingPredicate:predicate];
            for(RegistrationTerm *term in filteredArray) {
                term.userEnteredPIN = nil;
            }
        }
    }
}


- (IBAction)startRegistration:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", comment: @"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction *registerAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Register", comment: @"Register button") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self sendEventWithCategory:Analytics.UI_Action action:Analytics.Button_Press label:@"Register" moduleName:self.module.name];
        [self registerSelectedCourses];
    }];
    [alertController addAction:registerAction];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alertController.popoverPresentationController.barButtonItem = self.registerButton;
    } else {
        alertController.popoverPresentationController.sourceView = self.navigationController.toolbar;
        alertController.popoverPresentationController.sourceRect = self.navigationController.toolbar.bounds;
    }

    [self presentViewController:alertController animated:YES completion:nil];
}

-(void) updateStatusBar
{
    int count = 0;
    for(RegistrationTerm *term in self.registrationTabController.terms) {
        NSArray *plannedSections = [self.registrationTabController sectionsInCart:term.termId];
        for(RegistrationPlannedSection *course in plannedSections) {
            if(course.selectedInCart) {
                count++;
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController setToolbarHidden:!(count>0) animated:YES];
        self.registerButton.title = [NSString stringWithFormat:NSLocalizedString(@"Register (%d)", @"label for register button in cart"), count];
    });
}

//-(void) reloadData:(id)sender
//{
//    [self.tableView reloadData];
//    [self updateBadge];
 ///
//}

-(void) registerSelectedCourses
{
    [self.navigationController setToolbarHidden:YES animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo: [UIApplication sharedApplication].keyWindow animated:YES];
    NSString *loadingString = NSLocalizedString(@"Registering", @"loading message while waiting for registration");
    hud.label.text = loadingString;
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        
        NSMutableArray *sectionRegistrations = [NSMutableArray new];
        
        for(RegistrationTerm *term in self.registrationTabController.terms) {
            NSArray *plannedSections = [self.registrationTabController sectionsInCart:term.termId];
            for(RegistrationPlannedSection *course in plannedSections) {
                
                if ( course.selectedInCart ) {
                    
                    NSMutableDictionary *sectionToRegister = [[NSMutableDictionary alloc] init];
                    
                    NSString * action = @"Add";
                    
                    if (course.isAudit) {
                        action = @"Audit";
                    } else if (course.isPassFail) {
                        action = @"PassFail";
                    }
                    
                    if(course.isVariableCredit) {
                        [sectionToRegister setObject:course.credits forKey:@"credits"];
                    }
                    if(term.requiresAltPin) {
                        [sectionToRegister setObject:term.userEnteredPIN forKey:@"altPin"];
                    }
                    [sectionToRegister setObject:term.termId forKey:@"termId"];
                    [sectionToRegister setObject:course.sectionId forKey:@"sectionId"];
                    [sectionToRegister setObject:action forKey:@"action"];
                    
                    if(course.authorizationCodeRequired) {
                        [sectionToRegister setObject:course.authorizationCode forKey:@"authorizationCode"];
                    }
                    
                    [sectionRegistrations addObject:sectionToRegister];
                }
                
            }
        }
        
        NSDictionary *postDictionary = @{
                                         @"planId": self.planId,
                                         @"sectionRegistrations": sectionRegistrations,
                                         };
        NSError *jsonError;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:postDictionary options:NSJSONWritingPrettyPrinted error:&jsonError];
        
        NSString *urlString = [NSString stringWithFormat:@"%@/%@/register-sections", [self.module propertyForKey:@"registration"], [[[CurrentUser sharedInstance] userid]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
        NSString* planningTool = [self.module propertyForKey:@"planningTool"];
        if(planningTool) {
            urlString = [NSString stringWithFormat:@"%@?planningTool=%@", urlString, planningTool];
        }
        
        NSMutableURLRequest * urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        //[urlRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        
        NSString *authenticationMode = [[AppGroupUtilities userDefaults] objectForKey:@"login-authenticationType"];
        if(!authenticationMode || [authenticationMode isEqualToString:@"native"]) {
            [urlRequest addAuthenticationHeader];
        }
        
        [urlRequest setHTTPMethod:@"PUT"];
        [urlRequest setHTTPBody:jsonData];
        
        
        NSDate *startDate = [NSDate date];
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        NSURLSession *session = [NSURLSession sharedSession]; // or create your own session with your own NSURLSessionConfiguration
        NSURLSessionTask *task = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
            NSTimeInterval elapsedTimeInterval = [[NSDate date] timeIntervalSinceDate:startDate];
            [self sendUserTimingWithCategory:@"Registration" time:elapsedTimeInterval name:@"Registration" label:nil moduleName:self.module.name];
            
            if(responseData) {
                NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
                [self.registrationTabController fetchRegistrationPlans:self];
                [self performSegueWithIdentifier:@"Register" sender:jsonResponse];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
            } else {
                UIAlertController *alertController = [UIAlertController
                                                      alertControllerWithTitle:NSLocalizedString(@"Error", @"Error")
                                                      message:error.localizedDescription
                                                      preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                           style:UIAlertActionStyleDefault
                                           handler:nil];
                [alertController addAction:okAction];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self presentViewController:alertController animated:YES completion:nil];
                
                    [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
            }
            
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });
}

-(NSNumberFormatter *)creditsFormatter
{
    if(_creditsFormatter == nil) {
        _creditsFormatter = [NSNumberFormatter new];
        _creditsFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        [_creditsFormatter setMinimumFractionDigits:1];
    }
    return _creditsFormatter;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        RegistrationTerm *term = [self registrationTermForSection:indexPath.section];
        NSArray *plannedSections = [self sectionsForTerm: term filteredByAuthorizationCodeRequired:(indexPath.section <= self.registrationTabController.terms.count)];
        RegistrationPlannedSection *plannedSection = [plannedSections objectAtIndex:indexPath.row];

        [self.registrationTabController removeFromCart:plannedSection];
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            UISplitViewController *split = [self.registrationTabController childViewControllers][0];
            UINavigationController *detailNavController = split.viewControllers[1];
            UIViewController *detailController = detailNavController.topViewController;
            if([detailController isKindOfClass:[RegistrationPlannedSectionDetailViewController class]]) {
                RegistrationPlannedSectionDetailViewController *registrationPlannedSectionDetailViewController = (RegistrationPlannedSectionDetailViewController *) detailController;
                if(registrationPlannedSectionDetailViewController.registrationPlannedSection == plannedSection) {
                    [registrationPlannedSectionDetailViewController clearView];
                }
            }
        }

        [self updateStatusBar];
    }
}

-(void) refreshTable:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
    if ([self hasAuthorizationCodeRequiredTerms]) {
        UIView *header = [[[NSBundle mainBundle] loadNibNamed:@"RegistrationCartTableHeaderView" owner:self options:nil] objectAtIndex:0];
        header.autoresizingMask = NO;
        self.tableView.tableHeaderView = header;
        self.tableView.tableHeaderView.subviews[0].backgroundColor = [UIColor colorWithRed:0.98 green:0.68 blue:0.09 alpha:1.0];

    } else {
        self.tableView.tableHeaderView = nil;
    }
    [self.tableView reloadData];
    [self updateBadge];
    [self updateStatusBar];
    });
}

-(void) promptForPIN:(NSString *)termId;
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:NSLocalizedString(@"PIN", @"PIN label for registration")
                                          message:NSLocalizedString(@"Enter the registration PIN", @"PIN label for registration")
                                          preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = NSLocalizedString(@"PIN", @"PIN label for registration");
         textField.secureTextEntry = YES;
         [textField addTarget:self
                       action:@selector(alertPINCodeTextFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];

     }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSArray *sectionsInCartForTerm = [self.registrationTabController sectionsInCart:self.termNeedingPIN];
                                       for(RegistrationPlannedSection *section in sectionsInCartForTerm) {
                                           section.selectedInCart = NO;
                                       }
                                       [self refreshTable:self];
                                   }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   RegistrationTerm *term = [self.registrationTabController findTermById:self.termNeedingPIN];
                                   self.termNeedingPIN = nil;
                                   UITextField *pinTextField = alertController.textFields.firstObject;
                                   term.userEnteredPIN = pinTextField.text;
                               }];
    okAction.enabled = NO;
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    self.termNeedingPIN = termId;
    [self presentViewController:alertController animated:YES completion:nil];

}

-(RegistrationTerm *) registrationTermForSection:(NSInteger)section
{
    //skip error, then two sections for each term
    int index = (int)(section - 1) % self.registrationTabController.terms.count;
    RegistrationTerm *term = [self.registrationTabController.terms objectAtIndex:index];
    return term;
}

-(NSArray *)sectionsForTerm: (RegistrationTerm *)term filteredByAuthorizationCodeRequired:(BOOL)authorizationCodeRequired {
    
    NSArray *plannedSections = [self.registrationTabController sectionsInCart:term.termId];
    
    NSPredicate *predicate;
    if (authorizationCodeRequired) {
        predicate = [NSPredicate predicateWithFormat:@"authorizationCodeRequired = YES"];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"authorizationCodeRequired = NO"];
    }
    NSArray *filteredSections = [plannedSections filteredArrayUsingPredicate:predicate];
    return filteredSections;
}

- (void)alertAuthorizationCodeTextFieldDidChange:(UITextField *)sender
{
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        UITextField *textField = alertController.textFields.firstObject;
        UIAlertAction *okAction = alertController.actions.lastObject;
        NSString *text = [textField text];
        okAction.enabled = [text length] > 0;
    }
}

- (void)alertPINCodeTextFieldDidChange:(UITextField *)sender
{
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        UITextField *textField = alertController.textFields.firstObject;
        UIAlertAction *okAction = alertController.actions.lastObject;
        NSString *text = [textField text];
        okAction.enabled = [text length] > 0;
    }
}


-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    RegistrationCartTermHeaderView *header=[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"RegistrationCartTermHeaderView"];

    if (section == 0) {
        header.cellView.backgroundColor = [UIColor accent];
        header.titleLabel.textColor = [UIColor subheaderText];
        header.titleLabel.text = NSLocalizedString(@"Ineligible for Registration", @"Ineligible for Registration");
        header.titleLabel.textColor = [UIColor subheaderText];
        header.warningImageView.hidden = YES;
    }
    else if (section <= self.registrationTabController.terms.count) {
        header.cellView.backgroundColor = [UIColor colorWithRed:0.98 green:0.68 blue:0.09 alpha:1.0];
        header.titleLabel.textColor = [UIColor whiteColor];
        RegistrationTerm *term = [self registrationTermForSection:section];
        header.titleLabel.text = term.name;
        header.warningImageView.hidden = NO;
    } else {
        header.cellView.backgroundColor = [UIColor accent];
        header.titleLabel.textColor = [UIColor subheaderText];
        
        RegistrationTerm *term = [self registrationTermForSection:section];
        header.titleLabel.text = term.name;
        header.warningImageView.hidden = YES;
    }
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([tableView.dataSource tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0;
    } else {
        return 30;
    }
}

-(BOOL) hasAuthorizationCodeRequiredTerms {
    if (self.registrationTabController.terms.count > 0 ) {
        for (int i = 1; i <= self.registrationTabController.terms.count; i++) {
            RegistrationTerm *term = [self registrationTermForSection:i];
            NSArray *plannedSections = [self sectionsForTerm: term filteredByAuthorizationCodeRequired:YES];
            if ([plannedSections count] > 0) {
                return YES;
            }
        }
    }
    return NO;
}
@end
