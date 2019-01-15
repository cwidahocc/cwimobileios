//
//  AppGroupUtilities
//  Mobile
//
//  Created by Jason Hocker on 1/26/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

@objc
class AppGroupUtilities : NSObject {

    @objc class func userDefaults() -> UserDefaults? {
        if Bundle.main.bundleIdentifier!.hasPrefix("com.ellucian.elluciangoenterprise") {
            return UserDefaults()
        }
        return UserDefaults(suiteName: lookupAppGroup()!)
    }
    
    class func lookupAppGroup() -> String? {
        var plistDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "Customizations", ofType: "plist") {
            plistDictionary = NSDictionary(contentsOfFile: path)
        }
        if plistDictionary != nil && plistDictionary!["App Group"] != nil {
            let appGroup = plistDictionary?["App Group"] as! String
            if !appGroup.isEmpty {
                return appGroup
            }
        }
        if Bundle.main.bundleIdentifier!.hasPrefix("com.ellucian.elluciangoenterprise") {
            return "group.com.ellucian.elluciangoenterprise"
        }
        if Bundle.main.bundleIdentifier!.hasPrefix("com.ellucian.elluciango") {
            return "group.com.ellucian.elluciango"
        }

        return nil;
    }
    
    @objc class func applicationDocumentsDirectory() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: lookupAppGroup()!)
    }
}
