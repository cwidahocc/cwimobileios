//
//  RegistrationPlannedSectionDetailViewController.m
//  Mobile
//
//  Created by jkh on 1/6/14.
//  Edited by amcewan on 3/10/2014
//  Copyright (c) 2014 Ellucian. All rights reserved.
//

#import "RegistrationPlannedSectionDetailViewController.h"
#import "Module.h"
#import "CourseDetailInstructor.h"
#import "RegistrationPlannedSectionMeetingPattern.h"
#import "CourseDetail.h"
#import "RegistrationTabBarController.h"
#import "RegistrationLocation.h"
#import "Ellucian_GO-Swift.h"

@interface RegistrationPlannedSectionDetailViewController ()
@property (strong, nonatomic) NSOrderedSet *meetingPatterns;
@property (strong, nonatomic) NSOrderedSet *instructors;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSDateFormatter *displayDateFormatter;
@property (nonatomic, strong) NSDateFormatter *displayTimeFormatter;
@property (nonatomic, strong) NSNumberFormatter *creditsFormatter;
@property (nonatomic, strong) NSDateFormatter *shortDisplayDateFormatter;

@end

@implementation RegistrationPlannedSectionDetailViewController


-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self adjustContraintsAccordingToContent];
    [self sendView:@"Registration Section Detail" moduleName:self.module.name];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.deleteButtonItem.tintColor = [UIColor whiteColor];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        self.maskView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.maskView setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:self.maskView];
        
    }
    
    if(self.deleteFromCartToolbar) {
        UIImage *registerButtonImage = [UIImage imageNamed:@"Registration Button"];
        [self.deleteFromCartToolbar setBackgroundImage:registerButtonImage forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    }
    
    [self.scrollView invalidateIntrinsicContentSize];
    
    self.navigationController.navigationBar.translucent = NO;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {

        self.courseSectionNumberLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course name-section number", @"Localizable", [NSBundle mainBundle], @"%@-%@", @"course name-section number"), self.registrationPlannedSection.courseName, self.registrationPlannedSection.courseSectionNumber];
        self.courseNameLabel.text = self.registrationPlannedSection.sectionTitle;
        
        if (self.registrationPlannedSection.isPassFail){
            self.gradingContent.text = NSLocalizedString(@"Pass/Fail", @"PassFail label for registration");
        } else if (self.registrationPlannedSection.isGraded){
            self.gradingContent.text = NSLocalizedString(@"Graded", @"Graded label for registration");
        } else if (self.registrationPlannedSection.isAudit){
            self.gradingContent.text = NSLocalizedString(@"Audit", @"Audit label for registration");
        }
    
        if(self.registrationPlannedSection.firstMeetingDate && self.registrationPlannedSection.lastMeetingDate) {
            NSString *dates = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course first meeting - last meeting", @"Localizable", [NSBundle mainBundle], @"%@ - %@", @"course first meeting - last meeting"), [self.displayDateFormatter stringFromDate:self.registrationPlannedSection.firstMeetingDate], [self.displayDateFormatter stringFromDate:self.registrationPlannedSection.lastMeetingDate]];
            self.meetingDateLabel.text = dates;
        } else {
            self.meetingDateLabel.text = @"";
        }
        //self.sectionLabel.text = @"Section ID:";
        self.sectionContent.text = self.registrationPlannedSection.sectionId;
        self.academicLevelsLabel.text = [self.registrationPlannedSection.academicLevels componentsJoinedByString:@","];
    
        //self.creditsLabel.text = @"Credits:";
        if ( self.registrationPlannedSection.credits ) {
            //self.creditsLabel.text = @"Credits:";
            if([self.registrationTabController containsSectionInCart:self.registrationPlannedSection]) {
                self.creditsContent.text = [NSString stringWithFormat:@"%@", [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.credits ]];
            } else if ( self.registrationPlannedSection.isVariableCredit ) {
                if([self.registrationPlannedSection.variableCreditOperator isEqualToString:@"OR"]) {
                    self.creditsContent.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration planned section detail variable credits (or)", @"Localizable", [NSBundle mainBundle], @"%@ / %@", @"registration planned section detail variable credits (or)"), [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.minimumCredits], [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.maximumCredits]];
                } else {
                    self.creditsContent.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration planned section detail variable credits (to)", @"Localizable", [NSBundle mainBundle], @"%@ - %@", @"registration planned section detail variable credits (to)"), [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.minimumCredits], [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.maximumCredits]];
                }
            } else {
                self.creditsContent.text = [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.credits];
            }
        }
        else if ( self.registrationPlannedSection.ceus ) {
            NSString * ceusText = [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.ceus];
            
            if ([self.registrationPlannedSection.ceus doubleValue] > 1.0 ){
                self.creditsContent.text = [NSString stringWithFormat:NSLocalizedString(@"%@ CEUs", @"CEUs label for registration"), ceusText];
            }
            else if ([self.registrationPlannedSection.ceus doubleValue] <= 1.0 ){
                self.creditsContent.text = [NSString stringWithFormat:NSLocalizedString(@"%@ CEU", @"CEU (singular) label for registration"), ceusText];
            }
        }
        
        
        if (self.availableSeatsView && self.registrationPlannedSection.available && self.registrationPlannedSection.capacity && self.registrationPlannedSection.capacity > 0) {
            self.availableSeatsView.layer.cornerRadius = 6.0f;
            self.availableSeatsView.layer.borderColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0].CGColor;
            self.availableSeatsView.layer.borderWidth = 1.0f;
            
            NSNumber *available = self.registrationPlannedSection.available;
            NSNumber *capacity = self.registrationPlannedSection.capacity;
            
            
            float z = [available floatValue] / [capacity floatValue];
            float delta = 1.0f / 6.0f;
            if ([available intValue] <= 0) {
                self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-full"];
            } else if(z <= delta) {
                self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-5-full"];
            } else if(z <= delta*2) {
                self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-4-full"];
            } else if(z <= delta*3) {
                self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-3-full"];
            } else if(z <= delta*4) {
                self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-2-full"];
            } else if(z <= delta*5) {
                self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-1-full"];
            } else {
                self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-default"];
            }
            
            if ([self.availableSeatsMeterImage.image respondsToSelector:@selector(imageFlippedForRightToLeftLayoutDirection)]) {
                if ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.availableSeatsMeterImage.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft) {
                    self.availableSeatsMeterImage.image = self.availableSeatsMeterImage.image.imageFlippedForRightToLeftLayoutDirection;
                }
            }
            
            self.availableSeatsLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"available seats/capacity", @"Localizable", [NSBundle mainBundle], @"%@/%@", @"available seats/capacity"), available, capacity];
            self.availableSeatsSpacingConstraint.constant = 10;
            self.availableSeatsViewHeightConstraint.constant = 16;
            self.availableSeatsLabelLabel.hidden = NO;
            self.availableSeatsView.hidden = NO;
        } else {
            self.availableSeatsSpacingConstraint.constant = 0;
            self.availableSeatsViewHeightConstraint.constant = 0;
            self.availableSeatsLabelLabel.hidden = YES;
            self.availableSeatsView.hidden = YES;
        }

        
        
        //self.meetingLabel.text = @"Meets";
        [self extractMeetingContent];

        //self.facultyLabel.text = @"Faculty";
        [self extractFacultyContentForPhone];
        
        self.descriptionContent.text = self.registrationPlannedSection.courseDescription;
        self.descriptionLabel.hidden = self.registrationPlannedSection.courseDescription == nil;
        [self adjustContraintsAccordingToContent];
        
        self.titleBackgroundView.backgroundColor = [UIColor accent];
    }
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.scrollView setContentOffset:CGPointZero animated:YES];
}


