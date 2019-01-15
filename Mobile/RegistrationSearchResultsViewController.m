//
//  RegistrationSearchResultsViewController.m
//  Mobile
//
//  Created by Jason Hocker on 1/13/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import "RegistrationSearchResultsViewController.h"
#import "RegistrationPlannedSection.h"
#import "RegistrationTabBarController.h"
#import "RegistrationPlannedSectionDetailViewController.h"
#import "RegistrationTerm.h"
#import "Ellucian_GO-Swift.h"

@interface RegistrationSearchResultsViewController ()
@property (strong, nonatomic) UIBarButtonItem *addToCartButton;
@property (nonatomic, strong) NSDateFormatter *displayDateFormatter;
@end

@implementation RegistrationSearchResultsViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if([self.courses count] == 0){
        [self showNoDataView:NSLocalizedString(@"Search Results Empty", @"empty Search Results message")];
    } else {
        [self hideNoDataView];
    }
    
    [self updateStatusBar];
    [self sendView:@"Registration search results list" moduleName:self.registrationTabController.module.name];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    UINib *cellNib = [UINib nibWithNibName:@"RegistrationSearchResultsHeaderFooterView" bundle:nil];
    [self.tableView registerNib:cellNib forHeaderFooterViewReuseIdentifier:@"RegistrationSearchResultsHeaderFooterView"];
    
    //setup toolbar
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    self.addToCartButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add To Cart", "Add To Cart button") style:UIBarButtonItemStylePlain target:self action:@selector(addToCart:)];

    UIImage *registerButtonImage = [UIImage imageNamed:@"Registration Button"];
    [self.navigationController.toolbar setBackgroundImage:registerButtonImage forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
    self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    
    self.toolbarItems = [NSArray arrayWithObjects:flexibleItem, self.addToCartButton, flexibleItem, nil];
    self.navigationController.navigationBar.translucent = NO;
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *courses = [self sectionsFilteredByAuthorizationCodeRequired:(section == 0)];
    return [courses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RegistrationPlannedSection *plannedSection = [self sectionForIndex:indexPath.row authorizationCodeRequired:(indexPath.section == 0)];
    
    NSString *CellIdentifier = @"Registration Course Cell";
    if( plannedSection.available && plannedSection.capacity && plannedSection.capacity > 0 ) {
        CellIdentifier = @"Registration Course Seats Cell";
    } else {
        CellIdentifier = @"Registration Course Cell";
    }

    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [cell setAccessibilityTraits:UIAccessibilityTraitButton];
    [cell setAccessibilityHint:NSLocalizedString(@"Selects course to add to cart.", @"VoiceOver hint for button that selects a course to add to the cart")];
    
    UILabel *line1aLabel = (UILabel *)[cell viewWithTag:1];
    line1aLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course name-section number", @"Localizable", [NSBundle mainBundle], @"%@-%@", @"course name-section number"), plannedSection.courseName, plannedSection.courseSectionNumber];
    NSString *cellLabel = line1aLabel.accessibilityLabel;

    UILabel *line2Label = (UILabel *)[cell viewWithTag:2];
    line2Label.text = plannedSection.sectionTitle;
    cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line2Label.accessibilityLabel];
    
    UILabel *line3Label = (UILabel *)[cell viewWithTag:3];
    UILabel *line3bLabel = (UILabel *)[cell viewWithTag:5];
    NSString *faculty = [plannedSection facultyNames];
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    [formatter setMinimumFractionDigits:1];
    
    NSString *minCredits = [formatter stringFromNumber:plannedSection.minimumCredits];
    NSString *maxCredits = [formatter stringFromNumber:plannedSection.maximumCredits];
    NSString *ceus = [formatter stringFromNumber:plannedSection.ceus];
    
    
    if(faculty) {
        line3Label.text = [NSString stringWithFormat:@"%@", faculty];
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3Label.accessibilityLabel];
        if(plannedSection.maximumCredits) {
            if([plannedSection.variableCreditOperator isEqualToString:@"OR"]) {
                line3bLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration divider min or max Credits", @"Localizable", [NSBundle mainBundle], @" | %@/%@ Credits", @"registration divider min or max Credits"), minCredits, maxCredits];
            } else {
                line3bLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration divider min to max Credits", @"Localizable", [NSBundle mainBundle], @" | %@-%@ Credits", @"registration divider min to max Credits"), minCredits, maxCredits];
            }
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3bLabel.accessibilityLabel];
        } else if (plannedSection.minimumCredits){
            line3bLabel.text = [NSString stringWithFormat:NSLocalizedString(@" | %@ Credits", @"divider Credits label for registration") , minCredits];
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3bLabel.accessibilityLabel];
        } else if (plannedSection.ceus ) {
            line3bLabel.text = [NSString stringWithFormat:NSLocalizedString(@" | %@ CEUs", @"divider CEUs label for registration"), ceus ];
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3bLabel.accessibilityLabel];
        }
    } else {
        if(plannedSection.maximumCredits) {
            if([plannedSection.variableCreditOperator isEqualToString:@"OR"]) {
                line3Label.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration min or max Credits", @"Localizable", [NSBundle mainBundle], @"%@/%@ Credits", @"registration min or max Credits"), minCredits, maxCredits];
            } else {
                line3Label.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration min to max Credits", @"Localizable", [NSBundle mainBundle], @"%@-%@ Credits", @"registration min to max Credits"), minCredits, maxCredits];
            }
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3Label.accessibilityLabel];
        } else if(plannedSection.minimumCredits){
            line3Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Credits", @"Credits label for registration") , minCredits];
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3Label.accessibilityLabel];
        } else if (plannedSection.ceus) {
            line3Label.text = [NSString stringWithFormat:NSLocalizedString(@"%@ CEUs", @"CEUs label for registration"), ceus ];
            cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line3Label.accessibilityLabel];
        }
        line3bLabel.text = nil;
    }
    UILabel *line4Label = (UILabel *)[cell viewWithTag:4];
    UILabel *line4bLabel = (UILabel *)[cell viewWithTag:7];
    if(plannedSection.meetingPatternDescription && plannedSection.instructionalMethod) {
        line4Label.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration search results meeting pattern", @"Localizable", [NSBundle mainBundle], @"%@", @"registration search results meeting pattern"), plannedSection.meetingPatternDescription];
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line4Label.accessibilityLabel];
        line4bLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration search results instructional method", @"Localizable", [NSBundle mainBundle], @" | %@", @"registration search results instructional method"), plannedSection.instructionalMethod];
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line4bLabel.accessibilityLabel];
        
    } else if(plannedSection.meetingPatternDescription) {
        line4Label.text = plannedSection.meetingPatternDescription;
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line4Label.accessibilityLabel];
        line4bLabel.text = nil;
    } else if(plannedSection.instructionalMethod) {
        line4Label.text = plannedSection.instructionalMethod;
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line4Label.accessibilityLabel];
        line4bLabel.text = nil;
    } else {
        line4Label.text = nil;
        line4bLabel.text = nil;
    }
    
    UILabel *line1bLabel = (UILabel *)[cell viewWithTag:6];
    if(plannedSection.academicLevels && plannedSection.location) {
        line1bLabel.text = [NSString stringWithFormat:@"%@ | %@", [plannedSection.academicLevels componentsJoinedByString:@","], plannedSection.location];
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line1bLabel.accessibilityLabel];
    } else if(plannedSection.academicLevels) {
        line1bLabel.text = [plannedSection.academicLevels componentsJoinedByString:@","];
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line1bLabel.accessibilityLabel];
    } else if(plannedSection.location) {
        line1bLabel.text = plannedSection.location;
        cellLabel = [NSString stringWithFormat:@"%@, %@,", cellLabel, line1bLabel.accessibilityLabel];
    } else {
        line1bLabel.text = nil;
    }
    
    UILabel *line5Label = (UILabel *)[cell viewWithTag:8];
    if(plannedSection.firstMeetingDate && plannedSection.lastMeetingDate) {        
        NSString *dates = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course first meeting - last meeting", @"Localizable", [NSBundle mainBundle], @"%@ - %@", @"course first meeting - last meeting"), [self.displayDateFormatter stringFromDate:plannedSection.firstMeetingDate], [self.displayDateFormatter stringFromDate:plannedSection.lastMeetingDate]];
        line5Label.text = dates;
    } else {
        line5Label.text = @"";
    }

    UIImageView *checkmarkImageView = (UIImageView *)[cell viewWithTag:100];
    if(plannedSection.selectedInSearchResults) {
        checkmarkImageView.image = [UIImage imageNamed:@"Registration Checkmark"];
    } else {
        checkmarkImageView.image = [UIImage imageNamed:@"Registration Circle"];
    }

    UIImage *image = [UIImage imageNamed:@"Registration Detail"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.accessibilityLabel = NSLocalizedString(@"Course detail", @"VoiceOver label for button that displays course details");
    CGRect frame = CGRectMake(0.0f, 0.0f, 44.0f, 44.0f);
    button.frame = frame;
    [button setImage:image forState:UIControlStateNormal];
    
    [button addTarget: self
               action: @selector(accessoryButtonTapped:withEvent:)
     forControlEvents: UIControlEventTouchUpInside];
    cell.accessoryView = button;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if( plannedSection.available && plannedSection.capacity) {
        UIView *background = (UIView *)[cell viewWithTag:11];
        background.layer.cornerRadius = 6.0f;
        background.layer.borderColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0].CGColor;
        background.layer.borderWidth = 1.0f;
        
        
        NSNumber *available = plannedSection.available;
        NSNumber *capacity = plannedSection.capacity;
        
        UIImageView *meterImage = (UIImageView *)[cell viewWithTag:12];
        float z = [available floatValue] / [capacity floatValue];
        float delta = 1.0f / 6.0f;
        if ([available intValue] <= 0) {
            meterImage.image = [UIImage imageNamed:@"seats-available-full"];
        } else if(z <= delta) {
            meterImage.image = [UIImage imageNamed:@"seats-available-5-full"];
        } else if(z <= delta*2) {
            meterImage.image = [UIImage imageNamed:@"seats-available-4-full"];
        } else if(z <= delta*3) {
            meterImage.image = [UIImage imageNamed:@"seats-available-3-full"];
        } else if(z <= delta*4) {
            meterImage.image = [UIImage imageNamed:@"seats-available-2-full"];
        } else if(z <= delta*5) {
            meterImage.image = [UIImage imageNamed:@"seats-available-1-full"];
        } else {
            meterImage.image = [UIImage imageNamed:@"seats-available-default"];
        }
    
        if ([meterImage.image respondsToSelector:@selector(imageFlippedForRightToLeftLayoutDirection)]) {
            if ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:meterImage.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft) {
                meterImage.image = meterImage.image.imageFlippedForRightToLeftLayoutDirection;
            }
        }

        UILabel *seatsLabel = (UILabel *)[cell viewWithTag:13];
        seatsLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"available seats/capacity", @"Localizable", [NSBundle mainBundle], @"%@/%@", @"available seats/capacity"), available, capacity];
        cellLabel = [NSString stringWithFormat:@"%@, %@", cellLabel, seatsLabel.accessibilityLabel];
    }
    
    if (indexPath.section % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithRed:0.98 green:0.68 blue:0.09 alpha:.2];
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }
    
    cellLabel = [cellLabel stringByReplacingOccurrencesOfString:@"|" withString:@""];
    [cell setAccessibilityLabel:cellLabel];
    
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( _allowAddToCart ) {
        RegistrationPlannedSection *plannedSection = [self sectionForIndex:indexPath.row authorizationCodeRequired:(indexPath.section == 0)];
        if(!plannedSection.selectedInSearchResults && [self shouldCheckForVariableCredits:plannedSection]) {
            NSString *title = [self titleForVariableCredits:plannedSection];
            
            UIAlertController *alertController = [UIAlertController
                                                alertControllerWithTitle:NSLocalizedString(@"Credits", @"Credits label for registration")
                                                message:title
                                                preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                           style:UIAlertActionStyleCancel
                                           handler:nil];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           NSString *text = [alertController.textFields.firstObject text];
                                           plannedSection.credits = @([text floatValue]);
                                           
                                           plannedSection.selectedInSearchResults = !plannedSection.selectedInSearchResults;
                                           [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
                                           [self updateStatusBar];
                                       }];
            
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
             {
                 textField.placeholder = NSLocalizedString(@"Credits", @"Credits label for registration");
                 textField.keyboardType = UIKeyboardTypeDecimalPad;
                 [textField addTarget:self
                               action:@selector(alertTextFieldDidChange:)
                     forControlEvents:UIControlEventEditingChanged];
                 textField.tag = [self.courses indexOfObject:plannedSection];
                 textField.delegate = self;
                 

             }];
            
            okAction.enabled = NO;
            [self presentViewController:alertController animated:YES completion:nil];
            

        } else {
            plannedSection.selectedInSearchResults = !plannedSection.selectedInSearchResults;
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self updateStatusBar];
        }
    }
}

