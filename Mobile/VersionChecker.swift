//
//  VersionChecker.swift
//  Mobile
//
//  Created by Jason Hocker on 7/11/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class VersionChecker {
    
    static let sharedInstance = VersionChecker()
    
    private init() {
        
    }
    
    static var latestVersionToCauseAlert = ""
    static let VersionCheckerCurrentNotification = Notification.Name("VersionCheckerCurrentNotification")
    static let VersionCheckerAppNewerNotification = Notification.Name("VersionCheckerAppNewerNotification")
    static let VersionCheckerUpdateAvailableNotification = Notification.Name("VersionCheckerUpdateAvailableNotification")
    static let VersionCheckerOutdatedNotification = Notification.Name("VersionCheckerOutdatedNotification")
    
    func checkVersion(_ supportedVersions: [String]) -> Bool {
        var notificationFired = false
        
        let plistPath = Bundle.main.path(forResource: "Customizations", ofType: "plist")!
        
        if let plistDictionary = NSDictionary(contentsOfFile: plistPath) {
            var enableVersionChecking = true
            if let enableVersionCheckingPlist = plistDictionary["Enable Version Checking"] as? Bool {
                enableVersionChecking = enableVersionCheckingPlist
            }
            if !enableVersionChecking {
                return true
            }
            //support legacy cloud servers
            if supportedVersions.count == 0 {
                return true
            }
            let appInfo = Bundle.main.infoDictionary!
            let appVersion = appInfo["CFBundleVersion"] as! String
            var appVersionComponents = appVersion.components(separatedBy: ".")
            let appVersionWithoutBuildNumber: String = appVersionComponents[0..<3].joined(separator: ".")
            let latestSupportedVersion = supportedVersions.last!
            var latestSupportedVersionComponents = latestSupportedVersion.components(separatedBy: ".")
            //current
            if (supportedVersions.last! == appVersionWithoutBuildNumber) {
                notificationFired = true
                NotificationCenter.default.post(name: VersionChecker.VersionCheckerCurrentNotification, object: nil)
            }
            else if appVersionComponents.count > 2 && latestSupportedVersionComponents.count > 2 && (appVersionWithoutBuildNumber == latestSupportedVersionComponents[0..<3].joined(separator: ".")) {
                notificationFired = true
                NotificationCenter.default.post(name: VersionChecker.VersionCheckerCurrentNotification, object: nil)
            }
            else if supportedVersions.contains(appVersionWithoutBuildNumber) {
                //if user hasn't been alerted, suggest upgrade
                notificationFired = true
                //Only tell them once... do not keep showing them the update alert
                if !(VersionChecker.latestVersionToCauseAlert == latestSupportedVersion) {
                    VersionChecker.latestVersionToCauseAlert = latestSupportedVersion
                    NotificationCenter.default.post(name: VersionChecker.VersionCheckerUpdateAvailableNotification, object: nil)
                }
            }
            
            //app newer than what server returns
            if appVersionComponents.count > 0 && latestSupportedVersionComponents.count > 0 && CInt(appVersionComponents[0])! > CInt(latestSupportedVersionComponents[0])! {
                notificationFired = true
                NotificationCenter.default.post(name: VersionChecker.VersionCheckerAppNewerNotification, object: nil)
            }
            else if appVersionComponents.count > 0 && latestSupportedVersionComponents.count > 0 && CInt(appVersionComponents[0])! == CInt(latestSupportedVersionComponents[0])! {
                if appVersionComponents.count > 1 && latestSupportedVersionComponents.count > 1 && CInt(appVersionComponents[1])! > CInt(latestSupportedVersionComponents[1])! {
                    notificationFired = true
                    NotificationCenter.default.post(name: VersionChecker.VersionCheckerAppNewerNotification, object: nil)
                }
                else if appVersionComponents.count > 1 && latestSupportedVersionComponents.count > 1 && CInt(appVersionComponents[1])! == CInt(latestSupportedVersionComponents[1])! {
                    if appVersionComponents.count > 2 && latestSupportedVersionComponents.count > 2 && CInt(appVersionComponents[2])! > CInt(latestSupportedVersionComponents[2])! {
                        notificationFired = true
                        NotificationCenter.default.post(name: VersionChecker.VersionCheckerAppNewerNotification, object: nil)
                    }
                }
            }
        }
        
        if !notificationFired {
            NotificationCenter.default.post(name: VersionChecker.VersionCheckerOutdatedNotification, object: nil)
            return false
        }
        else {
            return true
        }
    }
}