-(void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self adjustContraintsAccordingToContent];
    if(self.maskView)
    {
        [self.maskView removeFromSuperview];
        self.maskView = nil;
        [self clearView];
    }
}

-(void) extractFacultyContentForPhone
{
    id lastObject = self.facultyContent;
    
    CGFloat fontSize = 13.0f;
    NSInteger facultyContentHeight = 10;
    
    NSArray * instructors = self.registrationPlannedSection.instructors;
    //int instructorCount = 10;
    NSInteger instructorCount = [instructors count];

    if ( instructorCount > 0 )
        facultyContentHeight = 0;
    
    //remove all subviews
    [[self.facultyContent subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (NSInteger iter = 0; iter < instructorCount; iter++) {
        
        CourseDetailInstructor *instructor = [instructors objectAtIndex:iter];
        
        //faculty name
        UILabel *facultyLabel = [UILabel new];
        facultyLabel.backgroundColor = [UIColor clearColor];
        facultyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        facultyLabel.text = instructor.formattedName;
        facultyLabel.font = [UIFont systemFontOfSize:fontSize];
        [facultyLabel sizeToFit];
        [self.facultyContent addSubview:facultyLabel];
        
        NSInteger labelHeight = facultyLabel.frame.size.height;
        
        facultyContentHeight += labelHeight;

        [self.facultyContent addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[facultyLabel]-(10)-|"
                                                 options:0 metrics:nil
                                                   views:@{@"facultyLabel":facultyLabel}]];

        if ( instructorCount == 1 )
        {
            [self.facultyContent addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[facultyLabel]-(1)-|"
                                                     options:0 metrics:nil
                                                       views:@{@"facultyLabel":facultyLabel}]];
            facultyContentHeight += 6;
            
        } else if ( instructorCount > 1 ){
            if ( iter == 0 ) {
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[facultyLabel]"
                                                         options:0 metrics:nil
                                                           views:@{@"facultyLabel":facultyLabel}]];
                facultyContentHeight += 3;
                
            } else if ( 0 < iter < (instructorCount-1) ){
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevLabel]-(1)-[facultyLabel]"
                                                         options:0 metrics:nil
                                                           views:@{@"facultyLabel":facultyLabel, @"prevLabel":lastObject}]];
                facultyContentHeight += 3;
                
            } else if ( iter == (instructorCount - 1) ){
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[facultyLabel]-(1)-|"
                                                         options:0 metrics:nil
                                                           views:@{@"facultyLabel":facultyLabel}]];
                facultyContentHeight += 3;
            }
        }
        
        lastObject = facultyLabel;
    }
    self.facultyConstraint.constant = facultyContentHeight;
}