-(BOOL) shouldCheckForVariableCredits:(RegistrationPlannedSection *)plannedSection
{
    //Ellucian Mobile 3.5
    if(plannedSection.variableCreditOperator) {
        return YES;
    } else {
        //Ellucian Mobile 3.0 - legacy version
        return [plannedSection minimumCredits] && [plannedSection maximumCredits];
    }
}


- (void)alertTextFieldDidChange:(UITextField *)sender
{
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        RegistrationPlannedSection *plannedSection = [self.courses objectAtIndex:sender.tag];
        UITextField *textField = alertController.textFields.firstObject;
        UIAlertAction *okAction = alertController.actions.lastObject;
        NSString *text = [textField text];
        if([text length] > 0) {
            okAction.enabled = [self validateEnteredVariableCreditValue:text forPlannedSection:plannedSection];
        } else {
            okAction.enabled = NO;
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *candidate = [[textField text] stringByReplacingCharactersInRange:range withString:string];
    if (!candidate || [candidate length] < 1 || [candidate isEqualToString:@""])
    {
        return YES;
    }
    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:candidate];
    if (!number || [number isEqualToNumber:[NSDecimalNumber notANumber]])
    {
        return NO;
    }
    return YES;
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
    RegistrationPlannedSection *plannedSection = [self sectionForIndex:indexPath.row authorizationCodeRequired:(indexPath.section == 0)];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        UISplitViewController *split = [self.registrationTabController childViewControllers][1];
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
            [_detailSelectionDelegate selectedDetail:plannedSection withIndex:indexPath withModule:self.registrationTabController.module withController:self];
        }
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if( plannedSection.available && plannedSection.capacity && plannedSection.capacity > 0 ) {
            [self performSegueWithIdentifier:@"Show Section Detail Seats" sender:plannedSection];
        } else {
            [self performSegueWithIdentifier:@"Show Section Detail" sender:plannedSection];
        }
    }

    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"Show Section Detail"] || [[segue identifier] isEqualToString:@"Show Section Detail Seats"]) {
        RegistrationPlannedSection *courseSection = sender;
        RegistrationPlannedSectionDetailViewController *detailController = [segue destinationViewController];
        detailController.registrationPlannedSection = courseSection;
        detailController.module = self.module;
    }
}

