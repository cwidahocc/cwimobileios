//
//  FeedCategory.h
//  Mobile
//
//  Created by jkh on 3/21/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Feed;

@interface FeedCategory : NSManagedObject

@property (nonatomic, retain) NSString * moduleName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *feed;
@end

@interface FeedCategory (CoreDataGeneratedAccessors)

- (void)addFeedObject:(Feed *)value;
- (void)removeFeedObject:(Feed *)value;
- (void)addFeed:(NSSet *)values;
- (void)removeFeed:(NSSet *)values;

@end