-(void) extractFacultyContentForPad
{
    id lastSeparator = nil;
    NSInteger constraintA=6;
    NSInteger constraintC=12;
    NSInteger constraintD=3;
    
    NSArray * instructors = self.registrationPlannedSection.instructors;
    //int instructorCount = 10;
    NSInteger instructorCount = [instructors count];
    CGFloat fontSize = 13.0f;
    NSInteger facultyContentHeight = 20;
    
    if ( instructorCount > 0 )
        facultyContentHeight = 0;
    
    //remove all subviews
    [[self.facultyContent subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (NSInteger iter = 0; iter < instructorCount; iter++) {
        
        CourseDetailInstructor *instructor = [instructors objectAtIndex:iter];
        
        //faculty name
        UILabel *facultyLabel = [UILabel new];
        facultyLabel.backgroundColor = [UIColor clearColor];
        facultyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        facultyLabel.text = instructor.formattedName;
        facultyLabel.font = [UIFont systemFontOfSize:fontSize];
        [facultyLabel sizeToFit];
        [self.facultyContent addSubview:facultyLabel];
        
        NSInteger labelHeight = facultyLabel.frame.size.height;
        
        facultyContentHeight += labelHeight;
        
        [self.facultyContent addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[facultyLabel]-(10)-|"
                                                 options:0 metrics:nil
                                                   views:@{@"facultyLabel":facultyLabel}]];
        
        if ( instructorCount == 1 )
        {
            [self.facultyContent addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[facultyLabel]-(0)-|"
                                                     options:0 metrics:nil
                                                       views:@{@"facultyLabel":facultyLabel}]];
            facultyContentHeight += constraintA;
            
        } else if ( instructorCount > 1 ){
            if ( iter == 0 ) {
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[facultyLabel]"
                                                         options:0 metrics:nil
                                                           views:@{@"facultyLabel":facultyLabel}]];
                facultyContentHeight += constraintD;
                
                UIView *separatorLine = [self createSeparatorLine];
                
                [self.facultyContent addSubview:separatorLine];
                
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[facultyLabel]-(2)-[separator]"
                                                         options:0 metrics:nil
                                                           views:@{@"facultyLabel":facultyLabel, @"separator":separatorLine}]];
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[separator]-(0)-|"
                                                         options:0 metrics:nil
                                                           views:@{@"separator":separatorLine}]];
                
                [separatorLine addConstraint:[NSLayoutConstraint constraintWithItem:separatorLine
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:1]];
                
                lastSeparator = separatorLine;
                
            } else if ( (0 < iter) && (iter < (instructorCount-1)) ){
                
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevSeparator]-(2)-[facultyLabel]"
                                                         options:0 metrics:nil
                                                           views:@{@"facultyLabel":facultyLabel, @"prevSeparator":lastSeparator}]];
                
                facultyContentHeight += constraintC;
                
                UIView *separatorLine = [self createSeparatorLine];
                
                [self.facultyContent addSubview:separatorLine];
                
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[facultyLabel]-(2)-[separator]"
                                                         options:0 metrics:nil
                                                           views:@{@"facultyLabel":facultyLabel, @"separator":separatorLine}]];
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[separator]-(0)-|"
                                                         options:0 metrics:nil
                                                           views:@{@"separator":separatorLine}]];
                
                [separatorLine addConstraint:[NSLayoutConstraint constraintWithItem:separatorLine
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:1]];
                
                lastSeparator = separatorLine;
                
            } else if ( iter == (instructorCount - 1) ){
                
                [self.facultyContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevSeparator]-(2)-[facultyLabel]"
                                                         options:0 metrics:nil
                                                           views:@{@"facultyLabel":facultyLabel, @"prevSeparator":lastSeparator}]];
                facultyContentHeight += constraintD;
                
            }
        }
    }
    self.facultyConstraint.constant = facultyContentHeight;
}

