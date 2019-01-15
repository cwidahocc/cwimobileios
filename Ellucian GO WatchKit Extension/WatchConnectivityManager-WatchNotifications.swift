//
//  WatchConnectivityManager-WatchNotifications.swift
//  Mobile
//
//  Created by Bret Hansen on 9/12/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import UserNotifications
import WatchKit

@available(watchOS 3.0, *)
extension WatchConnectivityManager:UNUserNotificationCenterDelegate{
    private static let notificationCategory = "LaunchBeaconCategory"
    private static let notificationNotInterestedActionId = "LaunchBeaconNotInterestedAction"
    //private static let notificationNotInterestedActionLabel = NSLocalizedString("Not Interested", comment: "Not Interested label")
    private static let notificationViewActionId = "LaunchBeaconViewAction"
    //private static let notificationViewActionLabel = NSLocalizedString("View", comment: "View label")
    private static let notificationDefaultActionId = "LaunchBeaconDefaultAction"

    
    func initializeNotifications() -> Void {
        print("initializing UserNotifications")
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) {_,_ in}
        
        let notInterestedAction = UNNotificationAction(identifier: WatchConnectivityManager.notificationNotInterestedActionId, title: NSLocalizedString("Not Interested", comment: "Not Interested label"), options: [.destructive])
        //let viewAction = UNNotificationAction(identifier: WatchConnectivityManager.notificationViewActionId, title: WatchConnectivityManager.notificationViewActionLabel, options: [])
        
        let launchBeaconCategory = UNNotificationCategory(identifier: WatchConnectivityManager.notificationCategory, actions: [/*viewAction,*/ notInterestedAction], intentIdentifiers: [], options: [])
        
        center.getNotificationCategories() {(categoriesIn) in
            let categories = categoriesIn
            print("notification categories.count: \(categories.count)")
            
            // remove any category with the same identifier
            var filteredCategories = categories.filter {
                $0.identifier != launchBeaconCategory.identifier
            }
            print("notification categories.count after filter: \(filteredCategories.count)")
            
            // add this newly defined category
            filteredCategories.insert(launchBeaconCategory)
            print("Added watch notification category")
            
            center.setNotificationCategories(Set(filteredCategories))
        }
        
        center.delegate = self
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification Response action identifier: \(response.actionIdentifier)")
        let userInfo = response.notification.request.content.userInfo
        if let moduleKey = userInfo["moduleKey"] as! String? {
            switch(response.actionIdentifier) {
            case UNNotificationDismissActionIdentifier: break
            case WatchConnectivityManager.notificationNotInterestedActionId:
                print("telling phone to mute this module")
                sendActionMessage("mute beacon", data: ["moduleKey": moduleKey], replyHandler: { _ in }, errorHandler: { _ in })
            case WatchConnectivityManager.notificationViewActionId:
                fallthrough
            default:
                // handoff to phone
                DispatchQueue.main.async {
                    print("handing off to phone")
                    if let wkRootController = self.wkRootController as! WKInterfaceController? {
                        wkRootController.invalidateUserActivity()
                        wkRootController.updateUserActivity("com.ellucian.go.open.module", userInfo: ["moduleKey": moduleKey], webpageURL: nil)
                        
                        let action = WKAlertAction(title: NSLocalizedString("OK", comment: "OK button on alert view"), style: WKAlertActionStyle.default, handler: {})
                        let message = NSLocalizedString("Please use Handoff to complete to view the content", comment: "Handoff message")
                        wkRootController.presentAlert(withTitle: NSLocalizedString("View " + self.getPhoneAppName() + " on phone", comment: "View on phone"), message: message, preferredStyle: WKAlertControllerStyle.alert, actions: [action])
                    }
                }
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping(UNNotificationPresentationOptions) -> Void) {
        print("notification will present")
        completionHandler([.alert, .sound])
    }
}
