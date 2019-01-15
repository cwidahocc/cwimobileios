//
//  ImportantNumbersDirectoryEntry.h
//  Mobile
//
//  Created by jkh on 3/5/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ImportantNumbersDirectoryEntry : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * moduleName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * phoneExtension;
@property (nonatomic, retain) NSString * buildingId;
@property (nonatomic, retain) NSString * campusId;

@end