-(void) extractMeetingContent
{
    id lastSeparator = nil;
    
    NSArray *meetingPatterns = self.registrationPlannedSection.meetingPatterns;
    
    //NSInteger meetingCount = 1;
    NSInteger meetingCount = [meetingPatterns count];
    
    NSInteger meetingContentHeight = 20;
    NSInteger constraintA=6;
    NSInteger constraintB=8;
    NSInteger constraintC=12;
    CGFloat fontSize = 13.0f;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        meetingContentHeight = 10;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        meetingContentHeight = 20;
        fontSize = 13.0f;
    }
    
    if (meetingCount > 0)
        meetingContentHeight = 0;
    
    //remove all subviews
    [[self.meetingContent subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (NSInteger iter = 0; iter < meetingCount; iter++) {
        
        RegistrationPlannedSectionMeetingPattern *mp = [meetingPatterns objectAtIndex:iter];
        
        NSString * meetingContent = @"";
        //mp:days
        NSMutableArray *daysOfClass = [mp.daysOfWeek mutableCopy];
        NSArray *localizedDays = [self.dateFormatter shortStandaloneWeekdaySymbols];
        for(int i = 0; i < [daysOfClass count]; i++) {
            NSInteger value = [[daysOfClass objectAtIndex:i] intValue] - 1;
                [daysOfClass replaceObjectAtIndex:i withObject:[localizedDays objectAtIndex:value]];
        }
        
        //mp:time
        NSString *days = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"days:", @"Localizable", [NSBundle mainBundle], @"%@: ", @"days:"), [daysOfClass componentsJoinedByString:@", "]];
        NSString *line1;
        BOOL sectionDatesMatchesMeetingPatternDates = (mp.startDate == self.registrationPlannedSection.firstMeetingDate) && (mp.endDate == self.registrationPlannedSection.lastMeetingDate);
        if(mp.instructionalMethodCode) {
            if (sectionDatesMatchesMeetingPatternDates) {
                line1 = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"days start - end method", @"Localizable", [NSBundle mainBundle], @"%@ %@ - %@ %@", @"days start - end method"), days, [self.displayTimeFormatter stringFromDate: mp.startTime], [self.displayTimeFormatter stringFromDate:mp.endTime], mp.instructionalMethodCode];
            } else {
                if (mp.startDate == mp.endDate) {
                    line1 = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"days startdate starttime - endtime method", @"Localizable", [NSBundle mainBundle], @"%@ %@ %@ - %@ %@", @"days startdate starttime - endtime method"), days, [self.shortDisplayDateFormatter stringFromDate: mp.startDate], [self.displayTimeFormatter stringFromDate: mp.startTime], [self.displayTimeFormatter stringFromDate:mp.endTime], mp.instructionalMethodCode];
                } else {
                    line1 = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"days startdate - enddate starttime - endtime method", @"Localizable", [NSBundle mainBundle], @"%@ %@ - %@ %@ - %@ %@", @"days startdate - enddate starttime - endtime method"), days, [self.shortDisplayDateFormatter stringFromDate: mp.startDate], [self.shortDisplayDateFormatter stringFromDate: mp.endDate], [self.displayTimeFormatter stringFromDate: mp.startTime], [self.displayTimeFormatter stringFromDate:mp.endTime], mp.instructionalMethodCode];
                }
            }

        } else {
            if (sectionDatesMatchesMeetingPatternDates) {
                line1 = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"days start - end", @"Localizable", [NSBundle mainBundle], @"%@ %@ - %@", @"days start - end"), days, [self.displayTimeFormatter stringFromDate: mp.startTime], [self.displayTimeFormatter stringFromDate:mp.endTime]];
            } else {
                if (mp.startDate == mp.endDate) {
                    line1 = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"days startdate starttime - endtime", @"Localizable", [NSBundle mainBundle], @"%@ %@ %@ - %@", @"days startdate starttime - endtime"), days, [self.shortDisplayDateFormatter stringFromDate: mp.startDate], [self.displayTimeFormatter stringFromDate: mp.startTime], [self.displayTimeFormatter stringFromDate:mp.endTime]];
                } else {
                    line1 = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"days startdate - enddate starttime - endtime", @"Localizable", [NSBundle mainBundle], @"%@ %@ - %@ %@ - %@", @"days startdate - enddate starttime - endtime"), days, [self.shortDisplayDateFormatter stringFromDate: mp.startDate], [self.shortDisplayDateFormatter stringFromDate: mp.endDate], [self.displayTimeFormatter stringFromDate: mp.startTime], [self.displayTimeFormatter stringFromDate:mp.endTime]];
                }
            }
        }

        NSMutableAttributedString *attributedLine1 =[[NSMutableAttributedString alloc]initWithString:line1];
        [attributedLine1 addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:fontSize+2.0f] range:NSMakeRange(0, [days length])];

        if ([meetingContent length] == 0){
            meetingContent = attributedLine1.string;
        } else {
            meetingContent = [meetingContent stringByAppendingString:@"\r"];
            meetingContent = [meetingContent stringByAppendingString:attributedLine1.string];
        }

        NSString *location = @"";
        if(mp.building && mp.room) {
            location = [NSString stringWithFormat:NSLocalizedString(@"%@, Room %@", @"label - building name, room number"), mp.building, mp.room];
        } else if(mp.building) {
            location = mp.building;
        } else  if(mp.room) {
            location = [NSString stringWithFormat:NSLocalizedString(@"Room %@", @"label - room number"), mp.room];
        }

        if([location length] > 0) {
            meetingContent = [meetingContent stringByAppendingString:@"\r"];
            meetingContent = [meetingContent stringByAppendingString:location];
        }
        if(mp.campusId) {
            NSError *error;
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"RegistrationLocation"];
            request.predicate = [NSPredicate predicateWithFormat:@"moduleId == %@ AND code == %@", self.module.internalKey, mp.campusId];
            RegistrationLocation *coreDataLocation = [[self.module.managedObjectContext executeFetchRequest:request error:&error] lastObject];
            meetingContent = [meetingContent stringByAppendingString:@"\r"];

            if(coreDataLocation) {
                meetingContent = [meetingContent stringByAppendingString:coreDataLocation.name];
            } else {
                meetingContent = [meetingContent stringByAppendingString:mp.campusId];
            }
        }
    
        UILabel *meetingLabel = [UILabel new];
        meetingLabel.backgroundColor = [UIColor clearColor];
        meetingLabel.translatesAutoresizingMaskIntoConstraints = NO;
        meetingLabel.lineBreakMode = NSLineBreakByWordWrapping;
        meetingLabel.text = meetingContent;
        meetingLabel.font = [UIFont systemFontOfSize:fontSize];
        meetingLabel.numberOfLines = 0;
        [meetingLabel sizeToFit];
        [self.meetingContent addSubview:meetingLabel];
        
        CGFloat minLabelWidth = MIN(self.view.bounds.size.width, self.view.bounds.size.height) - 20;
        CGSize neededSize = [meetingLabel sizeThatFits:CGSizeMake(minLabelWidth, CGFLOAT_MAX)]; 
        
        NSInteger labelHeight = neededSize.height;
        
        meetingContentHeight += labelHeight;
        
        [self.meetingContent addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[meetingLabel]-(0)-|"
                                                 options:0 metrics:nil
                                                   views:@{@"meetingLabel":meetingLabel}]];
        
        if ( meetingCount == 1 )
        {
            [self.meetingContent addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[meetingLabel]-(3)-|"
                                                     options:0 metrics:nil
                                                       views:@{@"meetingLabel":meetingLabel}]];
            meetingContentHeight += constraintA;
            
        } else if ( meetingCount > 1 ){
            if ( iter == 0 ) {
                [self.meetingContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(0)-[meetingLabel]"
                                                         options:0 metrics:nil
                                                           views:@{@"meetingLabel":meetingLabel}]];
                meetingContentHeight += constraintB;
                
                UIView *separatorLine = [self createSeparatorLine];
                
                [self.meetingContent addSubview:separatorLine];
                
                [self.meetingContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[meetingLabel]-(3)-[separator]"
                                                         options:0 metrics:nil
                                                           views:@{@"meetingLabel":meetingLabel, @"separator":separatorLine}]];
                [self.meetingContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[separator]-(0)-|"
                                                         options:0 metrics:nil
                                                           views:@{@"separator":separatorLine}]];
                
                [separatorLine addConstraint:[NSLayoutConstraint constraintWithItem:separatorLine
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:1]];
                
                lastSeparator = separatorLine;
                
            } else if ( (0 < iter) && (iter < (meetingCount-1)) ){
                [self.meetingContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevSeparator]-(3)-[meetingLabel]"
                                                         options:0 metrics:nil
                                                           views:@{@"meetingLabel":meetingLabel, @"prevSeparator":lastSeparator}]];
                
                meetingContentHeight += constraintC;
                
                UIView *separatorLine = [self createSeparatorLine];
                
                [self.meetingContent addSubview:separatorLine];
                
                [self.meetingContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[meetingLabel]-(5)-[separator]"
                                                         options:0 metrics:nil
                                                           views:@{@"meetingLabel":meetingLabel, @"separator":separatorLine}]];
                [self.meetingContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[separator]-(0)-|"
                                                         options:0 metrics:nil
                                                           views:@{@"separator":separatorLine}]];
                
                [separatorLine addConstraint:[NSLayoutConstraint constraintWithItem:separatorLine
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:1]];
                
                lastSeparator = separatorLine;
                
            } else if ( iter == (meetingCount-1) ){
                
                [self.meetingContent addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevSeparator]-(5)-[meetingLabel]"
                                                         options:0 metrics:nil
                                                           views:@{@"meetingLabel":meetingLabel, @"prevSeparator":lastSeparator}]];
                meetingContentHeight += constraintC;
            }
        }
    }
    self.meetingConstraint.constant = meetingContentHeight;
}

