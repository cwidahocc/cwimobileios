//
//  RegistrationTabBarController.m
//  Mobile
//
//  Created by jkh on 1/8/14.
//  Copyright (c) 2014 Ellucian. All rights reserved.
//

#import "ModuleRole.h"
#import "RegistrationTabBarController.h"
#import "RegistrationSearchViewController.h"
#import "UIViewController+ECSlidingViewController.h"
#import "RegistrationCartViewController.h"
#import "MBProgressHUD.h"
#import "RegistrationTerm.h"
#import "RegistrationPlannedSection.h"
#import "RegistrationPlannedSectionMeetingPattern.h"
#import "RegistrationPlannedSectionInstructor.h"
#import "Ellucian_GO-Swift.h"

@interface RegistrationTabBarController ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSMutableArray *plannedSections;
@property (nonatomic, strong) NSMutableArray *searchedSections;

@end

@implementation RegistrationTabBarController

@synthesize module_;

-(void)viewDidLoad
{
    [super viewDidLoad];


    UITabBarItem *tabBarItem0 = self.tabBar.items[0];
    tabBarItem0.selectedImage = [UIImage imageNamed:@"Registration Cart Selected"];
    UITabBarItem *tabBarItem2 = self.tabBar.items[2];
    tabBarItem2.selectedImage = [UIImage imageNamed:@"Registration Registered Tab Image Selected"];
    
    self.searchedSections = [NSMutableArray new];
    
    [self loadRegistration:self];
}

-(void) loadRegistration:(id)sender
{
    BOOL match = NO;
    
    for(ModuleRole *role in self.module.roles) {
        if([[CurrentUser sharedInstance].roles containsObject:role.role]) {
            match = YES;
            break;
        } else if ([ role.role isEqualToString:@"Everyone"]) {
            match = YES;
            break;
        }
    }
    
    if ( match ) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSString *loadingString = NSLocalizedString(@"Retrieving terms", @"loading message while fetching terms to use for search");
        hud.label.text = loadingString;
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString);
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            if ([self fetchTerms]) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                
                MBProgressHUD *hud2 = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                NSString *loadingString2 = NSLocalizedString(@"Checking Eligibility", @"checking registration eligibility message");
                hud2.label.text = loadingString2;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString2);
                
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    
                    self.registrationAllowed = [self checkRegistrationEligibility:self];
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    
                    MBProgressHUD *hud3 = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                    NSString *loadingString3 = NSLocalizedString(@"Fetching saved course sections", @"Fetching saved course sections message");
                    hud3.label.text = loadingString3;
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString3);
                    
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self fetchRegistrationPlans:self];
                        [MBProgressHUD hideHUDForView:self.view animated:YES];
                        
                        if([self itemsInCartCount] == 0 && !self.ineligibleMessage) {
                            self.selectedIndex = 1;
                        }
                        
                        if (self.planId == nil) {
                            //disable ability to add items to cart
                            [self passCartPermissionToSearchController:NO];
                        } else {
                            [self passCartPermissionToSearchController:YES];
                        }
                        
                        if(self.ineligibleMessage) {
                            UIAlertController *alertController = [UIAlertController
                                                                  alertControllerWithTitle:NSLocalizedString(@"Ineligible for Registration", @"Ineligible for Registration")
                                                                  message:self.ineligibleMessage
                                                                  preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *resetAction = [UIAlertAction
                                                          actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                                          style:UIAlertActionStyleDestructive
                                                          handler:nil];
                            [alertController addAction:resetAction];
                            [self presentViewController:alertController animated:YES completion:nil];
                        }
                    });
                });
            } else {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            }
        });
    } 
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CurrentUser.LoginExecutorSuccessNotification object:nil];
    
}

- (IBAction)revealMenu:(id)sender
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitController = self.viewControllers[1];
        UINavigationController *navigationController = splitController.viewControllers[0];
        RegistrationSearchViewController *searchController = (RegistrationSearchViewController *)navigationController.childViewControllers[0];
        [searchController.termTextField resignFirstResponder];
        [searchController.searchTextField resignFirstResponder];
    } else {
        UINavigationController *navigationController = self.viewControllers[1];
        RegistrationSearchViewController *searchController = (RegistrationSearchViewController *)navigationController.childViewControllers[0];
        [searchController.termTextField resignFirstResponder];
        [searchController.searchTextField resignFirstResponder];
    }
    [super revealMenu:sender];
}

