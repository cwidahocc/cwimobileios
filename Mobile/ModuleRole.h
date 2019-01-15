//
//  ModuleRole.h
//  Mobile
//
//  Created by jkh on 2/5/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Module;

@interface ModuleRole : NSManagedObject

@property (nonatomic, retain) NSString * role;
@property (nonatomic, retain) Module *module;

@end
