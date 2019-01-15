//
//  NotificationsFetcher.swift
//  Mobile
//
//  Created by Jason Hocker on 7/11/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class NotificationsFetcher : NSObject {
    static var lock = false
    
    static let NotificationsUpdatedNotification = Notification.Name("NotificationsUpdated")
    
    
    class func fetchNotificationsFromURL(notificationsUrl: String, withManagedObjectContext managedObjectContext: NSManagedObjectContext, showLocalNotification: Bool, fromView view: UIViewController?) {
        let importContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        importContext.parent = managedObjectContext
        if NotificationsFetcher.lock {
            return
        }
        //already in progress
        NotificationsFetcher.lock = true
        
        importContext.perform({() -> Void in
            
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            let authenticatedRequest: AuthenticatedRequest = AuthenticatedRequest()
            let responseData = authenticatedRequest.requestURL(NSURL(string: notificationsUrl)! as URL, fromView: view)
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            var newKeys = [String]()
            
            var unreadNotificationCount: Int = 0
            
            if let responseData = responseData {
                let json = JSON(data: responseData)
                var previousNotifications = [String : EllucianNotification]()
                let request = NSFetchRequest<EllucianNotification>(entityName: "Notification")
                let oldObjects = try? importContext.fetch(request)
                for oldObject in oldObjects! {
                    previousNotifications[oldObject.notificationId!] = oldObject
                }
                
                if let notifications = json["notifications"].array {
                    for notificationDictionary in notifications {
                        let notificationId = notificationDictionary["id"].string!
                        var notification = previousNotifications[notificationId]
                        var updateObject: Bool = false
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                        
                        if let notification = notification {
                            previousNotifications.removeValue(forKey: notificationId)
                            
                            if notification.notificationId != notificationDictionary["id"].string {
                                updateObject = true
                            }
                            else if notification.title != notificationDictionary["title"].string {
                                updateObject = true
                            }
                            else if notificationDictionary["description"].string != nil && notification.notificationDescription != notificationDictionary["description"].string {
                                updateObject = true
                            }
                            else if notificationDictionary["description"].string != nil && notification.notificationDescription != notificationDictionary["description"].string {
                                updateObject = true
                            }
                            else if notificationDictionary["hyperlink"].string != nil && notification.hyperlink != notificationDictionary["hyperlink"].string {
                                updateObject = true
                            }
                            else if notificationDictionary["linkLabel"].string != nil && notification.linkLabel != notificationDictionary["linkLabel"].string {
                                updateObject = true
                            }
                            else if notification.noticeDate != nil && notification.noticeDate as Date? != dateFormatter.date(from: notificationDictionary["noticeDate"].string!) {
                                updateObject = true
                            }
                            else if notificationDictionary["sticky"] != nil {//&& notificationDictionary["sticky"].boolean != notification.sticky {
                                updateObject = true
                            }
                            else if notification.read != nil && notificationDictionary["statuses"] != nil {
                                let statuses = notificationDictionary["statuses"].array
                                for status in statuses! {
                                    if status == "READ" {
                                        updateObject = true
                                    }
                                }
                            }
                        }
                        else {
                            notification = NSEntityDescription.insertNewObject(forEntityName: "Notification", into: importContext) as? EllucianNotification
                            newKeys.append(notificationId)
                            updateObject = true
                        }
                        
                        if updateObject {
                            notification?.notificationId = (notificationDictionary["id"].string)
                            notification?.title = (notificationDictionary["title"].string)
                            if (notificationDictionary["description"].string) != nil {
                                notification?.notificationDescription = (notificationDictionary["description"].string)?.replacingOccurrences(of: "\\n", with: "\n")
                            }
                            if (notificationDictionary["hyperlink"].string) != nil {
                                notification?.hyperlink = (notificationDictionary["hyperlink"].string)
                            }
                            if (notificationDictionary["linkLabel"].string) != nil {
                                notification?.linkLabel = (notificationDictionary["linkLabel"].string)
                            }
                            //if it doesn't report that it is sticky, assume that it is (for legacy purposes)
                            if notificationDictionary["sticky"] != nil {
                                notification?.sticky = NSNumber(value: notificationDictionary["sticky"].boolValue )
                            }
                            else {
                                notification?.sticky = true
                            }
                            if notificationDictionary["statuses"] != nil {
                                let statuses = notificationDictionary["statuses"].array
                                for status in statuses! {
                                    if status == "READ" {
                                        notification?.read = true
                                    }
                                }
                            }
                            else if notification?.read! == true {
                                //previously set locally
                                notification?.read = true
                            }
                            else if notification?.read! == false {
                                unreadNotificationCount += 1
                                notification?.read = false
                            }
                            
                            if let newDate = dateFormatter.date(from: (notificationDictionary["noticeDate"].string)!) {
                                notification?.noticeDate = newDate as NSDate
                            }
                            else {
                                notification?.noticeDate = nil
                            }
                        }
                        
                    }
                    
                }
                
                for oldObject in previousNotifications.values {
                    importContext.delete(oldObject)
                }
                
                
            }
            
            try! importContext.save()
            //persist to store and update fetched result controllers
            importContext.parent?.perform({() -> Void in
                try? importContext.parent?.save()
                if newKeys.count > 0 || unreadNotificationCount > 0 {
                    DispatchQueue.main.async(execute: {() -> Void in
                        NotificationCenter.default.post(name: NotificationsFetcher.NotificationsUpdatedNotification, object: nil)
                    })
                }
                lock = false
                
                
            })
        })
    }
    
    class func fetchNotifications(_ notification: Notification) {
        NotificationsFetcher.fetchNotifications(managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext)
        
    }
    
    class func fetchNotifications(managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<Module>(entityName: "Module")
        let sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        fetchRequest.sortDescriptors = sortDescriptors
        let modules = try? managedObjectContext.fetch(fetchRequest)
        for module in modules! {
            let isLoggedIn = CurrentUser.sharedInstance.isLoggedIn
            if let type = module.type, type == "notifications" && isLoggedIn {
                let userid = CurrentUser.sharedInstance.userid
                if let notificationsUrl = module.property(forKey: "notifications"), let userid = userid {
                    let urlString = "\(notificationsUrl)/\(userid.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!)"
                    NotificationsFetcher.fetchNotificationsFromURL(notificationsUrl: urlString, withManagedObjectContext: managedObjectContext, showLocalNotification: true, fromView: nil)
                }
            }
        }
    }
    
    class func deleteNotification(notification: EllucianNotification, module: Module) {
        //mark deleted on server
        let baseUrl = module.property(forKey: "mobilenotifications")!
        let urlString = "\(baseUrl)/\(CurrentUser.sharedInstance.userid!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!)/\(notification.notificationId!)"
        var urlRequest = URLRequest(url: URL(string: urlString)!)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let authenticationMode = AppGroupUtilities.userDefaults()?.string(forKey: "login-authenticationType")
        if authenticationMode == nil || (authenticationMode == "native") {
            urlRequest.addAuthenticationHeader()
        }
        urlRequest.httpMethod = "DELETE"
        
        let task =  URLSession.shared.dataTask(with: urlRequest)
        task.resume()
        
        let context = notification.managedObjectContext
        context?.delete(notification)
        try! context?.save()
    }
}