-(BOOL) checkRegistrationEligibility:(id)sender
{
    NSError *error;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/eligibility", [self.module propertyForKey:@"registration"], [[[CurrentUser sharedInstance] userid]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];

    AuthenticatedRequest *authenticatedRequest = [AuthenticatedRequest new];
    NSDictionary *headers = @{@"Accept": @"application/vnd.hedtech.v1+json"};
    NSData *responseData = [authenticatedRequest requestURL:[NSURL URLWithString:urlString] fromView:self addHTTPHeaderFields:headers];

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    });
    
    if(responseData)
    {
        
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:kNilOptions
                              error:&error];
        BOOL eligible = [[json objectForKey:@"eligible"] boolValue];
        if(eligible)
        {
            self.ineligibleMessage = nil;
        } else {
            NSMutableArray *messagesArray = [NSMutableArray new];
            for(NSDictionary *dict in [json objectForKey:@"messages"]) {
                [messagesArray addObject:[dict objectForKey:@"message"]];
            }
            self.ineligibleMessage = [messagesArray componentsJoinedByString:@"\n"];
        }
        
        for(NSDictionary *termsDictionary in [json valueForKey:@"terms"]) {
            NSString *termId = [termsDictionary objectForKey:@"term"];
            RegistrationTerm *term = [self findTermById:termId];
            if(term) {
                term.eligible = [[termsDictionary objectForKey:@"eligible"] boolValue];
                term.requiresAltPin = [[termsDictionary objectForKey:@"requireAltPin"] boolValue];
            }
        }
        return eligible;
        
    } else {
        [self reportNetworkError];
        return NO;
    }
}

