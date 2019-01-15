//
//  ILPAssignmentsFetchOperation.swift
//  Mobile
//
//  Created by Bret Hansen on 9/11/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class ILPAssignmentsFetchOperation: Operation {
    private let internalKey: String
    private let url: String
    
    var assignments: [[String: Any]] = []
    
    init(internalKey: String, url: String) {
        self.internalKey = internalKey
        self.url = url
    }
    
    override func main() {

        // ensure user is logged in
        if CurrentUser.sharedInstance.isLoggedIn {
            // load assignments from server
            AssignmentsFetcher.fetch(CoreDataManager.sharedInstance.managedObjectContext, url: self.url)
            
            let request = NSFetchRequest<CourseAssignment>(entityName: "CourseAssignment")
            request.sortDescriptors = [NSSortDescriptor(key: "dueDate", ascending: true)]
            
            do {
                let assignmentModels = try CoreDataManager.sharedInstance.managedObjectContext.fetch(request)
                for assignment in assignmentModels {
                    var assignmentDictionary: [String: Any] = [:]
                    if (assignment.sectionId != nil) {
                        assignmentDictionary["sectionId"] = assignment.sectionId
                    }
                    if (assignment.assignmentDescription != nil) {
                        assignmentDictionary["assignmentDescription"] = assignment.assignmentDescription
                    }
                    if (assignment.dueDate != nil) {
                        assignmentDictionary["dueDate"] = assignment.dueDate
                    }
                    if (assignment.name != nil) {
                        assignmentDictionary["name"] = assignment.name
                    }
                    if (assignment.courseName != nil) {
                        assignmentDictionary["courseName"] = assignment.courseName
                    }
                    if (assignment.courseSectionNumber != nil) {
                        assignmentDictionary["courseSectionNumber"] = assignment.courseSectionNumber
                    }
                    if (assignment.url != nil) {
                        assignmentDictionary["url"] = assignment.url
                    }
                    
                    assignments.append(assignmentDictionary)
                }
            } catch {
                print("Unable to query Assignments")
            }
        }
    }
}
