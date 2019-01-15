//
//  RegistrationTabBarController.h
//  Mobile
//
//  Created by jkh on 1/8/14.
//  Copyright (c) 2014 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Ellucian_GO-Swift.h"

#define kRegistrationPlanDataReloaded @"RegistrationPlanDataReloaded"
#define kRegistrationItemRemovedFromCart @"RegistrationItemRemovedFromCart"

@class Module;
@class RegistrationPlannedSection;
@class RegistrationTerm;

@interface RegistrationTabBarController : UITabBarController <EllucianMobileLaunchableControllerProtocol>

@property (strong, nonatomic) Module *module;

@property (nonatomic, assign) BOOL registrationAllowed;
@property (nonatomic, strong) NSString *ineligibleMessage;
@property (nonatomic, strong) NSString *planId;
@property (nonatomic, strong) NSArray *terms;

- (void)fetchRegistrationPlans:(id)sender;
-(int) itemsInCartCount;
-(NSString *)termName:(NSString *)termId;
-(NSArray *) sectionsInCart:(NSString *) termId;
-(BOOL) containsSectionInCart:(RegistrationPlannedSection *) section;
-(NSArray *) registeredSections:(NSString *) termId;
-(void) addSearchedSection:(RegistrationPlannedSection *)section;
-(void) removeSearchedSection:(NSString *)sectionId term:(NSString *)termId;
-(RegistrationTerm *) findTermById:(NSString *) termId;
-(void) reportError:(NSString *)error;
-(void) reportNetworkError;
-(void) removeSection:(RegistrationPlannedSection *)section;
-(void) removeFromCart:(RegistrationPlannedSection *) section;
-(BOOL) courseIsInCart:(RegistrationPlannedSection *)section;
-(BOOL) courseIsRegistered:(RegistrationPlannedSection *)section;
@end
