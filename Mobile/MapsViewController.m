//
//  MapsViewController.m
//  Mobile
//
//  Created by Jason Hocker on 9/6/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import "MapsViewController.h"
#import "MapPinAnnotation.h"
#import "POIListViewController.h"
#import "POIDetailViewController.h"
#import "Ellucian_GO-Swift.h"
#import "MBProgressHUD.h"

@interface MapsViewController ()

@property (strong, nonatomic) NSArray *campuses;
@property (strong, nonatomic) MapCampus *selectedCampus;
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation MapsViewController

@synthesize module_;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self startTrackingLocation];
    
    if(!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    self.mapView.delegate = self;
    
    self.title = self.module.name;
    self.navigationController.navigationBar.translucent = NO;
    self.toolbar.translucent = NO;
    
    self.searchBar.delegate = self;
    self.definesPresentationContext = YES;
    
    self.buildingsButton.accessibilityLabel = @"Points of interest";

    [self fetchCachedMaps];
    [self fetchMapsInBackground];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self sendView:@"Map of campus" moduleName:self.module.name];
    //TODO use the notification names instead of strings after converting this to swift
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuOpened:) name:@"SlidingViewOpenMenuAppearsNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuClosed:) name:@"SlidingViewTopResetNotification"  object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self startTrackingLocation];
    
    // Send notification to ensure that POI searchController will not persist
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MapsViewWillAppear" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.mapView.showsUserLocation = NO;
    [self.locationManager stopUpdatingLocation];
}


- (IBAction)campusSelector:(id)sender {

    [self sendEventWithCategory:Analytics.UI_Action action:Analytics.Button_Press label:@"Tap campus selector" moduleName:self.module.name];
    
    if([self.campuses count] > 0) {
        
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select Campus", @"title of action sheet for user to select which campus to see on the map")
                                                                             message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", comment: @"Cancel") style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAction];
       
        for(MapCampus *campus in self.campuses) {
            UIAlertAction *campusAction = [UIAlertAction actionWithTitle:campus.name style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self sendEventToTracker1WithCategory:Analytics.UI_Action action:Analytics.Invoke_Native label:@"Select campus" moduleName:self.module.name];
                NSUserDefaults *userDefaults = [AppGroupUtilities userDefaults];
                NSString *key = [NSString stringWithFormat:@"%@-%@", @"mapLastCampus", self.module.internalKey ];
                [userDefaults setObject:campus.campusId forKey:key];
                [self showCampus:campus];
            }];
            [alertController addAction:campusAction];
        }
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            alertController.popoverPresentationController.barButtonItem = self.campusSelectionButton;
        } else {
            alertController.popoverPresentationController.sourceView = self.navigationController.toolbar;
            alertController.popoverPresentationController.sourceRect = self.navigationController.toolbar.bounds;
        }
        

        [self presentViewController:alertController animated:YES completion:nil];

        
    }
}