-(void) addToCart:(id)sender
{
    [self sendEventWithCategory: Analytics.UI_Action action:Analytics.Button_Press label:@"Add to cart" moduleName:self.registrationTabController.module.name];
    [self updateCartRequestToServer];
    [self updateStatusBar];
    [self.tableView reloadData];

}

-(void) updateCartRequestToServer
{
    NSMutableArray *termsToRegister = [NSMutableArray new];
    
    BOOL coursesAdded = NO;
    RegistrationTabBarController *tabController = self.registrationTabController;
    for(RegistrationTerm *term in tabController.terms) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"termId == %@", term.termId ];
        NSArray *coursesForTerm  = [self.courses filteredArrayUsingPredicate:predicate];
        
        if([coursesForTerm count] > 0) {
            NSMutableArray *sectionRegistrations = [NSMutableArray new];
            for(RegistrationPlannedSection *course in self.courses) {
                if(course.selectedInSearchResults) {
                    if([tabController courseIsInCart:course] || [tabController courseIsRegistered:course]) {
                        NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"%@-%@ failed to add to cart. Section is already registered or exists in the cart.", @"item already in cart error"), course.courseName, course.courseSectionNumber];
                        [tabController reportError:errorMessage];
                    } else {
                        NSString * gradingType = @"Graded";
                        if (course.isAudit) {
                            gradingType = @"Audit";
                        } else if (course.isPassFail) {
                            gradingType = @"PassFail";
                        }
                        NSMutableDictionary *sectionToRegister = [NSMutableDictionary new];
                        [sectionToRegister setObject:course.sectionId forKey:@"sectionId"];
                        [sectionToRegister setObject:@"add" forKey:@"action"];
                        if( course.credits ) {
                            [sectionToRegister setObject: course.credits forKey:@"credits"];
                        }
                        if(course.ceus) {
                            [sectionToRegister setObject: course.ceus forKey:@"ceus"];
                        }
                        [sectionToRegister setObject:gradingType forKey:@"gradingType"];
                        
                        [sectionRegistrations addObject:sectionToRegister];
                        
                        [tabController addSearchedSection:course];
  
                        coursesAdded = YES;
                    }
                    course.selectedInSearchResults = NO;
                }
            }
            
            NSMutableDictionary *termToRegister = [NSMutableDictionary new];
            [termToRegister setObject:term.termId forKey:@"termId"];
            [termToRegister setObject:sectionRegistrations forKey:@"sections"];
            
            [termsToRegister addObject:termToRegister];

        }
    }

    NSMutableDictionary *postDictionary = [NSMutableDictionary new];
    [postDictionary setObject:termsToRegister forKey:@"terms"];
    if(self.registrationTabController.planId) {
        [postDictionary setObject: self.registrationTabController.planId forKey:@"planId"];
    }

    NSError *jsonError;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:postDictionary options:NSJSONWritingPrettyPrinted error:&jsonError];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/update-cart", [self.registrationTabController.module propertyForKey:@"registration"], [[[CurrentUser sharedInstance] userid]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
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

    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(data)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUser.LoginExecutorSuccessNotification object:nil];
            
            NSDictionary* json = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:kNilOptions
                                  error:&error];
            BOOL success = [[json objectForKey:@"success"] boolValue];
            if(!success) {
                NSArray *messages = [json objectForKey:@"messages"];
                if([messages count] > 0) {
                    NSString *message = [messages componentsJoinedByString:@"\n"];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.registrationTabController reportError:message];
                    });
                }
            }
        }
    }];
    [downloadTask resume];

    if(coursesAdded) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Registration", @"message for add to cart title")
                                              message:NSLocalizedString(@"Course(s) added to cart.", @"message for add to cart alert")
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"OK action");
                                   }];
        
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

