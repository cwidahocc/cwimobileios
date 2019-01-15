//
//  WatchStateManager.swift
//  Mobile
//
//  Created by Bret Hansen on 9/3/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WatchConnectivity
import WatchKit

class WatchConnectivityManager: NSObject {
    static let receivedMessage = Notification.Name("WatchConnectivityManager: message")
    static let sharedInstance = WatchConnectivityManager()
    
    private var wcSession: WCSession?
    private(set) var lastConfigData: Data?
    private var user: [String: Any]?
    var refreshUserAfterReachable = false
    fileprivate var refreshingUser = false
    var sessionActive = false
    
    #if os(watchOS)
    private let actionQueueSize = 3
    #else
    private let actionQueueSize = 5
    #endif
    
    var wkRootController: AnyObject? = nil
    
    private var phoneAppName: String?
    
    private var actionQueue = [ActionMessage]()
    private var pinging = false
    private var pingid = 0
    private var retryDelaySeconds: Double = 1
    private var actionTimeoutSeconds: Double = 7
    
    // make init private for singleton
    override private init() {
    }
    
    func getPhoneAppName() -> String {
        if phoneAppName == nil {
            let plistPath = Bundle.main.path(forResource: "Customizations", ofType: "plist")
            let plistDictioanry = NSDictionary(contentsOfFile: plistPath!)!
            
            if let name = plistDictioanry["iOS Application Name"] as! String? {
                self.phoneAppName = name
            } else {
                self.phoneAppName = "Ellucian GO"
            }
        }
        
        return self.phoneAppName!
    }
    
    func saveRootController(_ controller: AnyObject) {
        self.wkRootController = controller
        print("WatchConnectivityManager saved root controller")
    }
    
    func ensureWatchConnectivityInitialized() {
        if wcSession == nil {
            if WCSession.isSupported() {
                wcSession = WCSession.default
                wcSession!.delegate = self
                wcSession!.activate()
                print("WatchConnectivityManager - called WSSession.activate()")
            }

            #if os(watchOS)
                initializeNotifications()
            #endif
        }        
    }
    
    @available(iOS 9.0, *)
    func session() -> WCSession? {
        return wcSession
    }
    
    func currentUser() -> [String: Any]? {
        
        if let _ = self.user {
            if let defaults = AppGroupUtilities.userDefaults() {
                if let defaultuser = defaults.object(forKey: "current user") as! [String: AnyObject]? {
                    self.user = defaultuser
                }
            }
        }
        
        return self.user
    }
    
    func isUserLoggedIn() -> Bool {
        let currentUser = self.currentUser()
        let isLoggedIn = (currentUser != nil) && (currentUser!["userid"] != nil)
        
        return isLoggedIn
    }
    
    func userLoggedIn(_ user: [String : Any], notifyOtherSide: Bool = true) {
        // save the user
        self.user = user
        if let defaults = AppGroupUtilities.userDefaults() {
            defaults.set(self.user, forKey: "current user")
        }
        
        if notifyOtherSide {
            // need to let the other device know
            self.notifyOtherSide("userLoggedIn", data: user as AnyObject)
        }
        
        // clear user data caches
        #if os(watchOS)
            DefaultsCache.clearLogoutCaches()
        #endif
        
    }
    
    func userLoggedOut(_ notifyOtherSide: Bool = true) {
        user = nil
        if let defaults = AppGroupUtilities.userDefaults() {
            defaults.removeObject(forKey: "current user")
        }
        if notifyOtherSide {
            self.notifyOtherSide("userLoggedOut")
        }
        
        // clear user data caches
        #if os(watchOS)
            DefaultsCache.clearLogoutCaches()
        #endif
    }
    
    func refreshUser()  {
        if let session = wcSession {
            if !refreshingUser {
                refreshingUser = true
                if session.isReachable {
                    // ask for a refresh of the user data
                    print("refreshUser sending action \"fetch user\" to phone")
                    sendActionMessage("fetch user", replyHandler: {
                        (data) -> Void in
                        
                        self.refreshingUser = false
                        let newUser = data["user"] as! [String: AnyObject]?
                        if (newUser != nil) {
                            let currentUser = self.currentUser()
                            let currentUserId = currentUser != nil ? currentUser!["userid"] as! String? : nil
                            var newUserId = newUser!["userid"] as! String?
                            
                            if newUserId != nil && newUserId == "" {
                                // when no user is logged in the userid is ""
                                newUserId = nil
                            }
                            
                            let logout = currentUserId != nil && (newUserId == nil || currentUserId! != newUserId!)
                            let login = newUserId != nil && (currentUserId == nil || currentUserId! != newUserId!)
                            
                            if logout {
                                self.userLoggedOut()
                                print("refreshUser logged out \(currentUserId!)")
                            }
                            
                            if login {
                                self.userLoggedIn(newUser!)
                                print("refreshUser logged in \(newUserId!)")
                            }
                        } else {
                            if self.isUserLoggedIn() {
                                self.userLoggedOut(false)
                            }
                            print("refreshUser user is logged out")
                        }
                        }, errorHandler: {
                            (error) -> Void in
                            
                            self.refreshingUser = false
                            print("refreshUser failed: \(error)")
                    })
                } else {
                    refreshingUser = false
                    refreshUserAfterReachable = true
                    print("refreshUser WC not yet reachable")
                }
            }
            
        }
        
        //        return WatchConnectivityManager.sharedInstance
    }
    