-(void) showCampus:(MapCampus *)campus
{
    self.selectedCampus = campus;
    self.title = campus.name;
    //copy your annotations to an array
    NSMutableArray *annotationsToRemove = [[NSMutableArray alloc] initWithArray: self.mapView.annotations];
    //Remove the object userlocation
    [annotationsToRemove removeObject: self.mapView.userLocation];
    //Remove all annotations in the array from the mapView
    [self.mapView removeAnnotations: annotationsToRemove];
    
    CLLocationCoordinate2D locationCenter;
    locationCenter.latitude = [campus.centerLatitude doubleValue];
    locationCenter.longitude = [campus.centerLongitude doubleValue];
    
    MKCoordinateSpan locationSpan;
    locationSpan.latitudeDelta = [campus.spanLatitude doubleValue];
    locationSpan.longitudeDelta = [campus.spanLongitude doubleValue];
        
    MKCoordinateRegion region = MKCoordinateRegionMake(locationCenter, locationSpan);
    if(locationSpan.latitudeDelta < 180 && locationSpan.longitudeDelta < 360 && locationCenter.latitude <= 90 && locationCenter.latitude >= -90 && locationCenter.longitude <= 180 && locationCenter.longitude >= -180) {
        [self.mapView setRegion:region animated:YES];
    }
    
    NSArray *filtered = campus.points.allObjects;
    NSString *searchText = self.searchBar.text;
    if (searchText.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"moduleInternalKey = %@ AND (name CONTAINS[cd] %@ OR ANY types.name CONTAINS[cd] %@ OR campus.name CONTAINS[cd] %@)", self.module.internalKey, searchText, searchText, searchText];
        filtered = [campus.points.allObjects filteredArrayUsingPredicate:predicate];
    }
    
    for(MapPOI *poi in filtered) {

        MapPinAnnotation *annotation = [[MapPinAnnotation alloc] initWithMapPOI:poi];
        [self.mapView addAnnotation:annotation];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
	// If it's the user location, just return nil.
	if ([annotation isKindOfClass:[MKUserLocation class]])
		return nil;
	// If it is our MapPinAnnotation, we create and return its view
	if ([annotation isKindOfClass:[MapPinAnnotation class]]) {
		// try to dequeue an existing pin view first
		static NSString* pinAnnotationIdentifier = @"PinAnnotationIdentifier";
		MKPinAnnotationView* pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:pinAnnotationIdentifier ];
		if (!pinView) {
			// If an existing pin view was not available, create one
			MKPinAnnotationView* customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pinAnnotationIdentifier];
			customPinView.animatesDrop = YES;
			customPinView.canShowCallout = YES;
            
			// add a detail disclosure button to the callout which will open a new view controller page
			UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			customPinView.rightCalloutAccessoryView = rightButton;
            
			return customPinView;
		} else {
			pinView.annotation = annotation;
		}
		return pinView;
	}
    return nil;
}

- (void)mapView:(MKMapView *)_mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if ([view.annotation isKindOfClass:[MapPinAnnotation class]]) {
        [self sendEventToTracker1WithCategory:Analytics.UI_Action action:Analytics.Button_Press label:@"Select Map Pin" moduleName:self.module.name];
        MapPinAnnotation *annotation = view.annotation;
        [self performSegueWithIdentifier:@"Show POI" sender:annotation.poi];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"Show POI List"])
    {
        [self sendEventWithCategory:Analytics.UI_Action action:Analytics.Button_Press label:@"Tap building icon" moduleName:self.module.name];
        POIListViewController *vc = (POIListViewController *) [segue destinationViewController];
        vc.module = self.module;
    }  else if ([[segue identifier] isEqualToString:@"Show POI"])
    {
        MapPOI *poi = sender;
        POIDetailViewController *vc = (POIDetailViewController *)[segue destinationViewController];
        vc.imageUrl = poi.imageUrl;
        vc.name = poi.name;
        NSMutableArray *types = [[NSMutableArray alloc] init];
        for(MapPOIType *type in poi.types) {
            [types addObject:type.name];
        }
        vc.types = [types copy];
        vc.location = [[CLLocation alloc] initWithLatitude:[poi.latitude doubleValue] longitude:[poi.longitude doubleValue]];
        vc.address = poi.address;
        vc.poiDescription = poi.description_;
        vc.additionalServices = poi.additionalServices;
        vc.buildingId = poi.buildingId;
        vc.campusName = poi.campus.name;
        vc.module = self.module;
    }
}