-(NSDateFormatter *)dateFormatter
{
    if(_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd"];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    return _dateFormatter;
}

-(NSDateFormatter *)timeFormatter
{
    if(_timeFormatter == nil) {
        _timeFormatter = [[NSDateFormatter alloc] init];
        [_timeFormatter setDateFormat:@"HH:mm'Z'"];
        [_timeFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    return _timeFormatter;
}

- (NSDateFormatter *)tzTimeFormatter:(NSString*)timeZone
{
    NSDateFormatter *tzTimeFormatter = [[NSDateFormatter alloc] init];
    [tzTimeFormatter setDateFormat:@"HH:mm'Z'"];
    [tzTimeFormatter setTimeZone:[NSTimeZone timeZoneWithName:timeZone]];
    return tzTimeFormatter;
}

- (void)fetchRegistrationPlans:(id)sender
{
    NSError *error;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/plans", [self.module propertyForKey:@"registration"], [[[CurrentUser sharedInstance] userid]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
    NSString* planningTool = [self.module propertyForKey:@"planningTool"];
    if(planningTool) {
        urlString = [NSString stringWithFormat:@"%@?planningTool=%@", urlString, planningTool];
    }

    AuthenticatedRequest *authenticatedRequest = [AuthenticatedRequest new];
    NSDictionary *headers = @{@"Accept": @"application/vnd.hedtech.v1+json"};
    NSData *responseData = [authenticatedRequest requestURL:[NSURL URLWithString:urlString] fromView:self addHTTPHeaderFields:headers];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    });
    
    if(responseData)
    {
        
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:kNilOptions
                              error:&error];
        
        NSMutableArray *plannedSections = [NSMutableArray new];
        NSMutableArray *searchedSections = [[NSMutableArray alloc] initWithArray:self.searchedSections];

        for(NSDictionary *planJson in [json objectForKey:@"plans"]) {
            self.planId = [planJson objectForKey:@"planId"];
            for(NSDictionary *termJson in [planJson objectForKey:@"terms"]) {
                NSString *termId = [termJson objectForKey:@"termId"];
                for(NSDictionary *plannedSectionJson in [termJson objectForKey:@"plannedCourses"]) {
                    RegistrationPlannedSection *plannedSection = [RegistrationPlannedSection new];
                    plannedSection.sectionId = [plannedSectionJson objectForKey:@"sectionId"];
                    plannedSection.courseId = [plannedSectionJson objectForKey:@"courseId"];
                    if([plannedSectionJson objectForKey:@"courseName"] != [NSNull null]) {
                        plannedSection.courseName = [plannedSectionJson objectForKey:@"courseName"];
                    }
                    plannedSection.courseSectionNumber = [plannedSectionJson objectForKey:@"courseSectionNumber"];
                    if([plannedSectionJson objectForKey:@"sectionTitle"] != [NSNull null]) {
                        plannedSection.sectionTitle = [plannedSectionJson objectForKey:@"sectionTitle"];
                    }
                    if([plannedSectionJson objectForKey:@"courseDescription"] != [NSNull null]) {
                        plannedSection.courseDescription = [plannedSectionJson objectForKey:@"courseDescription"];
                    }
                    if([plannedSectionJson objectForKey:@"credits"] != [NSNull null]) {
                        plannedSection.credits = [plannedSectionJson objectForKey:@"credits"];
                    }
                    if([plannedSectionJson objectForKey:@"minimumCredits"] != [NSNull null]) {
                        plannedSection.minimumCredits = [plannedSectionJson objectForKey:@"minimumCredits"];
                    }
                    if([plannedSectionJson objectForKey:@"maximumCredits"] != [NSNull null]) {
                        plannedSection.maximumCredits = [plannedSectionJson objectForKey:@"maximumCredits"];
                    }

                    if([plannedSectionJson objectForKey:@"variableCreditIncrement"] != [NSNull null]) {
                        plannedSection.variableCreditIncrement = [plannedSectionJson objectForKey:@"variableCreditIncrement"];
                    }
                    if([plannedSectionJson objectForKey:@"variableCreditOperator"] != [NSNull null]) {
                        plannedSection.variableCreditOperator = [plannedSectionJson objectForKey:@"variableCreditOperator"];
                    }
                    if([plannedSectionJson objectForKey:@"ceus"] != [NSNull null]) {
                        plannedSection.ceus = [plannedSectionJson objectForKey:@"ceus"];
                    }
                    plannedSection.status = [plannedSectionJson objectForKey:@"status"];
                    plannedSection.gradingType = [plannedSectionJson objectForKey:@"gradingType"];
                    
                    plannedSection.termId = termId;
                    plannedSection.classification = [plannedSectionJson objectForKey:@"classification"];
                    
                    if([plannedSectionJson objectForKey:@"firstMeetingDate"] != [NSNull null]) {
                        plannedSection.firstMeetingDate = [self.dateFormatter dateFromString:[plannedSectionJson objectForKey:@"firstMeetingDate"]];
                    }
                    
                    if([plannedSectionJson objectForKey:@"lastMeetingDate"] != [NSNull null]) {
                        plannedSection.lastMeetingDate = [self.dateFormatter dateFromString:[plannedSectionJson objectForKey:@"lastMeetingDate"]];
                    }
                    
                    //if there is a non zero value for CEUs, then make sure that the credits value is nil
                    if ( plannedSection.ceus && [plannedSection.ceus intValue] > 0 ) {
                        plannedSection.credits = nil;
                    }
                    if([plannedSectionJson objectForKey:@"location"] != [NSNull null]) {
                        plannedSection.location = [plannedSectionJson objectForKey:@"location"];
                    }
                    if([plannedSectionJson objectForKey:@"academicLevels"] != [NSNull null]) {
                        plannedSection.academicLevels = [plannedSectionJson objectForKey:@"academicLevels"];
                    }
                    
                    NSMutableArray *meetingPatterns = [NSMutableArray new];
                    for(NSDictionary *meetingPatternJson in [plannedSectionJson objectForKey:@"meetingPatterns"]) {
                        RegistrationPlannedSectionMeetingPattern *meetingPattern = [RegistrationPlannedSectionMeetingPattern new];
                        if([meetingPatternJson objectForKey:@"instructionalMethodCode"] != [NSNull null]) {
                            meetingPattern.instructionalMethodCode = [meetingPatternJson objectForKey:@"instructionalMethodCode"];
                        }
                        meetingPattern.startDate =  [self.dateFormatter dateFromString:[meetingPatternJson objectForKey:@"startDate"]];
                        meetingPattern.endDate =  [self.dateFormatter dateFromString:[meetingPatternJson objectForKey:@"endDate"]];
                        
                        if ([meetingPatternJson objectForKey:@"startTime"] && [meetingPatternJson objectForKey:@"startTime"] != [NSNull null]){
                            meetingPattern.startTime =  [self.timeFormatter dateFromString:[meetingPatternJson objectForKey:@"startTime"]];
                        }
                        
                        if([meetingPatternJson objectForKey:@"endTime"] && [meetingPatternJson objectForKey:@"endTime"] != [NSNull null]) {
                            meetingPattern.endTime =  [self.timeFormatter dateFromString:[meetingPatternJson objectForKey:@"endTime"]];
                        }
                        
                        if([meetingPatternJson objectForKey:@"sisStartTimeWTz"] && [meetingPatternJson objectForKey:@"sisStartTimeWTz"] != [NSNull null]) {
                            
                            NSString * sisStartTimeWTZ = [meetingPatternJson objectForKey:@"sisStartTimeWTz"];
                            NSArray  * startTimeComplex = [sisStartTimeWTZ componentsSeparatedByString:@" "];
                            if ( [startTimeComplex count] == 2 ) {
                                NSDateFormatter *tzTimeFormatter = [self tzTimeFormatter:startTimeComplex[1]];
                                meetingPattern.startTime = [tzTimeFormatter dateFromString:startTimeComplex[0]];
                            }
                        }
                        
                        if([meetingPatternJson objectForKey:@"sisEndTimeWTz"] && [meetingPatternJson objectForKey:@"sisEndTimeWTz"] != [NSNull null]) {
                            
                            NSString * sisEndTimeWTZ = [meetingPatternJson objectForKey:@"sisEndTimeWTz"];
                            NSArray  * endTimeComplex = [sisEndTimeWTZ componentsSeparatedByString:@" "];
                            if ( [endTimeComplex count] == 2 ) {
                                NSDateFormatter *tzTimeFormatter = [self tzTimeFormatter:endTimeComplex[1]];
                                meetingPattern.endTime = [tzTimeFormatter dateFromString:endTimeComplex[0]];
                            }
                        }
                        
                        
                        
                        meetingPattern.daysOfWeek = [meetingPatternJson objectForKey:@"daysOfWeek"];
                        if([meetingPatternJson objectForKey:@"room"] != [NSNull null]) {
                            meetingPattern.room = [meetingPatternJson objectForKey:@"room"];
                        }
                        //mp.frequency = [meetingPatternJson objectForKey:@"frequency"];
                        if([meetingPatternJson objectForKey:@"building"] != [NSNull null]) {
                            meetingPattern.building = [meetingPatternJson objectForKey:@"building"];
                        }
                        if([meetingPatternJson objectForKey:@"buildingId"] != [NSNull null]) {
                            meetingPattern.buildingId = [meetingPatternJson objectForKey:@"buildingId"];
                        }
                        if([meetingPatternJson objectForKey:@"campusId"] != [NSNull null]) {
                            meetingPattern.campusId = [meetingPatternJson objectForKey:@"campusId"];
                        }
                        
                        [meetingPatterns addObject:meetingPattern];
                    };
                    plannedSection.meetingPatterns = [meetingPatterns copy];
                    
                    NSMutableArray *instructors = [NSMutableArray new];
                    for(NSDictionary *instructorJson in [plannedSectionJson objectForKey:@"instructors"]) {
                        RegistrationPlannedSectionInstructor *instructor = [RegistrationPlannedSectionInstructor new];
                        if([instructorJson objectForKey:@"firstName"] != [NSNull null]) {
                            instructor.firstName = [instructorJson objectForKey:@"firstName"];
                        }
                        if([instructorJson objectForKey:@"lastName"] != [NSNull null]) {
                            instructor.lastName = [instructorJson objectForKey:@"lastName"];
                        }
                        if([instructorJson objectForKey:@"middleInitial"] != [NSNull null]) {
                            instructor.middleInitial = [instructorJson objectForKey:@"middleInitial"];
                        }
                        instructor.instructorId = [instructorJson objectForKey:@"instructorId"];
                        instructor.primary = [instructorJson objectForKey:@"primary"];
                        if([instructorJson objectForKey:@"formattedName"] != [NSNull null]) {
                            instructor.formattedName = [instructorJson objectForKey:@"formattedName"];
                        }
                        [instructors addObject:instructor];
                    };
                    plannedSection.instructors = [instructors copy];
                    [plannedSections addObject:plannedSection];
                    
                    if([plannedSectionJson objectForKey:@"authorizationCodeRequired"] != [NSNull null]) {
                        plannedSection.authorizationCodeRequired = [[plannedSectionJson objectForKey:@"authorizationCodeRequired"] boolValue];
                    }
                    if([plannedSectionJson objectForKey:@"authorizationCodePresented"] != [NSNull null]) {
                        plannedSection.authorizationCode = [plannedSectionJson objectForKey:@"authorizationCodePresented"];
                    }
                    
                    if([searchedSections containsObject:plannedSection]) {
                        [searchedSections removeObject:plannedSection];
                    }
                }
            }
        }
        self.plannedSections = plannedSections;
        self.searchedSections = searchedSections;
            
        [[NSNotificationCenter defaultCenter] postNotificationName:kRegistrationPlanDataReloaded object:nil];
        
    } else {
        [self reportNetworkError];
    }
}

