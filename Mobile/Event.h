//
//  Event.h
//  Mobile
//
//  Created by Jason Hocker on 12/13/12.
//  Copyright (c) 2012 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EventCategory, EventModule;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSString * contact;
@property (nonatomic, retain) NSString * dateLabel;
@property (nonatomic, retain) NSString * description_;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSString * summary;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSNumber * allDay;
@property (nonatomic, retain) NSSet *category;
@property (nonatomic, retain) EventModule *module;
@end

@interface Event (CoreDataGeneratedAccessors)

- (void)addCategoryObject:(EventCategory *)value;
- (void)removeCategoryObject:(EventCategory *)value;
- (void)addCategory:(NSSet *)values;
- (void)removeCategory:(NSSet *)values;

@end