- (IBAction)showMyLocation:(id)sender {
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self showLocationOnMap];
    } else if (status == kCLAuthorizationStatusDenied) {
        UIAlertController * alert=   [UIAlertController
                                      alertControllerWithTitle:NSLocalizedString(@"Location Access Disabled", @"Location Access Disabled")
                                      message:NSLocalizedString(@"Location services are used at your institution to alert you when you are near location specific information or services. Please allow location access \"Always\" in your device settings.", @"Description shown to user if location access disabled.  The text in quotes is the label used by iOS. Arabic=دائما Spanish=Siempre French=Tourjous Portuguese=Sempre")
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* settingsAction = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Settings", "Settings application name. This is part of iOS.  Apple translates this to be Arabic = الإعدادات Spanish/Portuguese=Ajustes French=Réglages")
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                                 
                             }];
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                 style:UIAlertActionStyleCancel
                                 handler:nil];
        
        [alert addAction:settingsAction];
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void) showLocationOnMap {

    [self sendEventWithCategory:Analytics.UI_Action action:Analytics.Invoke_Native label:@"Geolocate user" moduleName:self.module.name];
    
    MKUserLocation *userLocation = self.mapView.userLocation;
    
    float maxNorth = MAX([self.selectedCampus.centerLatitude floatValue] + [self.selectedCampus.spanLatitude floatValue], userLocation.location.coordinate.latitude);
    float maxSouth = MIN([self.selectedCampus.centerLatitude floatValue] - [self.selectedCampus.spanLatitude floatValue], userLocation.location.coordinate.latitude);
    float maxEast = MAX([self.selectedCampus.centerLongitude floatValue] + [self.selectedCampus.spanLongitude floatValue], userLocation.location.coordinate.longitude);
    float maxWest = MIN([self.selectedCampus.centerLongitude floatValue] - [self.selectedCampus.spanLongitude floatValue], userLocation.location.coordinate.longitude);
    
    float centerLatitude = (maxNorth + maxSouth) / 2.0f;
    float centerLongitude = (maxEast + maxWest) / 2.0f;
    float spanLatitude = ABS(maxNorth - maxSouth);
    float spanLongitude = ABS(maxEast - maxWest);
    
    CLLocationCoordinate2D locationCenter;
    locationCenter.latitude = centerLatitude;
    locationCenter.longitude = centerLongitude;
    
    MKCoordinateSpan locationSpan;
    locationSpan.latitudeDelta = spanLatitude;
    locationSpan.longitudeDelta = spanLongitude;
    
    MKCoordinateRegion region = MKCoordinateRegionMake(locationCenter, locationSpan);
    [self.mapView setRegion:region animated:YES];
}

- (IBAction)mapTypeChanged:(id)sender {
    [self sendEventWithCategory:Analytics.UI_Action action:Analytics.Invoke_Native label:@"Change map view" moduleName:self.module.name];
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	switch([segmentedControl selectedSegmentIndex]) {
        case 0: {
            self.mapView.mapType = MKMapTypeStandard;
            break;
        }
        case 1: {
            self.mapView.mapType = MKMapTypeSatellite;
            break;
        }
        case 2: {
            self.mapView.mapType = MKMapTypeHybrid;
            break;
        }
    }
}

- (void) fetchMapsInBackground {
    UIView *hudView = self.view;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:hudView animated:YES];
    NSString *loadingString = NSLocalizedString(@"Loading", @"loading message while waiting for data to load");
    hud.label.text = loadingString;
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString);
    
    NSManagedObjectContext *importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    importContext.parentContext = self.module.managedObjectContext;
    NSString *urlString = [self.module propertyForKey:@"campuses"];
    [importContext performBlock: ^{
        NSError *error;
        [self downloadMaps:importContext WithURL:urlString];
        //save to main context
        if (![importContext save:&error]) {
            NSLog(@"Could not save to main context after update to map: %@", [error userInfo]);
        }
        
        [importContext.parentContext performBlock:^{

            NSError *parentError = nil;
            if(![importContext.parentContext save:&parentError]) {
                NSLog(@"Could not save to store after update to maps: %@", [parentError userInfo]);
            }
            [self fetchCachedMaps];
                
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [MBProgressHUD hideHUDForView:hudView animated:YES];
            });
        }];
    }];
}

