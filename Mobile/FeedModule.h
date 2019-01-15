//
//  FeedModule.h
//  Mobile
//
//  Created by jkh on 3/21/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Feed;

@interface FeedModule : NSManagedObject

@property (nonatomic, retain) NSString * hiddenCategories;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *feeds;
@end

@interface FeedModule (CoreDataGeneratedAccessors)

- (void)addFeedsObject:(Feed *)value;
- (void)removeFeedsObject:(Feed *)value;
- (void)addFeeds:(NSSet *)values;
- (void)removeFeeds:(NSSet *)values;

@end
