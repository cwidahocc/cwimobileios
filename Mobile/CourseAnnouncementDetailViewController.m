//
//  CourseAnnouncementDetailViewController.m
//  Mobile
//
//  Created by Jason Hocker on 6/6/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import "CourseAnnouncementDetailViewController.h"
#import "Ellucian_GO-Swift.h"

@interface CourseAnnouncementDetailViewController ()
@property (nonatomic, strong) AllAnnouncementsViewController *masterController;
@end

@implementation CourseAnnouncementDetailViewController

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
    
    self.navigationController.navigationBar.translucent = NO;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
    
    UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(takeAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        self.toolbarItems = [ NSArray arrayWithObjects: flexibleSpace, shareButtonItem, nil ];
        self.navigationController.toolbar.translucent = NO;
        //for ilp module on ipad create add items to toolbar created in storyboard
    } else {
        [self.padToolBar setItems:[ NSArray arrayWithObjects: flexibleSpace, shareButtonItem, nil ] animated:NO];
        self.padToolBar.translucent = NO;
        UIImage *registerButtonImage = [UIImage imageNamed:@"Registration Button"];
        [self.padToolBar setBackgroundImage:registerButtonImage forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
        self.padToolBar.tintColor = [UIColor whiteColor];
    }
    
    self.titleLabel.text = self.itemTitle;
    if ( self.courseName != nil && self.courseSectionNumber != nil) {
        self.courseNameLabel.text = [NSString stringWithFormat:@"%@-%@", self.courseName, self.courseSectionNumber];
    } else {
        self.courseNameLabel.text = @"";
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    self.dateLabel.text = [dateFormatter stringFromDate:self.itemPostDateTime];
    self.descriptionTextView.text = self.itemContent;
    
    self.backgroundView.backgroundColor = [UIColor accent];
    self.titleLabel.textColor = [UIColor subheaderText];
    self.courseNameLabel.textColor = [UIColor subheaderText];
    self.dateLabel.textColor = [UIColor subheaderText];
    [self sendEventToTracker1WithCategory:Analytics.UI_Action action:Analytics.Search label:@"ILP Announcements Detail" moduleName:self.module.name];
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

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self sendView:@"Course activity detail" moduleName:self.module.name];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"Show Website"]) {
        WKWebViewController *detailController = (WKWebViewController *)[segue destinationViewController];
        detailController.loadRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.itemLink]];
        detailController.title = self.itemTitle;
        detailController.analyticsLabel = self.module.name;
    }
}

- (IBAction) takeAction:(id)sender {
    if (self.itemTitle != nil) {
        [self sendEventToTracker1WithCategory:Analytics.UI_Action action:Analytics.Follow_web label:@"Open activity in web frame" moduleName:self.module.name];
        [self performSegueWithIdentifier:@"Show Website" sender:sender];
    }
}

-(void)setCourseAnnouncement:(CourseAnnouncement *)courseAnnouncement
{
    if (_courseAnnouncement != courseAnnouncement) {
        _courseAnnouncement = courseAnnouncement;
        
        [self refreshUI];
    }
}

-(void)refreshUI
{
    _titleLabel.text = _courseAnnouncement.title;
    _courseNameLabel.text = [NSString stringWithFormat:@"%@-%@", _courseAnnouncement.courseName, _courseAnnouncement.courseSectionNumber];
    _descriptionTextView.text = _courseAnnouncement.content;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    _itemPostDateTime = _courseAnnouncement.date;
    if(_itemPostDateTime) {
        _dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Due: %@", @"due date label with date"), [dateFormatter stringFromDate:_itemPostDateTime]];
    } else {
        _dateLabel.text = NSLocalizedString(@"None announcement date available", "no date for announcement");
    }
    
    [self.view setNeedsDisplay];
    
}


-(void)selectedDetail:(id)newCourseAnnouncement withIndex:(NSIndexPath*)myIndex withModule:(Module*)myModule withController:(id)myController
{
    if ( [newCourseAnnouncement isKindOfClass:[CourseAnnouncement class]] )
    {
        [self setCourseAnnouncement:(CourseAnnouncement *)newCourseAnnouncement];
        [self setModule:myModule];
    }
}

@end
