//
//  RegistrationRegisteredSectionsViewController.m
//  Mobile
//
//  Created by Jason Hocker on 1/24/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import "RegistrationRegisteredSectionsViewController.h"
#import "MBProgressHUD.h"
#import "RegistrationPlannedSection.h"
#import "RegistrationTerm.h"
#import <AddressBook/AddressBook.h>
#import "MBProgressHUD.h"
#import "RegistrationResultsViewController.h"
#import "RegistrationTabBarController.h"
#import "RegistrationPlannedSectionDetailViewController.h"
#import "Ellucian_GO-Swift.h"

@interface RegistrationRegisteredSectionsViewController ()
@property (nonatomic, strong) NSNumberFormatter *creditsFormatter;
@property (strong, nonatomic) UIBarButtonItem *dropButton;
@property (nonatomic, strong) NSString *termNeedingPIN;
@end

@implementation RegistrationRegisteredSectionsViewController

@synthesize module_;

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self sendView:@"Registration Registered Sections list" moduleName:self.module.name];
    [self updateStatusBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self traitCollection].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
    }
    
    UINib *cellNib = [UINib nibWithNibName:@"RegistrationCartTermHeaderView" bundle:nil];
    [self.tableView registerNib:cellNib forHeaderFooterViewReuseIdentifier:@"RegistrationCartTermHeaderView"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData:) name:kRegistrationPlanDataReloaded object:nil];
    
    self.navigationItem.title = [self.module name];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    self.dropButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Drop", "Registration Drop button") style:UIBarButtonItemStylePlain target:self action:@selector(dropRegistration:)];
    UIImage *registerButtonImage = [UIImage imageNamed:@"Registration Button"];
    [self.navigationController.toolbar setBackgroundImage:registerButtonImage forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
    self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    
    self.toolbarItems = [NSArray arrayWithObjects:flexibleItem, self.dropButton, flexibleItem, nil];
    self.navigationController.navigationBar.translucent = NO;
    
    [self checkEmptyList];
}

-(void) checkEmptyList
{
    BOOL empty = YES;
    for(RegistrationTerm *term in self.registrationTabController.terms) {
        NSArray *plannedSections = [self.registrationTabController registeredSections:term.termId];
        if([plannedSections count] > 0) {
            empty = NO;
            break;
        }
        
    }

    if(empty){
        [self showNoDataView:NSLocalizedString(@"No registered classes for open terms.", @"No registered classes for open terms message")];
    } else {
        [self hideNoDataView];
    }
}

#pragma mark - variables from tab
-(RegistrationTabBarController *) registrationTabController
{
    return  (RegistrationTabBarController *)[self tabBarController];
}

#pragma mark - table