-(int) itemsInCartCount
{
    int count = 0;
    for(RegistrationTerm *term in self.terms) {
        NSArray *plannedSections = [self sectionsInCart:term.termId];
        count += [plannedSections count];
    }
    return count;
}


-(void) addSearchedSection:(RegistrationPlannedSection *)section
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sectionId == %@ and termId == %@", section.sectionId, section.termId];
    NSArray *results = [[self sectionsInCart:section.termId ] filteredArrayUsingPredicate:predicate];
    if([results count] > 0) {
        for(RegistrationPlannedSection *section in results) {
            [self removeFromCart:section];
        }
    }
    [self.searchedSections addObject:section];
    [[NSNotificationCenter defaultCenter] postNotificationName:kRegistrationPlanDataReloaded object:nil];
}

-(BOOL) courseIsInCart:(RegistrationPlannedSection *)section
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sectionId == %@ and termId == %@", section.sectionId, section.termId];
    NSArray *results = [[self sectionsInCart:section.termId ] filteredArrayUsingPredicate:predicate];
    return [results count] > 0;
}

-(BOOL) courseIsRegistered:(RegistrationPlannedSection *)section
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sectionId == %@ and termId == %@ AND classification == %@", section.sectionId, section.termId, @"registered"];
    NSArray *results = [self.plannedSections filteredArrayUsingPredicate:predicate];
    return [results count] > 0;
}

