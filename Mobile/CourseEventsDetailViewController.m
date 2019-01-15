//
//  CourseEventsDetailViewController.m
//  Mobile
//
//  Created by Jason Hocker on 8/7/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import "CourseEventsDetailViewController.h"
#import "Ellucian_GO-Swift.h"

@interface CourseEventsDetailViewController ()
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) NSDateFormatter *dateFormatterShare;
@end

@implementation CourseEventsDetailViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.padToolBar setHidden:YES];
        [self.navigationController setToolbarHidden:NO animated:NO];
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.padToolBar setHidden:NO];
        [self.navigationController setToolbarHidden:YES animated:NO];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
    self.navigationController.navigationBar.translucent = NO;
    
    UIBarButtonItem *addCalendarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add-to-calendar"] style:UIBarButtonItemStylePlain target:self action:@selector(addToMyCalendar:)];
    
    UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc]  initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if ((UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) && self.eventTitle != nil) {
        self.toolbarItems = [ NSArray arrayWithObjects: addCalendarButtonItem, flexibleSpace, shareButtonItem, nil ];
    } else {
        [self.padToolBar setItems:[ NSArray arrayWithObjects: addCalendarButtonItem, flexibleSpace, shareButtonItem, nil ] animated:NO];
        self.padToolBar.translucent = NO;
        UIImage *registerButtonImage = [UIImage imageNamed:@"Registration Button"];
        [self.padToolBar setBackgroundImage:registerButtonImage forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
        self.padToolBar.tintColor = [UIColor whiteColor];
    }
    
    self.eventStore = [[EKEventStore alloc] init];
    
    self.title = NSLocalizedString(@"Event Detail", @"heading for event detail page");

    self.titleLabel.text = self.eventTitle;
    
    NSString* courseName = self.courseName? self.courseName : @"";
    NSString* courseSectionNumber = self.courseSectionNumber? self.courseSectionNumber : @"";

    //format and separate if both are present
    if ( self.courseName && self.courseSectionNumber ) {
        self.courseNameLabel.text = [NSString stringWithFormat:@"%@-%@", courseName, courseSectionNumber];
    } else //otherwise display blanks and/or any fields present
    {
        self.courseNameLabel.text = [NSString stringWithFormat:@"%@%@", courseName, courseSectionNumber];
    }
    
    NSDateFormatter *datetimeFormatter = [[NSDateFormatter alloc] init];
    [datetimeFormatter setDateStyle:NSDateFormatterMediumStyle];
    [datetimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    if(self.allDay) {
        self.startDateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@, All Day", @"label for all day event"), [dateFormatter stringFromDate:self.startDate]];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        // now build a NSDate object for the next day
        NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
        [offsetComponents setDay:-1];
        NSDate *nextDate = [calendar dateByAddingComponents:offsetComponents toDate:self.endDate options:0];
        
        self.endDateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@, All Day", @"label for all day event"), [dateFormatter stringFromDate:nextDate]];
    } else {
        self.startDateLabel.text = [datetimeFormatter stringFromDate:self.startDate];
        self.endDateLabel.text = [datetimeFormatter stringFromDate:self.endDate];
    }
    
    self.locationLabel.text = self.location;
    self.descriptionTextView.text = self.eventDescription;
    
    self.backgroundView.backgroundColor = [UIColor accent];
    self.titleLabel.textColor = [UIColor subheaderText];
    self.courseNameLabel.textColor = [UIColor subheaderText];
    [self sendEventToTracker1WithCategory:Analytics.UI_Action action:Analytics.Search label:@"ILP Assignments Detail" moduleName:self.module.name];
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self.navigationController setToolbarHidden:YES animated:NO];
    } else {
        [self.padToolBar setHidden:YES];
    }
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self sendView:@"Course events detail" moduleName:self.module.name];
}

- (IBAction) addToMyCalendar:(id)sender {
    if (self.eventTitle != nil) {
        [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
         {
             [self performSelectorOnMainThread:@selector(addEventToCalendar) withObject:nil waitUntilDone:YES];
         }];
    }
}

-(void) addEventToCalendar
{
    EKEvent * event = [EKEvent eventWithEventStore:self.eventStore];
    event.title     = self.eventTitle;
    event.location  = self.location;
    event.startDate = self.startDate;
    event.endDate   = self.endDate;
    event.notes     = self.eventDescription;
    event.allDay    = self.allDay;
    
    EKEventEditViewController *controller = [[EKEventEditViewController alloc] init];
    
    controller.eventStore       = self.eventStore;
    controller.event            = event;
    controller.editViewDelegate = self;
    
    [self presentViewController:controller animated:YES completion:nil];
    
}