- (UITableViewCell *)tableView:(UITableView *)tableView configureCell:(NSIndexPath *)indexPath
{
    RegistrationTerm *term = [self.registrationTabController.terms objectAtIndex:indexPath.section];
    NSArray *plannedSections = [self.registrationTabController registeredSections:term.termId];
    RegistrationPlannedSection *plannedSection = [plannedSections objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"Registration Section Cell";
    
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
    } else {
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
        if (credits){
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
    if(plannedSection.selectedForDrop) {
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
    
    cellLabel = [cellLabel stringByReplacingOccurrencesOfString:@"|" withString:@""];
    [cell setAccessibilityLabel:cellLabel];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView configureCell:indexPath];
    [cell setAccessibilityTraits:UIAccessibilityTraitButton];
    [cell setAccessibilityHint:NSLocalizedString(@"Selects course to drop.", @"VoiceOver hint for button that selects a course to drop")];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RegistrationTerm *term = [self.registrationTabController.terms objectAtIndex:indexPath.section];
    if(term.requiresAltPin && !term.userEnteredPIN) {
        [self promptForPIN:term.termId];
    }
    NSArray *plannedSections = [self.registrationTabController registeredSections:term.termId];
    RegistrationPlannedSection *plannedSection = [plannedSections objectAtIndex:indexPath.row];
    
    plannedSection.selectedForDrop = !plannedSection.selectedForDrop;
    [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self updateStatusBar];
}

- (NSString *)tableView:(UITableView *)tableView stringForTitleForHeaderInSection:(NSInteger)section
{
    
    RegistrationTerm *term = [self.registrationTabController.terms objectAtIndex:section];
    return term.name;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    RegistrationTerm *term = [self.registrationTabController.terms objectAtIndex:section ];
    NSArray *plannedSections = [self.registrationTabController registeredSections:term.termId];
    return [plannedSections count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.registrationTabController.terms count];
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
    RegistrationTerm *term = [self.registrationTabController.terms objectAtIndex:indexPath.section];
    NSArray *plannedSections = [self.registrationTabController registeredSections:term.termId];
    RegistrationPlannedSection *plannedSection = [plannedSections objectAtIndex:indexPath.row];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UISplitViewController *split = [self.registrationTabController childViewControllers][2];
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

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{

    RegistrationCartTermHeaderView *header=[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"RegistrationCartTermHeaderView"];

    header.cellView.backgroundColor = [UIColor accent];
    header.titleLabel.textColor = [UIColor subheaderText]; //subheaderText
        
    RegistrationTerm *term = [self.registrationTabController.terms objectAtIndex:section ];
    header.titleLabel.text = term.name;
    header.warningImageView.hidden = YES;
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([tableView.dataSource tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0;
    } else {
        return 30;
    }
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

#pragma mark - logic

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.navigationController setToolbarHidden:YES animated:YES];
    if ([[segue identifier] isEqualToString:@"Show Section Detail"]) {
        RegistrationPlannedSection *courseSection = sender;
        RegistrationPlannedSectionDetailViewController *detailController = [segue destinationViewController];
        detailController.registrationPlannedSection = courseSection;
        detailController.module = self.module;
    } else if ([[segue identifier] isEqualToString:@"Show Drop Results"]) {
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
        
        if([[messages objectForKey:@"messages"] count] || [[messages objectForKey:@"failures"] count]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userEnteredPIN.length > 0"];
            NSArray *filteredArray = [self.registrationTabController.terms filteredArrayUsingPredicate:predicate];
            for(RegistrationTerm *term in filteredArray) {
                term.userEnteredPIN = nil;
            }
        }
    }
}

- (IBAction)dropRegistration:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", comment: @"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction *dropAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Drop", comment: @"Registration Drop button") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self sendEventWithCategory:Analytics.UI_Action action:Analytics.Button_Press label:@"Drop" moduleName:self.module.name];
        [self dropSelectedCourses];
    }];
    [alertController addAction:dropAction];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alertController.popoverPresentationController.barButtonItem = self.dropButton;
    } else {
        alertController.popoverPresentationController.sourceView = self.navigationController.toolbar;
        alertController.popoverPresentationController.sourceRect = self.navigationController.toolbar.bounds;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

-(void) updateStatusBar
{
    int count = 0;
    for(RegistrationTerm *term in self.self.registrationTabController.terms) {
        NSArray *plannedSections = [self.registrationTabController registeredSections:term.termId];
        for(RegistrationPlannedSection *course in plannedSections) {
            if(course.selectedForDrop) {
                count++;
            }
        }
    }
    [self.navigationController setToolbarHidden:!(count>0) animated:YES];
    self.dropButton.title = [NSString stringWithFormat:NSLocalizedString(@"Drop (%d)", @"label for drop button in registered list"), count];
}


-(void) reloadData:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self checkEmptyList];
    });
}

-(NSString *) planId
{
    return self.registrationTabController.planId;
}

-(void) dropSelectedCourses
{
    [self.navigationController setToolbarHidden:YES animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo: [UIApplication sharedApplication].keyWindow animated:YES];
    NSString *loadingString = NSLocalizedString(@"Dropping", @"loading message while waiting for dropping");
    hud.label.text = loadingString;
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        
        NSMutableArray *sectionRegistrations = [NSMutableArray new];
        
        for(RegistrationTerm *term in self.registrationTabController.terms) {
            NSArray *plannedSections = [self.registrationTabController registeredSections:term.termId];
            for(RegistrationPlannedSection *course in plannedSections) {
                
                if ( course.selectedForDrop ) {
                    
                    NSMutableDictionary *sectionToRegister = [[NSMutableDictionary alloc] init];
                    
                    NSString * action = @"Drop";
                    
                    if(course.isVariableCredit) {
                        [sectionToRegister setObject:course.credits forKey:@"credits"];
                    }
                    if(term.requiresAltPin) {
                        [sectionToRegister setObject:term.userEnteredPIN forKey:@"altPin"];
                    }
                    [sectionToRegister setObject:term.termId forKey:@"termId"];
                    [sectionToRegister setObject:course.sectionId forKey:@"sectionId"];
                    [sectionToRegister setObject:action forKey:@"action"];
                    
                    
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
            [self sendUserTimingWithCategory:@"Registration" time:elapsedTimeInterval name:@"Registration Drop" label:nil moduleName:self.module.name];
            if(responseData) {
                NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
                [self.registrationTabController fetchRegistrationPlans:self];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self performSegueWithIdentifier:@"Show Drop Results" sender:jsonResponse];
                    [MBProgressHUD hideHUDForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
            } else {
                
                UIAlertController *alertController = [UIAlertController
                                                      alertControllerWithTitle:NSLocalizedString(@"Error", @"Error")
                                                      message:error.localizedDescription
                                                      preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"OK", @"OK action")
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
                                       NSArray *sectionsInCartForTerm = [self.registrationTabController registeredSections:self.termNeedingPIN];
                                       for(RegistrationPlannedSection *section in sectionsInCartForTerm) {
                                           section.selectedForDrop = NO;
                                       }
                                       [self.tableView reloadData];
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

@end