    func notifyOtherSide(_ action: String, data: Any? = nil) {
        if let session = wcSession {
            var userInfo: [String: Any] = [
                "action": action
            ]
            
            if data != nil {
                userInfo["data"] = data
            }
            
            session.transferUserInfo(userInfo)
        }
    }
    
    private class ActionMessage {
        let action: String
        let data: [String: Any]?
        let replyHandler: (([String: Any]) -> Void)?
        let errorHandler: ((Error) -> Void)?
        var retryCount: Int = 0
        
        init(action: String, data: [String: Any]? = nil, replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?) {
            self.action = action
            self.data = data
            self.replyHandler = replyHandler
            self.errorHandler = errorHandler
        }
    }
    
    func sendActionMessage(_ action: String, data: [String: Any]? = nil, replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?) {
        
        // ensure only at most one of each action is in the queue
        actionQueue = actionQueue.filter { $0.action != action }
        
        // add this action message to the queue
        actionQueue.append(ActionMessage(action: action, data: data, replyHandler: replyHandler, errorHandler: errorHandler))
        
        self.sendNextActionMessage()
    }
    
    func sendCommunicationErrorToAllActionMessages() {
        for actionMessage in actionQueue {
            if let errorHandler = actionMessage.errorHandler {
                errorHandler(NSError(domain: "WatchConnectivityManager", code: 1, userInfo: nil))
            }
        }
    }
    
    private func showCommunicationError() {
        #if os(watchOS)
            if sessionActive {
                if let wkRootController = self.wkRootController as! WKInterfaceController? {
                    let action = WKAlertAction(title: NSLocalizedString("OK", comment: "OK button on alert view"), style: WKAlertActionStyle.default, handler: {})
                    let message = String.localizedStringWithFormat(NSLocalizedString("Please ensure the phone is nearby and launch %@ on the phone",
                                                                                     comment: "Watch communication to phone error message"), self.getPhoneAppName())
                    wkRootController.presentAlert(withTitle: NSLocalizedString("Communication Error", comment: "Watch communication to phone error title"), message: message, preferredStyle: WKAlertControllerStyle.alert, actions: [action])
                }
            }
            
        #endif
    }
    
    func sendNextActionMessage() {
        ensureWatchConnectivityInitialized()
        
        if actionQueue.count > 0 {
            if let session = wcSession {
                if session.isReachable {
                    let actionMessage = actionQueue.removeFirst()
                    sendActualActionMessage(actionMessage.action, data: actionMessage.data, retryCount: actionMessage.retryCount, replyHandler: {
                        (response) -> Void in
                        
                        if let actionReplyHandler = actionMessage.replyHandler {
                            actionReplyHandler(response)
                        }
                        self.sendNextActionMessage()
                        }, errorHandler: {
                            (error) -> Void in
                            
                            if let actionErrorHandler = actionMessage.errorHandler {
                                actionErrorHandler(error)
                            }
                            self.sendNextActionMessage()
                    })
                } else {
                    // if not yet reachable, call to Session delegate will kick off next message
                }
            }
        }
    }
    
    private func sendActualActionMessage(_ action: String, data: [String: Any]? = nil, retryCount: Int, replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?) {
        if let session = wcSession {
            var message = [ "action": action]
            if let data = data {
                message.merge(data)
            }
            
            print("sendActionMessage sending action: \(action)")
            print("sendActionMessage session reachable: \(session.isReachable)")
            session.sendMessage(message, replyHandler: {
                (data) -> Void in
                
                print("sendActionMessage action: \(action) received data")
                
                if let replyHandler = replyHandler {
                    replyHandler(data)
                }
                }, errorHandler: {
                    (error) -> Void in
                    
                    let code = error._code
                    let domain = error._domain
                    var errorHandled = false
                    print("sendActionMessage error code: \(code) domain: \(domain)")
                    
                    var showCommunicationError = false
                    if error._code == 7014 || error._code == 7012 {
                        if retryCount < 3 {
                            // failed to send, retry after a short delay
                            print("failed to send -> retry: \(retryCount+1))")
                            errorHandled = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.sendActualActionMessage(action, data: data, retryCount: retryCount+1, replyHandler: replyHandler, errorHandler: errorHandler)
                            }
                        } else {
                            showCommunicationError = true
                        }
                    } else {
                        showCommunicationError = true
                    }
                    
                    #if os(watchOS)
                        if showCommunicationError {
                            if let wkRootController = self.wkRootController as! WKInterfaceController? {
                                let action = WKAlertAction(title: NSLocalizedString("OK", comment: "OK button on alert view"), style: WKAlertActionStyle.default, handler: {})
                                let message = NSLocalizedString("Please ensure the phone is nearby and launch",
                                                                comment: "Watch communication to phone error message") + self.getPhoneAppName()
                                wkRootController.presentAlert(withTitle: NSLocalizedString("Communication Error", comment: "Watch communication to phone error title"), message: message, preferredStyle: WKAlertControllerStyle.alert, actions: [action])
                            }
                        }
                    #endif
                    
                    if !errorHandled {
                        if let errorHandler = errorHandler {
                            errorHandler(error)
                        }
                    }
            })
        }
    }
}
