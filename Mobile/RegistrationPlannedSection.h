//
//  RegistrationPlannedSection.h
//  Mobile
//
//  Created by jkh on 11/18/13.
//  Copyright (c) 2013 - 2014 Ellucian. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kPassNoPass @"PassFail"
#define kAudit @"Audit"
#define kGraded @"Graded"


@interface RegistrationPlannedSection : NSObject

@property (nonatomic, strong) NSString *sectionId;
@property (nonatomic, strong) NSString *courseId;
@property (nonatomic, strong) NSString *courseName;
@property (nonatomic, strong) NSString *courseSectionNumber;
@property (nonatomic, strong) NSString *sectionTitle;
@property (nonatomic, strong) NSString *courseDescription;
@property (nonatomic, strong) NSNumber *credits;
@property (nonatomic, strong) NSNumber *ceus;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *gradingType;
@property (nonatomic, strong) NSDate * firstMeetingDate;
@property (nonatomic, strong) NSDate * lastMeetingDate;
@property (nonatomic, strong) NSArray *meetingPatterns;
@property (nonatomic, strong) NSArray *instructors;
@property (nonatomic, strong) NSString *termId;
@property (nonatomic, strong) NSString *classification;
@property (nonatomic, strong) NSNumber *minimumCredits;
@property (nonatomic, strong) NSNumber *maximumCredits;
@property (nonatomic, strong) NSNumber *variableCreditIncrement;
@property (nonatomic, strong) NSString *variableCreditOperator;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSArray *academicLevels;
@property (nonatomic, strong) NSNumber *capacity;
@property (nonatomic, strong) NSNumber *available;

@property (nonatomic, assign) BOOL selectedInCart;
@property (nonatomic, assign) BOOL selectedInSearchResults;
@property (nonatomic, assign) BOOL selectedForDrop;
@property (nonatomic, readonly) BOOL isVariableCredit;

@property (nonatomic, assign) BOOL isPassFail;
@property (nonatomic, assign) BOOL isGraded;
@property (nonatomic, assign) BOOL isAudit;

@property (nonatomic, assign) BOOL authorizationCodeRequired;
@property (nonatomic, strong) NSString *authorizationCode;

-(NSString *)facultyNames;
-(NSString *)meetingPatternDescription;
-(NSString *)instructionalMethod;

@end
