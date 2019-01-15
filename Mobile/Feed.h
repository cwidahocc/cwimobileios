//
//  Feed.h
//  Mobile
//
//  Created by jkh on 3/21/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FeedCategory, FeedModule;

@interface Feed : NSManagedObject

@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * dateLabel;
@property (nonatomic, retain) NSString * entryId;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * logo;
@property (nonatomic, retain) NSData * logoData;
@property (nonatomic, retain) NSDate * postDateTime;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *category;
@property (nonatomic, retain) FeedModule *module;
@end

@interface Feed (CoreDataGeneratedAccessors)

- (void)addCategoryObject:(FeedCategory *)value;
- (void)removeCategoryObject:(FeedCategory *)value;
- (void)addCategory:(NSSet *)values;
- (void)removeCategory:(NSSet *)values;

@end
