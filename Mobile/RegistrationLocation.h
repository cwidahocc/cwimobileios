//
//  RegistrationLocation.h
//  Mobile
//
//  Created by Jason Hocker on 10/9/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RegistrationLocation : NSManagedObject

@property (nonatomic, retain) NSString * moduleId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * code;
@property (nonatomic, assign) BOOL unselected;
@end
