//
//  AboutContactPageController.swift
//  Mobile
//
//  Created by Jason Hocker on 4/26/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import WatchKit
import Foundation
import CoreData


class AboutContactPageController: WKInterfaceController {
    
    @IBOutlet var contactLabel: WKInterfaceLabel!
    override func awake(withContext context: Any?) {
        self.contactLabel.setText(AppGroupUtilities.userDefaults()?.string(forKey: "about-contact"))
    }
}
