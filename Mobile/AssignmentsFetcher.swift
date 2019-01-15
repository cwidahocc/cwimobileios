//
//  AssignmentsFetcher.swift
//  Mobile
//
//  Created by Jason Hocker on 5/19/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class AssignmentsFetcher: NSObject {
    
    class func fetch(_ context: NSManagedObjectContext, url: String) {
        
        let importContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        importContext.parent = context
        
        if let userid = CurrentUser.sharedInstance.userid {
            
            let urlString = NSString( format:"%@/%@/assignments", url, userid )
            let url: URL? = URL(string: urlString as String)
            
            let authenticatedRequest = AuthenticatedRequest()

            if let response = authenticatedRequest.requestURL(url, fromView: nil)

            {
                NotificationCenter.default.removeObserver(self, name:CurrentUser.LoginExecutorSuccessNotification, object:nil)
                
                let json = JSON(data: response)
                
                let request = NSFetchRequest<CourseAssignment>(entityName: "CourseAssignment")
                var oldObjects: [AnyObject]?
                do {
                    oldObjects = try importContext.fetch(request)
                } catch {
                }
                
                for oldObject in oldObjects! {
                    importContext.delete(oldObject as! NSManagedObject)
                }
                
                let assignmentList: Array<JSON> = json["assignments"].arrayValue
                
                for  jsonDictionary in assignmentList {
                    let entry:CourseAssignment = NSEntityDescription.insertNewObject(forEntityName: "CourseAssignment", into: importContext) as! CourseAssignment
                    entry.sectionId = jsonDictionary["sectionId"].stringValue
                    entry.courseName = jsonDictionary["courseName"].stringValue
                    entry.courseSectionNumber = jsonDictionary["courseSectionNumber"].stringValue
                    entry.name = jsonDictionary["name"].stringValue
                    entry.assignmentDescription = jsonDictionary["description"].stringValue
                    
                    let datetimeFormatter = DateFormatter()
                    datetimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'";
                    datetimeFormatter.timeZone = TimeZone(abbreviation:"UTC")
                    
                    entry.dueDate = datetimeFormatter.date(from: jsonDictionary["dueDate"].stringValue)
                    entry.url = jsonDictionary["url"].stringValue
                }
                
                do {
                    try importContext.save()
                } catch let saveError as NSError {
                    print("save error: \(saveError.localizedDescription)")
                } catch {
                    
                }
            }

            do {
                try importContext.parent!.save()
            } catch let parentError as NSError {
                print("Could not save to store after update to course assignments: \(parentError.localizedDescription)")
            } catch {
            }
        }
        
    }
}
