//
//  WatchConnectivity-Session.swift
//  Mobile
//
//  Created by Bret Hansen on 9/14/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WatchConnectivity

@available(watchOS 2.0, *)
extension WatchConnectivityManager:WCSessionDelegate {
    
    @available(watchOS 2.2, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activation did complete with status")
        sessionActive = true
        if session.isReachable {
            self.sendNextActionMessage()
            if refreshUserAfterReachable {
                refreshUserAfterReachable = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.refreshUser()
                }
            }
        }
    }
        
    // Info for watch from phone
    @available(watchOS 2.0, *)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        var popToRoot = false
        if let action = userInfo["action"] as! String? {
            switch(action) {
            case "configurationLoaded":
                print("WatchConnectivityManager received configuration loaded")
                if let configurationData = userInfo["data"] as! Data? {
                    let _ = ConfigurationManager.shared.processConfigurationData(configurationData, notifyOtherSide: false) {
                        (result: Bool) in
                        ImageCache.sharedCache.reset()
                        popToRoot = true
                    }
                }
                break
            case "userLoggedIn":
                if let userData = userInfo["data"] as? [String: Any] {
                    self.userLoggedIn(userData, notifyOtherSide: false)
                    popToRoot = true
                    print("WatchConnectivityManager received user logged in")
                }
                break
            case "userLoggedOut":
                self.userLoggedOut(false)
                popToRoot = true
                print("WatchConnectivityManager received user logged out")
                break
            default:
                print("Received unknown infoType: \(action)")
            }
        }
        
        if popToRoot && wkRootController != nil {
            DispatchQueue.main.async {
                #if os(watchOS)
                    if let menuController = self.wkRootController as! MenuController? {
                        menuController.popToRootController()
                        menuController.initMenu()
                        print("WatchConnectivityManager pop to root controller")
                    }
                #endif
            }
        }
    }
}