- (void) downloadMaps:(NSManagedObjectContext *)context WithURL:(NSString *)urlString
{
    NSError *error;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    });

    NSData *responseData = [NSData dataWithContentsOfURL: [NSURL URLWithString: urlString]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    });
    
    if(responseData)
    {
        
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:kNilOptions
                              error:&error];
        
        Map *map = nil;
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Map"];
        request.predicate = [NSPredicate predicateWithFormat:@"moduleName = %@", self.module.internalKey];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"moduleName" ascending:YES];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if ([matches count] == 1) {
            map = [matches lastObject];
            [context deleteObject:map];
        }
        map = [NSEntityDescription insertNewObjectForEntityForName:@"Map" inManagedObjectContext:context];
        map.moduleName = self.module.internalKey;
        
        //fetch types
        NSFetchRequest *typeRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *typeEntity = [NSEntityDescription entityForName:@"MapPOIType" inManagedObjectContext:context];
        [typeRequest setEntity:typeEntity];
        NSPredicate *typePredicate =[NSPredicate predicateWithFormat:@"moduleInternalKey = %@",self.module.internalKey];
        [typeRequest setPredicate:typePredicate];
        
        NSArray *typeArray = [context executeFetchRequest:typeRequest error:&error];
        NSMutableDictionary *typeMap = [[NSMutableDictionary alloc] init];
        for(MapPOIType *poiType in typeArray) {
            [typeMap setObject:poiType forKey:poiType.name];
        }
        
        for(NSDictionary *campus in [json objectForKey:@"campuses"]) {
            MapCampus *managedCampus = [NSEntityDescription insertNewObjectForEntityForName:@"MapCampus" inManagedObjectContext:context];
            managedCampus.name = [campus objectForKey:@"name"];
            managedCampus.campusId = [campus objectForKey:@"id"];
            
            float nwLatitude = [[campus valueForKey:@"northWestLatitude"] floatValue];
            float nwLongitude = [[campus valueForKey:@"northWestLongitude"] floatValue];
            float seLatitude = [[campus valueForKey:@"southEastLatitude"] floatValue];
            float seLongitude = [[campus valueForKey:@"southEastLongitude"] floatValue];
            
            managedCampus.centerLatitude = [NSNumber numberWithFloat:(nwLatitude + seLatitude) / 2.0f];
            managedCampus.centerLongitude = [NSNumber numberWithFloat:(nwLongitude + seLongitude) / 2.0f];
            managedCampus.spanLatitude = [NSNumber numberWithFloat:ABS(nwLatitude - seLatitude)];
            managedCampus.spanLongitude = [NSNumber numberWithFloat:ABS(nwLongitude - seLongitude)];
            [map addCampusesObject:managedCampus];
            managedCampus.map = map;
            

            for(NSDictionary *building in [campus objectForKey:@"buildings"]) {       
                MapPOI *managedPOI = [NSEntityDescription insertNewObjectForEntityForName:@"MapPOI" inManagedObjectContext:context];
                managedPOI.campus = managedCampus;
                managedPOI.moduleInternalKey = self.module.internalKey;

                [managedCampus addPointsObject:managedPOI];
                if([building objectForKey:@"type"] != [NSNull null]) {
                    //managedPOI.type = [building objectForKey:@"type"];
                
                    for (NSString *type in [building objectForKey:@"type"]) {
                        if(type != (NSString *)[NSNull null]) {
                            MapPOIType* typeObject = [typeMap objectForKey:type];
                            if(!typeObject) {
                                typeObject = [NSEntityDescription insertNewObjectForEntityForName:@"MapPOIType" inManagedObjectContext:context];
                                typeObject.name = type;
                                typeObject.moduleInternalKey = self.module.internalKey;
                                [typeMap setObject:typeObject forKey:typeObject.name];
                            }
                            [managedPOI addTypesObject:typeObject];
                            [typeObject addPointsOfInterestObject:managedPOI];
                        }
                    }
                }
                managedPOI.name = [building objectForKey:@"name"];
                if([building objectForKey:@"address"] != [NSNull null])
                    managedPOI.address = [[building objectForKey:@"address"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                if([building objectForKey:@"longDescription"] != [NSNull null])
                    managedPOI.description_ = [building objectForKey:@"longDescription"];
                if([building objectForKey:@"latitude"] != [NSNull null])
                    managedPOI.latitude = [NSNumber numberWithFloat:[[building objectForKey:@"latitude"] floatValue]];
                if([building objectForKey:@"longitude"] != [NSNull null])
                    managedPOI.longitude = [NSNumber numberWithFloat:[[building objectForKey:@"longitude"] floatValue]];
                if([building objectForKey:@"imageUrl"] != [NSNull null])
                    managedPOI.imageUrl = [building objectForKey:@"imageUrl"];
                if([building objectForKey:@"additionalServices"] != [NSNull null])
                    managedPOI.additionalServices = [[building objectForKey:@"additionalServices"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
                if([building objectForKey:@"buildingId"] != [NSNull null])
                    managedPOI.buildingId = [building objectForKey:@"buildingId"];
                
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Poor Network Connection",@"title when data cannot load due to a poor netwrok connection") message:NSLocalizedString(@"Data could not be retrieved.",@"message when data cannot load due to a poor netwrok connection") preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* alertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
            [alert addAction:alertAction];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }

}

- (void) fetchCachedMaps
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MapCampus" inManagedObjectContext:self.module.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"map.moduleName = %@", self.module.internalKey];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    self.campuses = [self.module.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if([self.campuses count] > 1) {
        self.campusSelectionButton.enabled = YES;
        self.buildingsButton.enabled = YES;
        
        NSUserDefaults *userDefaults = [AppGroupUtilities userDefaults];
        NSString *key = [NSString stringWithFormat:@"%@-%@", @"mapLastCampus", self.module.internalKey ];
        NSString *previousCampus = [userDefaults objectForKey:key];
        
        if(previousCampus) {
            for(MapCampus *campus in self.campuses) {
                if([campus.campusId isEqualToString:previousCampus]) {
                    [self showCampus:campus];
                }
            }
        } else if([CLLocationManager locationServicesEnabled]) {
            
            double distance = DBL_MAX;
            for(MapCampus *campus in self.campuses) {
            
                double lat1 = self.mapView.userLocation.coordinate.latitude*M_PI/180.0;
                double lon1 = self.mapView.userLocation.coordinate.longitude*M_PI/180.0;
                double lat2 = [campus.centerLatitude doubleValue]*M_PI/180.0;
                double lon2 = [campus.centerLongitude doubleValue]*M_PI/180.0;
            
                double calculatedDistance = acos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lon2 - lon1)) * 6368500.0;
            
                if(calculatedDistance < distance) {
                    self.selectedCampus = campus;
                    distance = calculatedDistance;
                }
            
            }
            [self showCampus:self.selectedCampus];
        } else {
            MapCampus *campus = [self.campuses firstObject];
            [self showCampus:campus];
        }
    } else if ([self.campuses count] == 1) {
        self.campusSelectionButton.enabled = YES;
        self.buildingsButton.enabled = YES;
        self.selectedCampus = [self.campuses lastObject];
        [self showCampus:self.selectedCampus];
    } else {
        self.campusSelectionButton.enabled = NO;
        self.buildingsButton.enabled = NO;
    }
    
}

