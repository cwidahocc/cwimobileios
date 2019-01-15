//
//  AboutPageController.swift
//  Mobile
//
//  Created by Jason Hocker on 4/26/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import WatchKit
import Foundation
import CoreData


class AboutPageController: WKInterfaceController {

    @IBOutlet var phoneLabel: WKInterfaceLabel!
    @IBOutlet var emailLabel: WKInterfaceLabel!
    @IBOutlet var websiteLabel: WKInterfaceLabel!

    @IBOutlet var contactButton: WKInterfaceButton!
    @IBOutlet var privacyButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        let defaults = AppGroupUtilities .userDefaults()
        if let phoneNumber : String = defaults?.string(forKey: "about-phone-number"), !phoneNumber.isEmpty  {
            phoneLabel.setText(phoneNumber)
        } else {
            phoneLabel.setHidden(true)
        }
        if let email : String = defaults?.string(forKey: "about-email-address"), !email.isEmpty {
            emailLabel.setText(email)
        } else {
            emailLabel.setHidden(true)
        }
        if let web : String = defaults?.string(forKey: "about-website-url"), !web.isEmpty  {
            websiteLabel.setText(web)
        } else {
            websiteLabel.setHidden(true)
        }
        
        if let contact : String = defaults?.string(forKey: "about-contact"), !contact.isEmpty {
            contactButton.setHidden(false)
        } else {
            contactButton.setHidden(true)
        }
        
        if let privacy : String = defaults?.string(forKey: "about-privacy-url"), !privacy.isEmpty {
            privacyButton.setHidden(false)
        } else {
            privacyButton.setHidden(true)
        }

    }
}
