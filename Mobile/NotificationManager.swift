//
//  NotificationManager.swift
//  Mobile
//
//  Created by Bret Hansen  on 1/14/14, Jason Hocker on 1/31/17.
//  Copyright © 2014-2017 Ellucian Company L.P. and its affiliates. All rights reserved.
//
import Foundation
import UserNotifications

class NotificationManager : NSObject {

    static let shared = NotificationManager()
    
    private override init() {
        super.init()
    }
    
    class func registerDeviceIfNeeded() {
        let defaults: UserDefaults? = AppGroupUtilities.userDefaults()
        let notificationRegistrationUrl: String? = defaults?.string(forKey: "notification-registration-url")
        let user = CurrentUser.sharedInstance
        // if notification url is defined and user is logged in
        if let _ = notificationRegistrationUrl, user.isLoggedIn {
            
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
                granted, error in
                if granted {
                   DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }

    class func registerDeviceToken(_ deviceToken: Data) {
        let defaults = AppGroupUtilities.userDefaults()
        let notificationRegistrationUrl = defaults?.string(forKey: "notification-registration-url")
        let notificationEnabled = defaults?.string(forKey: "notification-enabled")
        let user = CurrentUser.sharedInstance
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)}).uppercased()
        
        let applicationName = (Bundle.main.infoDictionary![(kCFBundleNameKey as String)] as! String)
        // if urlString is set and either notificationEnabled hasn't been determined or is YES, then attempt to register
        if let notificationRegistrationUrl = notificationRegistrationUrl, (notificationEnabled == nil || NSString(string: notificationEnabled ?? "").boolValue ) {
            var registerDictionary  = ["devicePushId": deviceTokenString, "platform": "ios", "applicationName": applicationName, "loginId": user.userauth, "sisId": user.userid]
            if user.email != nil {
                registerDictionary["email"] = user.email
            }
            
            let urlRequest = NSMutableURLRequest(url: URL(string: notificationRegistrationUrl)!)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let authenticationMode = defaults?.string(forKey: "login-authenticationType")
            if authenticationMode == nil || (authenticationMode == "native") {
                urlRequest.addAuthenticationHeader()
            }
            urlRequest.httpMethod = "POST"

            let jsonData = try? JSONSerialization.data(withJSONObject: registerDictionary, options: JSONSerialization.WritingOptions(rawValue: 0))
            urlRequest.httpBody = jsonData
            let semaphore = DispatchSemaphore(value: 0)
            let session = URLSession.shared
            // or create your own session with your own NSURLSessionConfiguration
            
            
            let task: URLSessionTask? = session.dataTask(with: urlRequest as URLRequest) {responseData, response, error in
                let httpResponse: HTTPURLResponse? = (response as? HTTPURLResponse)
                let statusCode = httpResponse?.statusCode
                if let responseData = responseData {
                    let jsonResponse = JSON(data:responseData)
                    
                    // check if the status is "success" if not we should not continue to attempt to interact with the Notifications API
                    if let statusCode = statusCode, statusCode != 200 && statusCode != 201 {
                        if let error = error {
                            print("Device token registration failed status: \(statusCode) - \(error.localizedDescription)")
                        } else {
                            print("Device token registration failed status: \(statusCode)")
                        }
                        
                    }
                    else {
                        let status = (jsonResponse["status"].string) ?? "disabled"
                        let enabled = (status == "success")
                        let notificationEnabled: String = enabled ? "YES" : "NO"
                        defaults?.set(notificationEnabled, forKey: "notification-enabled")
                        if enabled {
                            // remember the registered user, so we re-register if user id changes
                            defaults?.set(user.userid, forKey:"registered-user-id")
                        }
                    }
                    semaphore.signal()
                }
            }
            task?.resume()
            let _ = semaphore.wait(timeout: .distantFuture)
        }
    }

}

@available(iOS 10.0, *)
extension NotificationManager : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification Response action identifier: \(response.actionIdentifier)")
        let userInfo = response.notification.request.content.userInfo
        
        if let _ = userInfo["aps"] as? NSDictionary {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.sendEvent(category:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      .push_Notification, action: .receivedMessage, label: "whileInActive")
            }
            UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: false, completion: nil)
            let operation: OpenModuleOperation = OpenModuleOperation(type: "notifications")
            if let uuid = userInfo["uuid"] as? String {
                operation.properties = ["uuid": uuid]
            }
            OperationQueue.main.addOperation(operation)
        } else if let moduleKey = userInfo["moduleKey"] as! String? {
            switch(response.actionIdentifier) {
            case UNNotificationDismissActionIdentifier:
                break
            case LaunchBeaconManager.notificationMuteForeverActionId:
                LaunchBeaconManager.shared.markModuleMuteForever(moduleKey)
            case LaunchBeaconManager.notificationMuteForTodayActionId:
                if let beaconId = userInfo["beaconId"] as! String? {
                    LaunchBeaconManager.shared.markBeaconMuteForToday(beaconId)
                }
            case LaunchBeaconManager.notificationViewActionId:
                fallthrough
            default:
                LaunchBeaconManager.shared.openModule(moduleKey)
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping(UNNotificationPresentationOptions) -> Void) {
//        let userInfo = notification.request.content.userInfo
//
//        
//        if let aps = userInfo["aps"] as? NSDictionary {
//            print("application active - show notification message alert")
//            // log activity to Google Analytics
//            //move out of here
//            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
//                rootViewController.sendEvent(category: .push_Notification, action: .receivedMessage, label: "whileActive")
//            }
//            if let alertMessage = aps["alert"] as? String {
//                let alert: UIAlertController = UIAlertController(title: NSLocalizedString("New Notification", comment: "new notification has arrived"), message: alertMessage, preferredStyle: .alert)
//                let view: UIAlertAction = UIAlertAction(title: NSLocalizedString("View", comment: "view label"), style: .default, handler: {(action: UIAlertAction) -> Void in
//                    let operation: OpenModuleOperation = OpenModuleOperation(type: "notifications")
//                    if let uuid = userInfo["uuid"] as? String {
//                        operation.properties = ["uuid": uuid]
//                    }
//                    OperationQueue.main.addOperation(operation)
//                })
//                let cancel: UIAlertAction = UIAlertAction(title: NSLocalizedString("Close", comment: "Close"), style: .cancel, handler: {(action: UIAlertAction) -> Void in
//                    alert.dismiss(animated: true, completion: { _ in })
//                })
//                alert.addAction(cancel)
//                alert.addAction(view)
//                UIApplication.shared.keyWindow?.makeKeyAndVisible()
//                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
//                completionHandler([.alert, .sound])
//            }
//        }
//        else {
            print("notification will present")
            completionHandler([.alert, .sound])
//        }
    }

}