-(RegistrationTabBarController *) registrationTabController
{
    return  (RegistrationTabBarController *)[self tabBarController];
}

-(void) updateStatusBar
{
    int count = 0;
    for(RegistrationPlannedSection *course in self.courses) {
        if(course.selectedInSearchResults) {
            count++;
        }
        
    }
    [self.navigationController setToolbarHidden:!(count>0) animated:YES];
    self.addToCartButton.title = [NSString stringWithFormat:NSLocalizedString(@"Add To Cart (%d)", @"label for add to cart button in registration search"), count];
}


-(NSString *) titleForVariableCredits:(RegistrationPlannedSection *)plannedSection
{
    NSString *title;
    //Banner
    if(plannedSection.variableCreditOperator) {
        if([plannedSection.variableCreditOperator isEqualToString:@"TO"]) {
            title = [NSString stringWithFormat:NSLocalizedString(@"Enter course credit value between %@ and %@", @"text for variable credits prompt"), plannedSection.minimumCredits, plannedSection.maximumCredits];
        } else if([plannedSection.variableCreditOperator isEqualToString:@"OR"]) {
            title = [NSString stringWithFormat:NSLocalizedString(@"Enter course credit value %@ or %@", @"text for variable credits prompt with two options"), plannedSection.minimumCredits, plannedSection.maximumCredits];
        } else if([plannedSection.variableCreditOperator isEqualToString:@"INC"]) {
            title = [NSString stringWithFormat:NSLocalizedString(@"Enter course credit value between %@ and %@ in increments of %@", @"text for variable credits with credit increment prompt"), plannedSection.minimumCredits, plannedSection.maximumCredits, plannedSection.variableCreditIncrement];
        }
    } else {
        //Colleague
        if(plannedSection.variableCreditIncrement) {
            title = [NSString stringWithFormat:NSLocalizedString(@"Enter course credit value between %@ and %@ in increments of %@", @"text for variable credits with credit increment prompt"), plannedSection.minimumCredits, plannedSection.maximumCredits, plannedSection.variableCreditIncrement];
        } else {
            title = [NSString stringWithFormat:NSLocalizedString(@"Enter course credit value between %@ and %@", @"text for variable credits prompt"), plannedSection.minimumCredits, plannedSection.maximumCredits];
        }
    }
    
    return title;
}


