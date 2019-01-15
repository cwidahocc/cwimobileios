//
//  NotificationsSplitViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/13/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class NotificationsSplitViewController : UISplitViewController, UISplitViewControllerDelegate {
    
    @objc var uuid : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        let navigationController = self.viewControllers[self.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = self.displayModeButtonItem
        navigationController.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        self.view.setNeedsLayout()
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if let secondaryViewController = secondaryViewController as? UINavigationController {
            let childViewController = secondaryViewController.childViewControllers[0]
            if childViewController is NotificationsDetailViewController {
                return false;
            }
        }
        return true;
    }
}
