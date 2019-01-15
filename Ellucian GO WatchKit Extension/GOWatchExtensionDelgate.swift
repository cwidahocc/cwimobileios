//
//  GOWatchExtensionDelgate.swift
//  Mobile
//
//  Created by Bret Hansen on 9/16/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WatchKit

class GOWatchExtensionDelegate: NSObject, WKExtensionDelegate {
    // need a strong reference in Watch to the WatchConnectivityManager
    
    var watchConnectivityManager: WatchConnectivityManager? = nil

    func applicationDidBecomeActive() {
        print("applicationDidBecomeActive")
        WatchConnectivityManager.sharedInstance.ensureWatchConnectivityInitialized()
        WatchConnectivityManager.sharedInstance.refreshUser()
        watchConnectivityManager = WatchConnectivityManager.sharedInstance // keep a strong reference
    }
}
