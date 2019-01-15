//
//  CourseDetailViewControllerProtocol.swift
//  Mobile
//
//  Created by Jason Hocker on 7/20/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

@objc protocol CourseDetailViewControllerProtocol {
    
    var module : Module? { get set }
    var termId : String? { get set }
    var sectionId : String? { get set }
    var courseName : String? { get set }
    var courseSectionNumber : String? { get set }
    
    
}
