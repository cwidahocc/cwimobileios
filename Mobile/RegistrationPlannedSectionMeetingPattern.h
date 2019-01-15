//
//  RegistrationPlannedSectionMeetingPattern.h
//  Mobile
//
//  Created by jkh on 11/19/13.
//  Copyright (c) 2013 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegistrationPlannedSectionMeetingPattern : NSObject

@property (nonatomic, strong) NSString *instructionalMethodCode;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, strong) NSArray *daysOfWeek;
@property (nonatomic, strong) NSString *room;
@property (nonatomic, strong) NSString *building;
@property (nonatomic, strong) NSString *buildingId;
@property (nonatomic, strong) NSString *campusId;

@end
