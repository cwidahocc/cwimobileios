//
//  SlidingViewExtensions.swift
//  Mobile
//
//  Created by Jason Hocker on 7/13/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

extension UIViewController {
    
    @nonobjc static let SlidingViewOpenMenuAppearsNotification = NSNotification.Name("SlidingViewOpenMenuAppearsNotification")
    @nonobjc static let SlidingViewTopResetNotification = NSNotification.Name("SlidingViewTopResetNotification")
    @nonobjc static let SlidingViewChangeTopControllerNotification = NSNotification.Name("SlidingViewChangeTopControllerNotification")

    
    @IBAction func revealMenu(_ sender: AnyObject) {
        
        if let menu = self.slidingViewController().underLeftViewController as? UITableViewController {
            UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, menu.tableView)
            
            if let defaults = AppGroupUtilities.userDefaults() {
                defaults.set(true, forKey: "menu-discovered") //used when home screen used to have coach text
            }
            
            self.sendEventToTracker1(category: .ui_Action, action: .button_Press, label: "Click Menu Tray Icon", moduleName: nil)
            
        }
        
        let direction = UIView.userInterfaceLayoutDirection(for: self.view.semanticContentAttribute)
        if direction == .rightToLeft {
            self.slidingViewController().anchorTopViewToLeft(animated: true)
        }
        else {
            self.slidingViewController().anchorTopViewToRight(animated: true)
        }
        //TODO remove after soft-deprecated popovers removed
        if let splitViewController = self as? UISplitViewController {
            if let detailNavController = splitViewController.viewControllers[1] as? UINavigationController {
                if let detailController = detailNavController.topViewController {
                    if detailController.responds(to: #selector(DetailSelectionDelegate.dismissMasterPopover)) {
                        if let vc = detailController as? DetailSelectionDelegate {
                            vc.dismissMasterPopover!()
                        }
                    }
                }
            }
        }
    }
}