-(BOOL) fetchTerms
{
    NSError *error;

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/terms", [self.module propertyForKey:@"registration"], [[[CurrentUser sharedInstance] userid]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
    AuthenticatedRequest *authenticatedRequest = [AuthenticatedRequest new];
    NSData *responseData = [authenticatedRequest requestURL:[NSURL URLWithString:urlString] fromView:self];

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    });
    
    if(responseData)
    {
        NSDictionary *termsJson = [NSJSONSerialization
                                   JSONObjectWithData:responseData
                                   options:kNilOptions
                                   error:&error];
        NSMutableArray *terms = [NSMutableArray new];
        for(NSDictionary *termJson in [termsJson objectForKey:@"terms"]) {
            RegistrationTerm *term = [RegistrationTerm new];
            [terms addObject:term];
            NSString *termId = [termJson objectForKey:@"id"];
            term.termId = termId;
            term.name = [termJson objectForKey:@"name"];
            term.startDate = [termJson objectForKey:@"startDate"];
            term.endDate = [termJson objectForKey:@"endDate"];
        }
        self.terms = [terms copy];
        return YES;
    } else {
        [self reportNetworkError];
        return NO;
    }
    return NO;
}

-(NSString *) termName:(NSString *)termId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"termId == %@", termId];
    NSArray *results = [self.terms filteredArrayUsingPredicate:predicate];
    RegistrationTerm *term = results[0];
    return term.name;
}

-(NSArray *) sectionsInCart:(NSString *) termId
{
    NSArray *plannedSections = [self plannedSections:termId];
    NSArray *searchedSections = [self searchedSections:termId];
    NSMutableArray *results = [NSMutableArray new];
    [results addObjectsFromArray:plannedSections];
    [results addObjectsFromArray:searchedSections];
    return results;
}

-(NSArray *) searchedSections:(NSString *) termId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"termId == %@", termId];
    NSArray *results = [self.searchedSections filteredArrayUsingPredicate:predicate];
    return results;
}

-(NSArray *) plannedSections:(NSString *) termId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"termId == %@ AND classification != %@", termId, @"registered"];
    NSArray *results = [self.plannedSections filteredArrayUsingPredicate:predicate];
    return results;
}

