//
//  ILPAssignmentsDetailController.swift
//  Mobile
//
//  Created by Jason Hocker on 4/28/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WatchKit
import CoreData
import EventKit

class ILPAssignmentsDetailController: WKInterfaceController {
    
    
    var assignment : Dictionary<String, AnyObject>?
    
    let datetimeOutputFormatter : DateFormatter = {
        var formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter
        
        }()
    
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var timeLabel: WKInterfaceLabel!
    @IBOutlet var courseNameLabel: WKInterfaceLabel!
    @IBOutlet var descriptionLabel: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        self.assignment = context as? Dictionary<String, AnyObject>
        
        if let assignment = self.assignment {
            self.titleLabel.setText((assignment["name"] as! String))
            
            if assignment["courseName"] != nil && assignment["courseSectionNumber"] != nil {
                if let courseNameString = assignment["courseName"] as? String, let courseSectionNumberString = assignment["courseSectionNumber"] as? String {
                    self.courseNameLabel.setText("\(courseNameString)-\(courseSectionNumberString)")
                }
            } else if assignment["courseName"] != nil {
                self.courseNameLabel.setText((assignment["courseName"] as! String))
            }
            
            if assignment["dueDate"] != nil {
                if let assignmentDate = assignment["dueDate"] as? Date {
                    let time = (self.datetimeOutputFormatter.string(from: assignmentDate))
                    self.timeLabel.setText(time)
                }
            } else {
                self.timeLabel.setHidden(true)
            }

            self.descriptionLabel.setText((assignment["assignmentDescription"] as! String))
        }
    }
    
    @IBAction func addReminder() {
        let eventStore : EKEventStore = EKEventStore()
        
        eventStore.requestAccess(to: .reminder) { (granted, error) -> Void in
            //
            if granted {
                if let assignment = self.assignment {
                    let reminder:EKReminder = EKReminder(eventStore: eventStore)
                    reminder.title = assignment["name"] as? String ?? ""
                    reminder.calendar = eventStore.defaultCalendarForNewReminders()
                    
                    var localizedDue : String? = nil
                    if let date = assignment["dueDate"] as? Date {
                        let calendar = Calendar.current
                        reminder.dueDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
                        let alarm = EKAlarm(absoluteDate: date)
                        reminder.alarms = [alarm]
                        let formattedDate = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
                        
                        localizedDue = String.localizedStringWithFormat(NSLocalizedString("Due: %@", comment: "due date label with date"), formattedDate)

                    }

                    var reminderCourseName : String
                    if let courseNameString = assignment["courseName"] as? String, let courseSectionNumberString = assignment["courseSectionNumber"] as? String {
                        
                        reminderCourseName = ("\(courseNameString)-\(courseSectionNumberString)")
                        
                    } else if let courseName = assignment["courseName"] as? String {
                        reminderCourseName = courseName
                    } else {
                        reminderCourseName = ""
                    }
                    
                    if let description = assignment["assignmentDescription"] as? String {
                        
                        if let localizedDue = localizedDue {
                            reminder.notes = "\(reminderCourseName)\n\(localizedDue)\n\(description))"
                        } else {
                            reminder.notes = "\(reminderCourseName)\n\(description))"
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func addToCalendar() {
        
        let eventStore : EKEventStore = EKEventStore()
        eventStore.requestAccess(to: .event, completion: {
            granted, error in
            if (granted) && (error == nil) {
                
                let event:EKEvent = EKEvent(eventStore: eventStore)
                event.title = (self.assignment!["name"] as! String)
                if let dueDate = self.assignment!["dueDate"] as? Date {
                    event.startDate = dueDate
                    event.endDate = dueDate
                }
                event.notes = (self.assignment!["assignmentDescription"] as! String)
                event.calendar = eventStore.defaultCalendarForNewEvents
                
                var location : String?
                if self.assignment!["courseName"] != nil && self.assignment!["courseSectionNumber"] != nil {
                    if let courseNameString = self.assignment!["courseName"] as? String, let courseSectionNumberString = self.assignment!["courseSectionNumber"] as? String {
                        location = ("\(courseNameString)-\(courseSectionNumberString)")
                    }
                } else if self.assignment!["courseName"] != nil {
                    location = (self.assignment!["courseName"] as! String)
                }
                
                event.location = location
                
//                do {
//                    try eventStore.saveEvent(event, span: .ThisEvent)
//                } catch {
//                    fatalError()
//                }
            } else {
                //todo add modal message to tell them to go iphone to change permissions
            }
        })
        
    }

}