-(BOOL)validateEnteredVariableCreditValue:(NSString *) text forPlannedSection: (RegistrationPlannedSection *) plannedSection
{
    float f = [text floatValue];
    if(plannedSection.variableCreditOperator) {
        if([plannedSection.variableCreditOperator isEqualToString:@"TO"]) {
            if( (f >= [plannedSection.minimumCredits floatValue] ) && (f <= [plannedSection.maximumCredits floatValue])) {
                return YES;
            } else {
                return NO;
            }

        } else if ([plannedSection.variableCreditOperator isEqualToString:@"INC"]) {
            if( (f >= [plannedSection.minimumCredits floatValue] ) && (f <= [plannedSection.maximumCredits floatValue])) {
                if([plannedSection.variableCreditOperator isEqualToString:@"INC"]) {
                    float modulo = fmodf(f, [plannedSection.variableCreditIncrement floatValue]);
                    if (modulo == 0) {
                        return YES;
                    } else {
                        return NO;
                    }
                } else {
                    return YES;
                }
            }
        } else if([plannedSection.variableCreditOperator isEqualToString:@"OR"]) {
            if( (f == [plannedSection.minimumCredits floatValue] ) || (f == [plannedSection.maximumCredits floatValue])) {
                return YES;
            }
            else {
                return NO;
            }
        }
    } else {
        //Colleague
        if( (f >= [plannedSection.minimumCredits floatValue] ) && (f <= [plannedSection.maximumCredits floatValue])) {
            if(plannedSection.variableCreditIncrement) {
                float modulo = fmodf((f - [plannedSection.minimumCredits floatValue]), [plannedSection.variableCreditIncrement floatValue]);
                if (modulo == 0) {
                    return YES;
                } else {
                    return NO;
                }
            } else {
                return YES;
            }
        } return NO;
    }
    return NO;
}

