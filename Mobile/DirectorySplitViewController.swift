//
//  DirectorySplitViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 12/2/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class DirectorySplitViewController  : UISplitViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
//        let navigationController = self.viewControllers[self.viewControllers.count-1] as! UINavigationController
//        navigationController.topViewController!.navigationItem.leftBarButtonItem = self.displayModeButtonItem()
//        navigationController.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        self.view.setNeedsLayout()
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if let secondaryViewController = secondaryViewController as? UINavigationController {
            let childViewController = secondaryViewController.childViewControllers[0]
            if childViewController is FeedDetailViewController {
                return false;
            }
        }
        return true;
    }
    
    override func revealMenu(_ sender: AnyObject) {
        let navigationViewController = self.childViewControllers[0] as! UINavigationController
        let masterController = navigationViewController.childViewControllers[0] as! DirectoryViewController
        masterController.searchBar?.resignFirstResponder()
        super.revealMenu(sender)
    }
}
