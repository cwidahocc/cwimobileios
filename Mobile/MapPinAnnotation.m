//
//  MapPinAnnotation.m
//  Mobile
//
//  Created by Jason Hocker on 9/7/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import "MapPinAnnotation.h"

@implementation MapPinAnnotation

- (id)initWithMapPOI:(MapPOI *)thePoi {
    
    self = [super init];
    if (self) {
        _poi = thePoi;
    }
    return self;
}

-(CLLocationCoordinate2D) coordinate
{
    CLLocationCoordinate2D location;
    location.latitude = [self.poi.latitude doubleValue];
    location.longitude = [self.poi.longitude doubleValue];
    return location;
}

-(NSString *) title
{
    return self.poi.name;
}

-(NSString *) subtitle
{
    NSMutableArray *categoryValues = [[NSMutableArray alloc] init];
    for(MapPOIType* value in self.poi.types) {
        [categoryValues addObject:value.name];
    }
    return [NSString stringWithFormat:@"%@", [categoryValues componentsJoinedByString:@", "]];
}


@end