- (NSFetchRequest *)searchFetchRequest
{
    if(_searchFetchRequest != nil) {
        return _searchFetchRequest;
    }
    _searchFetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MapPOI" inManagedObjectContext:self.module.managedObjectContext];
    [_searchFetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [_searchFetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    return _searchFetchRequest;
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.searchFetchRequest = nil;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.filteredList count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MapPOI Search"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MapPOI Search"];
    }
    
    MapPOI *poi = [self.filteredList objectAtIndex:indexPath.row];
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.campus.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MapPOI *poi = [self.filteredList objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"Show POI" sender:poi];

}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self sendEventToTracker1WithCategory:Analytics.UI_Action action:Analytics.Search label:@"Search" moduleName:nil];
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [[searchBar valueForKey:@"_cancelButton"] setEnabled:YES];
}

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText {
    [self showCampus:self.selectedCampus];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [self showCampus:self.selectedCampus];
}

-(void) menuOpened:(id)sender
{
    self.mapView.scrollEnabled = NO;
}

-(void) menuClosed:(id)sender
{
    self.mapView.scrollEnabled = YES;
}

- (void)startTrackingLocation
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        [self.locationManager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
    } else if (status == kCLAuthorizationStatusDenied) {
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startTrackingLocation];
            self.zoomWithCurrentLocationButton.enabled = YES;
            self.zoomWithCurrentLocationButton.accessibilityLabel = NSLocalizedString(@"Locate", @"VoiceOver label for button that locates the user on a map");
            self.zoomWithCurrentLocationButton.accessibilityHint = NSLocalizedString(@"Displays current location.", @"VoiceOver hint for button that locates the user on a map");
            self.mapView.showsUserLocation = YES;
            break;
        case kCLAuthorizationStatusNotDetermined:
            [self.locationManager requestWhenInUseAuthorization];
            break;
        default:
            break;
    }
}

@end