-(NSArray *) registeredSections:(NSString *) termId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"termId == %@ AND classification == %@", termId, @"registered"];
    NSArray *results = [self.plannedSections filteredArrayUsingPredicate:predicate];
    return results;
}

-(void) removeSearchedSection:(NSString *)sectionId term:(NSString *)termId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"termId == %@ AND sectionId == %@", termId, sectionId];
    NSArray *results = [self.searchedSections filteredArrayUsingPredicate:predicate];
    for(id section in results) {
        [self.searchedSections removeObject:section];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kRegistrationPlanDataReloaded object:nil];
}


- (void)passCartPermissionToSearchController:(BOOL)permission
{
    RegistrationSearchViewController *searchController = nil;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitController = self.viewControllers[1];
        UINavigationController *navigationController = splitController.viewControllers[0];
        searchController = (RegistrationSearchViewController *)navigationController.childViewControllers[0];
    } else {
        UINavigationController *navigationController = self.viewControllers[1];
        searchController = (RegistrationSearchViewController *)navigationController.childViewControllers[0];
    }
    
    searchController.allowAddToCart = permission;
}

-(RegistrationTerm *) findTermById:(NSString *) termId
{
    RegistrationTerm *term;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"termId == %@", termId];
    NSArray *filteredArray = [self.terms filteredArrayUsingPredicate:predicate];
    if ([filteredArray count] > 0) {
        term = [filteredArray firstObject];
    }
    return term;
}

-(void) reportError:(NSString *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Error", @"Error")
                                              message:error
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                   style:UIAlertActionStyleDefault
                                   handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

-(void) reportNetworkError
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Poor Network Connection", @"title when data cannot load due to a poor netwrok connection")
                                              message:NSLocalizedString(@"Data could not be retrieved.", @"message when data cannot load due to a poor netwrok connection")
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                   style:UIAlertActionStyleDefault
                                   handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

-(void) removeSection:(RegistrationPlannedSection *)section
{
    if([self.plannedSections containsObject:section]) {
        [self.plannedSections removeObject:section];
    }
    if([self.searchedSections containsObject:section]) {
        [self.searchedSections removeObject:section];
    }
}

-(void) removeFromCart:(RegistrationPlannedSection *) section
{
    
    NSMutableArray *termsToRegister = [NSMutableArray new];
    
    NSMutableArray *sectionRegistrations = [NSMutableArray new];
    
    NSString * gradingType = @"Graded";
    if (section.isAudit) {
        gradingType = @"Audit";
    } else if (section.isPassFail) {
        gradingType = @"PassFail";
    }
    NSMutableDictionary *sectionToRegister = [NSMutableDictionary new];
    [sectionToRegister setObject:section.sectionId forKey:@"sectionId"];
    [sectionToRegister setObject:@"remove" forKey:@"action"];
    if( section.credits ) {
        [sectionToRegister setObject: section.credits forKey:@"credits"];
    }
    if(section.ceus) {
        [sectionToRegister setObject: section.ceus forKey:@"ceus"];
    }
    [sectionToRegister setObject:gradingType forKey:@"gradingType"];
    [sectionRegistrations addObject:sectionToRegister];
    
    NSMutableDictionary *termToRegister = [NSMutableDictionary new];
    [termToRegister setObject:section.termId forKey:@"termId"];
    [termToRegister setObject:sectionRegistrations forKey:@"sections"];
    [termsToRegister addObject:termToRegister];
    
    NSMutableDictionary *postDictionary = [NSMutableDictionary new];
    [postDictionary setObject:termsToRegister forKey:@"terms"];
    if(self.planId) {
        [postDictionary setObject: self.planId forKey:@"planId"];
    }
    //this isn't doing what I think
    [self removeSection:section];
    
    NSError *jsonError;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:postDictionary options:NSJSONWritingPrettyPrinted error:&jsonError];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@/update-cart", [self.module propertyForKey:@"registration"], [[[CurrentUser sharedInstance] userid]  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
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
                        [self reportError:message];
                    });
                }
            }
        }
    }];
    [downloadTask resume];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRegistrationItemRemovedFromCart object:nil];
}

-(BOOL) containsSectionInCart:(RegistrationPlannedSection *) section
{
    return [self.plannedSections containsObject:section] ||
    [self.searchedSections containsObject:section];
}

@end
