//
//  NotificationUIActivityItemProvider.swift
//  Mobile
//
//  Created by Jason Hocker on 8/19/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation


class NotificationUIActivityItemProvider : UIActivityItemProvider {
    
    let subject : String
    let text : String
    
    init(subject: String, text: String) {

        self.subject = subject
        self.text = text
        super.init(placeholderItem: subject)
    }
    
    override public var item: Any { return text }
    
    @nonobjc
    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        if activityType == .mail {
            return subject
        } else {
            return ""
        }
    }
}
