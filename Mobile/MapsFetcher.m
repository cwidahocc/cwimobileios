//
//  MapsFetcher.m
//  Mobile
//
//  Created by Jason Hocker on 5/15/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import "MapsFetcher.h"
#import "Ellucian_GO-Swift.h"

@implementation MapsFetcher

+(void) fetch:(NSManagedObjectContext *)context WithURL:(NSString *)urlString moduleKey:(NSString *)moduleKey {
    
    NSManagedObjectContext *importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    importContext.parentContext = context;
    
    NSError *error;

    NSData *responseData = [NSData dataWithContentsOfURL: [NSURL URLWithString: urlString]];
    

    if(responseData)
    {
        
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:responseData
                              options:kNilOptions
                              error:&error];
        
        Map *map = nil;
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Map"];
        request.predicate = [NSPredicate predicateWithFormat:@"moduleName = %@", moduleKey];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"moduleName" ascending:YES];
        request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if ([matches count] == 1) {
            map = [matches lastObject];
            [context deleteObject:map];
        }
        map = [NSEntityDescription insertNewObjectForEntityForName:@"Map" inManagedObjectContext:context];
        map.moduleName = moduleKey;
        
        //fetch types
        NSFetchRequest *typeRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *typeEntity = [NSEntityDescription entityForName:@"MapPOIType" inManagedObjectContext:context];
        [typeRequest setEntity:typeEntity];
        NSPredicate *typePredicate =[NSPredicate predicateWithFormat:@"moduleInternalKey = %@",moduleKey];
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
                managedPOI.moduleInternalKey = moduleKey;
                
                [managedCampus addPointsObject:managedPOI];
                if([building objectForKey:@"type"] != [NSNull null]) {
                    //managedPOI.type = [building objectForKey:@"type"];
                    
                    for (NSString *type in [building objectForKey:@"type"]) {
                        if(type != (NSString *)[NSNull null]) {
                            MapPOIType* typeObject = [typeMap objectForKey:type];
                            if(!typeObject) {
                                typeObject = [NSEntityDescription insertNewObjectForEntityForName:@"MapPOIType" inManagedObjectContext:context];
                                typeObject.name = type;
                                typeObject.moduleInternalKey = moduleKey;
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
        if(![context save:&error]) {
            NSLog(@"Could not save to store after update to maps: %@", [error userInfo]);
        }
    }
}
@end
