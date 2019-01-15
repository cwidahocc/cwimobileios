//
//  CourseRoster.h
//  Mobile
//
//  Created by jkh on 2/15/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CourseRoster : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * middleName;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * photo;
@property (nonatomic, retain) NSString * sectionId;
@property (nonatomic, retain) NSString * sectionKey;
@property (nonatomic, retain) NSString * studentId;
@property (nonatomic, retain) NSString * termId;

@end
