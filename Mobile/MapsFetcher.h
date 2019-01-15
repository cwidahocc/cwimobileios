//
//  MapsFetcher.h
//  Mobile
//
//  Created by Jason Hocker on 5/15/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface MapsFetcher : NSObject

+(void) fetch:(NSManagedObjectContext *)context WithURL:(NSString *)urlString moduleKey:(NSString *)moduleKey;

@end
