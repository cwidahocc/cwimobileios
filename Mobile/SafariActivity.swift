//
//  SafariActivity.swift
//  Mobile
//
//  Created by Jason Hocker on 8/5/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class SafariActivity : UIActivity {
    
    var targetURL : URL?
    
    //TODO Xcode 8 beta 6 hack http://stackoverflow.com/questions/39075442/uiactivitytype-property-cannot-be-an-objc-override-because-its-type-cannot-be
//    https://bugs.swift.org/browse/SR-2344
    override open var activityType: UIActivityType {
        get {
            return UIActivityType(rawValue: "SafariActivity")
        }
    }
    override public var activityTitle: String? {
        return NSLocalizedString("Open in Safari", comment: "label to open link in Safari")
    }
    
    override public var activityImage: UIImage? {
        return UIImage(named:"icon_website")
    }
    
    override public class var activityCategory: UIActivityCategory { return .action }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let _ = item as? URL {
                return true
            }
            if let urlString = item as? String {
                if let url = URL(string: urlString) {
                    if UIApplication.shared.canOpenURL(url) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let url = item as? URL {
                targetURL = url
            } else if let urlString = item as? String, let url = URL(string:urlString) {
                targetURL = url
            }
        }
    }
    
    override func perform() {
        if let targetURL = targetURL {
            UIApplication.shared.open(targetURL, options: [:], completionHandler: {
                (success) in
                self.activityDidFinish(success)
            })
        } else {
            activityDidFinish(false)
        }
    }
}
