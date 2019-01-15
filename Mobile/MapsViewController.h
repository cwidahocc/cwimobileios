//
//  MapsViewController.h
//  Mobile
//
//  Created by Jason Hocker on 9/6/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Module.h"
#import "Ellucian_GO-Swift.h"


@interface MapsViewController : UIViewController<MKMapViewDelegate, UISearchBarDelegate, UITableViewDataSource, CLLocationManagerDelegate, EllucianMobileLaunchableControllerProtocol >
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) Module *module;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *campusSelectionButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buildingsButton;

@property (strong, nonatomic) NSArray *filteredList;
@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *zoomWithCurrentLocationButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

- (IBAction)campusSelector:(id)sender;
- (IBAction)showMyLocation:(id)sender;

- (IBAction)mapTypeChanged:(id)sender;

@end
