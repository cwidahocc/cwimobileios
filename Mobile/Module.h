//
//  Module.h
//  Mobile
//
//  Created by Jason Hocker on 6/5/14.
//  Copyright (c) 2014 Ellucian Company L.P. and its affiliates. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ModuleProperty, ModuleRole;

@interface Module : NSManagedObject

@property (nonatomic, retain) NSString * iconUrl;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * internalKey;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * hideBeforeLogin;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *properties;
@property (nonatomic, retain) NSSet *roles;
@property (nonatomic, retain) NSNumber * homeScreenOrder;
@property (nonatomic) BOOL displayInMenu;
@end

@interface Module (CoreDataGeneratedAccessors)

- (void)addPropertiesObject:(ModuleProperty *)value;
- (void)removePropertiesObject:(ModuleProperty *)value;
- (void)addProperties:(NSSet *)values;
- (void)removeProperties:(NSSet *)values;

- (void)addRolesObject:(ModuleRole *)value;
- (void)removeRolesObject:(ModuleRole *)value;
- (void)addRoles:(NSSet *)values;
- (void)removeRoles:(NSSet *)values;

@end
