//
//  NotificationsEmptyViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/19/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class NotificationsEmptyViewController : UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.topViewController?.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        self.navigationController?.topViewController?.navigationItem.leftItemsSupplementBackButton = true
    }
}