-(UIView*)createSeparatorLine
{
    UIView *separatorLine = [UIView new];
    separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    [separatorLine setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.3]];
    return separatorLine;
}

-(void) adjustContraintsAccordingToContent
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGSize newSize;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            CGSize trialSize = CGSizeMake(510.0f, 1.0f);
            newSize = [self.descriptionContent sizeThatFits:trialSize];
            self.creditLabelConstraint.constant = 197;
        } else {
            CGSize trialSize = CGSizeMake(388.0f, 1.0f);
            newSize = [self.descriptionContent sizeThatFits:trialSize];
            self.creditLabelConstraint.constant = 40;
        }
    } else {
        self.widthConstraint.constant = [UIScreen mainScreen].bounds.size.width;
        CGSize trialSize = CGSizeMake(self.widthConstraint.constant-20.0f, 1.0f);
        newSize = [self.descriptionContent sizeThatFits:trialSize];
    }

    self.descriptionConstraint.constant = newSize.height;

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

-(NSDateFormatter *)shortDisplayDateFormatter
{
    if(_shortDisplayDateFormatter == nil) {
        _shortDisplayDateFormatter = [[NSDateFormatter alloc] init];
        [_shortDisplayDateFormatter setLocalizedDateFormatFromTemplate:@"Md"];
        [_shortDisplayDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    }
    return _shortDisplayDateFormatter;
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

-(NSDateFormatter *)displayTimeFormatter
{
    if(_displayTimeFormatter == nil) {
        _displayTimeFormatter = [[NSDateFormatter alloc] init];
        [_displayTimeFormatter setDateStyle:NSDateFormatterNoStyle];
        [_displayTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return _displayTimeFormatter;
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

-(void)selectedDetail:(id)newSection withIndex:(NSIndexPath*)myIndex withModule:(Module*)myModule withController:(id)myController
{
    if ( [newSection isKindOfClass:[RegistrationPlannedSection class]] )
    {
        [self setSection:(RegistrationPlannedSection *)newSection];
        [self setModule:myModule];
    }
}

-(void)setSection:(RegistrationPlannedSection *)section
{
    if (_registrationPlannedSection != section) {
        _registrationPlannedSection = section;
        
        [self refreshUI];
    }
}

-(void)refreshUI
{
    if(self.maskView != nil)
    {
        [self.maskView removeFromSuperview];
        self.maskView = nil;
    }
    
    [self.scrollView invalidateIntrinsicContentSize];
    
    self.navigationController.navigationBar.translucent = NO;
    
    self.courseSectionNumberLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course name-section number", @"Localizable", [NSBundle mainBundle], @"%@-%@", @"course name-section number"), self.registrationPlannedSection.courseName, self.registrationPlannedSection.courseSectionNumber];
    self.courseNameLabel.text = self.registrationPlannedSection.sectionTitle;
    
    //self.sectionLabel.text = @"Section ID:";
    self.sectionContent.text = self.registrationPlannedSection.sectionId;
    self.academicLevelsLabel.text = [self.registrationPlannedSection.academicLevels componentsJoinedByString:@","];
    
    if (self.registrationPlannedSection.isPassFail){
        self.gradingContent.text = NSLocalizedString(@"Pass/Fail", @"PassFail label for registration");
    } else if (self.registrationPlannedSection.isGraded){
        self.gradingContent.text = NSLocalizedString(@"Graded", @"Graded label for registration");
    } else if (self.registrationPlannedSection.isAudit){
        self.gradingContent.text = NSLocalizedString(@"Audit", @"Audit label for registration");
    }
    
    if(self.registrationPlannedSection.firstMeetingDate && self.registrationPlannedSection.lastMeetingDate) {
        NSString *dates = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"course first meeting - last meeting", @"Localizable", [NSBundle mainBundle], @"%@ - %@", @"course first meeting - last meeting"), [self.displayDateFormatter stringFromDate:self.registrationPlannedSection.firstMeetingDate], [self.displayDateFormatter stringFromDate:self.registrationPlannedSection.lastMeetingDate]];
        self.meetingDateLabel.text = dates;
    } else {
        self.meetingDateLabel.text = @"";
    }
    
    if ( self.registrationPlannedSection.credits ) {
        //self.creditsLabel.text = @"Credits:";
        if(self.registrationPlannedSection.selectedInCart) {
            self.creditsContent.text = [NSString stringWithFormat:@"%@", self.registrationPlannedSection.credits ];
        } else if ( self.registrationPlannedSection.isVariableCredit ) {
            if([self.registrationPlannedSection.variableCreditOperator isEqualToString:@"OR"]) {
                self.creditsContent.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration planned section detail variable credits (or)", @"Localizable", [NSBundle mainBundle], @"%@ / %@", @"registration planned section detail variable credits (or)"), [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.minimumCredits], [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.maximumCredits]];
            } else {
                self.creditsContent.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"registration planned section detail variable credits (to)", @"Localizable", [NSBundle mainBundle], @"%@ - %@", @"registration planned section detail variable credits (to)"), [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.minimumCredits], [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.maximumCredits]];
            }
        } else {
            self.creditsContent.text = [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.credits];
        }
    } else if ( self.registrationPlannedSection.ceus ) {
        NSString * ceusText = [self.creditsFormatter stringFromNumber:self.registrationPlannedSection.ceus];
        if ( [self.registrationPlannedSection.ceus doubleValue] > 1.0 ) {
            
            self.creditsContent.text = [ceusText stringByAppendingString:NSLocalizedString(@"CEUs", @"CEUs label for registration") ];
        } else if ([self.registrationPlannedSection.ceus doubleValue] <= 1.0 ){
            self.creditsContent.text = [ceusText stringByAppendingString:NSLocalizedString(@"CEU", @"CEU (singular) label for registration")];
        }
        
    }
    
    if (self.availableSeatsView && self.registrationPlannedSection.available && self.registrationPlannedSection.capacity && self.registrationPlannedSection.capacity > 0) {
        self.availableSeatsView.layer.cornerRadius = 6.0f;
        self.availableSeatsView.layer.borderColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0].CGColor;
        self.availableSeatsView.layer.borderWidth = 1.0f;
        
        NSNumber *available = self.registrationPlannedSection.available;
        NSNumber *capacity = self.registrationPlannedSection.capacity;
        
        
        float z = [available floatValue] / [capacity floatValue];
        float delta = 1.0f / 6.0f;
        if ([available intValue] <= 0) {
            self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-full"];
        } else if(z <= delta) {
            self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-5-full"];
        } else if(z <= delta*2) {
            self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-4-full"];
        } else if(z <= delta*3) {
            self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-3-full"];
        } else if(z <= delta*4) {
            self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-2-full"];
        } else if(z <= delta*5) {
            self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-1-full"];
        } else {
            self.availableSeatsMeterImage.image = [UIImage imageNamed:@"seats-available-default"];
        }

        self.availableSeatsLabel.text = [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"available seats/capacity", @"Localizable", [NSBundle mainBundle], @"%@/%@", @"available seats/capacity"), available, capacity];
        self.availableSeatsSpacingConstraint.constant = 10;
        self.availableSeatsViewHeightConstraint.constant = 16;
        self.availableSeatsLabelLabel.hidden = NO;
        self.availableSeatsView.hidden = NO;
    } else {
        self.availableSeatsSpacingConstraint.constant = 0;
        self.availableSeatsViewHeightConstraint.constant = 0;
        self.availableSeatsLabelLabel.hidden = YES;
        self.availableSeatsView.hidden = YES;
    }
    
    //self.meetingLabel.text = @"Meets";
    [self extractMeetingContent];
    
    //self.facultyLabel.text = @"Faculty";
    [self extractFacultyContentForPad];

    self.descriptionContent.text = self.registrationPlannedSection.courseDescription;
    self.descriptionLabel.hidden = self.registrationPlannedSection.courseDescription == nil;
    
    self.titleBackgroundView.backgroundColor = [UIColor accent];
    [self adjustContraintsAccordingToContent];
    
    [self.view setNeedsDisplay];
    
}

