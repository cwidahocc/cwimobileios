//
//  Grade.h
//  Mobile
//
//  Created by Jason Hocker on 9/24/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GradeCourse;

@interface Grade : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSDate * lastUpdated;
@property (nonatomic, retain) GradeCourse *course;

@end
