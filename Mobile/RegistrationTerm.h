//
//  RegistrationTerm.h
//  Mobile
//
//  Created by jkh on 11/19/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegistrationTerm : NSObject

@property (nonatomic, strong) NSString *termId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *startDate;
@property (nonatomic, strong) NSString *endDate;
@property (nonatomic, assign) BOOL eligible;
@property (nonatomic, assign) BOOL requiresAltPin;
@property (nonatomic, strong) NSString *userEnteredPIN;

@end
