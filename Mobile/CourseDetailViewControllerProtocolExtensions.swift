//
//  CourseDetailViewControllerProtocolExtensions.swift
//  Mobile
//
//  Created by Jason Hocker on 7/20/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

extension CourseDetailViewControllerProtocol {
    
    func courseNameAndSectionNumber() -> String {
        let courseName = self.courseName!
        let courseSectionNumber = self.courseSectionNumber!
        let courseNameAndSectionNumber = "\(courseName)-\(courseSectionNumber)"
        return courseNameAndSectionNumber
    }
    
}