-(void)eventEditViewController:(EKEventEditViewController *)controller
         didCompleteWithAction:(EKEventEditViewAction)action {
    
    switch (action) {
        case EKEventEditViewActionCanceled:
            // User tapped "cancel"
            break;
        case EKEventEditViewActionSaved:
            // User tapped "save"
            break;
        case EKEventEditViewActionDeleted:
            // User tapped "delete"
            break;
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSDateFormatter *)dateFormatterShare
{
    if(_dateFormatterShare == nil) {
        _dateFormatterShare = [[NSDateFormatter alloc] init];
        [_dateFormatterShare setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatterShare setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatterShare setDoesRelativeDateFormatting:NO];
    }
    return _dateFormatterShare;
}

-(IBAction)share:(id)sender {
    if (self.eventTitle != nil) {
        NSString* eventDate = [self.dateFormatterShare stringFromDate:self.startDate];

        NSString *text = @"";
        if (eventDate && self.location) {
            text = [NSString stringWithFormat:@"%@\n%@\n%@\n%@", self.titleLabel.text, eventDate, self.location, self.eventDescription];
        } else if (eventDate) {
            text = [NSString stringWithFormat:@"%@\n%@\n%@", self.titleLabel.text, eventDate, self.eventDescription];
        } else if (self.location) {
            text = [NSString stringWithFormat:@"%@\n%@\n%@", self.titleLabel.text, self.location, self.eventDescription];
        } else {
            text = [NSString stringWithFormat:@"%@\n%@", self.titleLabel.text, self.eventDescription];
        }

        NSArray *activityItems = [NSArray arrayWithObjects:text, nil];
        
        UIActivityViewController *avc = [[UIActivityViewController alloc]
                                         initWithActivityItems: activityItems applicationActivities:nil];
        [avc setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            if (completed) {
                NSString *label = [NSString stringWithFormat:@"Tap Share Icon - %@", activityType];
                [self sendEventToTracker1WithCategory:Analytics.UI_Action action:Analytics.Invoke_Native label:label moduleName:self.module.name];
            }
        }];
        
        UIBarButtonItem *buttonItem = (UIBarButtonItem *) sender;
        avc.popoverPresentationController.barButtonItem = buttonItem;
        [self presentViewController:avc animated:YES completion:nil];
    }
}


-(void)selectedDetail:(id)newCourseEvent withIndex:(NSIndexPath*)myIndex withModule:(Module*)myModule withController:(id)myController
{
    if ( [newCourseEvent isKindOfClass:[CourseEvent class]] )
    {
        [self setCourseEvent:(CourseEvent *)newCourseEvent];
        [self setModule:myModule];
    }
}

-(void)setCourseEvent:(CourseEvent *)courseEvent
{
    if (_courseEvent != courseEvent) {
        _courseEvent = courseEvent;
        
        [self refreshUI];
    }
}

-(void)refreshUI
{
    _titleLabel.text = _courseEvent.title;
    _courseNameLabel.text = [NSString stringWithFormat:@"%@-%@", _courseEvent.courseName, _courseEvent.courseSectionNumber];
    _descriptionTextView.text = _courseEvent.eventDescription;
    _locationLabel.text = _courseEvent.location;
    
    if ( _courseEvent.isAllDay > 0 ) {
        _allDay = true;
    } else {
        _allDay = false;
    }
    _startDate = _courseEvent.startDate;
    _endDate = _courseEvent.endDate;
    
    NSDateFormatter *datetimeFormatter = [[NSDateFormatter alloc] init];
    [datetimeFormatter setDateStyle:NSDateFormatterMediumStyle];
    [datetimeFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];

    if(_allDay) {
        self.startDateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@, All Day", @"label for all day event"), [dateFormatter stringFromDate:_startDate]];
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        // now build a NSDate object for the next day
        NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
        [offsetComponents setDay:-1];
        NSDate *nextDate = [calendar dateByAddingComponents:offsetComponents toDate:self.endDate options:0];

        self.endDateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@, All Day", @"label for all day event"), [dateFormatter stringFromDate:nextDate]];
    } else {
        if(_startDate) {
            _startDateLabel.text = [datetimeFormatter stringFromDate:self.startDate];
        }
        if(_endDate){
            _endDateLabel.text = self.endDateLabel.text = [datetimeFormatter stringFromDate:self.endDate];
        }
    }
    [self.view setNeedsDisplay];
}


@end
