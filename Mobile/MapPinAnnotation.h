//
//  MapPinAnnotation.h
//  Mobile
//
//  Created by Jason Hocker on 9/7/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Ellucian_GO-Swift.h"

@interface MapPinAnnotation : NSObject<MKAnnotation> {

}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *subtitle;
@property (nonatomic, strong) MapPOI *poi;
@property (nonatomic) int nTag;

- (id)initWithMapPOI:(MapPOI *)poi;

@end