-(NSArray *)sectionsFilteredByAuthorizationCodeRequired:(BOOL)authorizationCodeRequired {
    NSPredicate *predicate;
    if (authorizationCodeRequired) {
        predicate = [NSPredicate predicateWithFormat:@"authorizationCodeRequired = YES"];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"authorizationCodeRequired = NO"];
    }
    NSArray *courses = [self.courses filteredArrayUsingPredicate:predicate];
    return courses;
}

-(RegistrationPlannedSection *) sectionForIndex:(NSUInteger) row authorizationCodeRequired:(BOOL) authorizationCodeRequired {
    
    NSArray *plannedSections = [self sectionsFilteredByAuthorizationCodeRequired:authorizationCodeRequired];
    RegistrationPlannedSection *plannedSection = [plannedSections objectAtIndex: row];
    return plannedSection;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 && [tableView.dataSource tableView:tableView numberOfRowsInSection:section] > 0) {
        return 30;
    } else {
        return 1;
    }
}

-(UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section == 0 && [tableView.dataSource tableView:tableView numberOfRowsInSection:section] > 0) {
        RegistrationSearchResultsHeaderFooterView *header=[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"RegistrationSearchResultsHeaderFooterView"];
        
        header.warningImage.image = [header.warningImage.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [header.warningImage setTintColor:[UIColor whiteColor]];

        return header;
    } else {
        return nil;
    }
}

-(NSDateFormatter *)displayDateFormatter
{
    if(_displayDateFormatter == nil) {
        _displayDateFormatter = [[NSDateFormatter alloc] init];
        [_displayDateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_displayDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_displayDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    return _displayDateFormatter;
}

@end