#pragma mark - UISplitViewDelegate methods
//-(void)splitViewController:(UISplitViewController *)svc
//    willHideViewController:(UIViewController *)aViewController
//         withBarButtonItem:(UIBarButtonItem *)barButtonItem
//      forPopoverController:(UIPopoverController *)pc
//{
//    //Grab a reference to the popover
//    self.masterPopover = pc;
//    
//    //Set the title of the bar button item
//    barButtonItem.title = self.module.name;
//}
//
//-(void)splitViewController:(UISplitViewController *)svc
//    willShowViewController:(UIViewController *)aViewController
// invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
//{
//    //Nil out the pointer to the popover.
//    _masterPopover = nil;
//}

- (IBAction) deleteFromCart:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", comment: @"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    UIAlertAction *removeAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", comment: @"Remove button") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.registrationTabController removeFromCart:self.registrationPlannedSection];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self clearView];
        }

    }];
    [alertController addAction:removeAction];
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alertController.popoverPresentationController.barButtonItem = self.deleteButtonItem;
    } else {
        alertController.popoverPresentationController.sourceView = self.navigationController.toolbar;
        alertController.popoverPresentationController.sourceRect = self.navigationController.toolbar.bounds;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
    

}

-(RegistrationTabBarController *) registrationTabController
{
    return  (RegistrationTabBarController *)[self tabBarController];
}

-(void) clearView
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        self.maskView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.maskView setBackgroundColor:[UIColor whiteColor]];
        [self.view addSubview:self.maskView];
        [self.navigationController setToolbarHidden:YES];
    }
}



@end
