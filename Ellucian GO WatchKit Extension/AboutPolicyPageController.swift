//
//  AboutPolicyPageController.swift
//  Mobile
//
//  Created by Jason Hocker on 4/26/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import WatchKit
import Foundation
import CoreData


class AboutPolicyPageController: WKInterfaceController {
    
    @IBOutlet var policyLabelLabel: WKInterfaceLabel!
    @IBOutlet var policyLabel: WKInterfaceLabel!
    override func awake(withContext context: Any?) {
        let defaults = AppGroupUtilities.userDefaults()
        self.policyLabelLabel.setText(defaults?.string(forKey: "about-privacy-display"))
        self.policyLabel.setText(defaults?.string(forKey: "about-privacy-url"))
    }
}
