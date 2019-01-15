//
//  ILPAssignmentsController.swift
//  Mobile
//
//  Created by Jason Hocker on 4/28/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WatchKit
import CoreData

class ILPAssignmentsController: WKInterfaceController {
    
    @IBOutlet var assignmentsTable: WKInterfaceTable!
    @IBOutlet var retrievingDataLabel: WKInterfaceLabel!
    @IBOutlet var signInLabel: WKInterfaceLabel!
    @IBOutlet var noAssignments: WKInterfaceLabel!
    @IBOutlet var spinner: WKInterfaceImage!
    
    var assignments : [Dictionary<String, AnyObject>]!
    var internalKey : String?
    var urlString : String?
    var cache: DefaultsCache?
    
    let datetimeOutputFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter
        
        }()
    
    override func awake(withContext context: Any?) {
        let dictionary = context! as! Dictionary<String, AnyObject>
        self.internalKey = dictionary["internalKey"] as? String
        self.setTitle(dictionary["title"] as? String)
        self.urlString = dictionary["ilp"] as? String
        
        cache = DefaultsCache(key: "ilp assignments \((self.internalKey)!)")
        
        var data: [String: String] = [:]
        
        if let urlString = self.urlString {
            data["url"] = urlString
        }
        if let internalKey = self.internalKey {
            data["internalKey"] = internalKey
        }
        
        if WatchConnectivityManager.sharedInstance.isUserLoggedIn() {
            if let assignments = cache?.fetch() as! [[String: AnyObject]]? {
                self.assignments = assignments
                self.populateTable()
                
                self.retrievingDataLabel.setHidden(true)
                self.spinner.stopAnimating()
                self.spinner.setHidden(true)
            } else {
                // show the spinner because we don't have data yet
                retrievingDataLabel.setHidden(false)
                self.spinner.startAnimating()
                self.spinner.setHidden(false)
            }
            
            WatchConnectivityManager.sharedInstance.sendActionMessage("fetch assignments", data: data, replyHandler: {
                    (data) -> Void in
                
                    self.retrievingDataLabel.setHidden(true)
                    self.spinner.stopAnimating()
                    self.spinner.setHidden(true)

                    self.assignments = data["assignments"] as! [[String:AnyObject]]
                    self.cache?.store(self.assignments)
                    DispatchQueue.main.async(execute: {
                        self.populateTable()
                    })
                }, errorHandler: {
                    (error) -> Void in
                    
                    DispatchQueue.main.async(execute: {
                        // show error message
                        self.retrievingDataLabel.setHidden(true)
                        self.spinner.stopAnimating()
                        self.spinner.setHidden(true)
                    })
            })
        } else {
            self.assignments = [[String: AnyObject]]()
            self.populateTable()
        }
    }
    
    func createTodayDateRange() -> [Date] {
        var cal = Calendar.current
        let timezone = TimeZone.current
        cal.timeZone = timezone
        
        var beginComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        beginComps.hour = 0
        beginComps.minute = 0
        beginComps.second = 0
        
        var endComps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        endComps.hour = 23
        endComps.minute = 59
        endComps.second = 59
        
        let beginOfToday = cal.date(from: beginComps)!
        let endOfToday = cal.date(from: endComps)!
        
        return [beginOfToday, endOfToday]
    }    
    
    func populateTable() {
        assignmentsTable.setNumberOfRows(assignments.count, withRowType: "ILPAssignmentsTableRowController")

        var displayedAssignments = false
        for (index, assignment) in self.assignments.enumerated() {
            displayedAssignments = true
            let row = assignmentsTable.rowController(at: index) as! ILPAssignmentsTableRowController
            row.titleLabel.setText(assignment["name"] as! String!)

            if assignment["courseName"] != nil && assignment["courseSectionNumber"] != nil {
                if let courseNameString = assignment["courseName"] as! String!, let courseSectionNumberString = assignment["courseSectionNumber"] as! String! {
                    row.courseLabel.setText("\(courseNameString)-\(courseSectionNumberString)")
                }
            } else if assignment["courseName"] != nil {
                row.courseLabel.setText(assignment["courseName"] as! String!)
            } else {
                row.courseLabel.setHidden(true)
            }

            if assignment["dueDate"] != nil {
                if let assignmentDate = assignment["dueDate"] as! Date! {
                    let time = (self.datetimeOutputFormatter.string(from: assignmentDate))
                    row.timeLabel.setText(time)
                }
            } else {
                row.timeLabel.setHidden(true)
            }
        }
        
        if WatchConnectivityManager.sharedInstance.isUserLoggedIn() {
            self.signInLabel.setHidden(true)
            noAssignments.setHidden(displayedAssignments)
        } else {
            self.signInLabel.setHidden(false)
            noAssignments.setHidden(true)
        }
    


    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        if (segueIdentifier == "ilp-assignment-detail") {
            return self.assignments![rowIndex]
        }
        return nil
    }
    
}
