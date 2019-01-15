//
//  OpenModuleAbstractOperation.swift
//  Mobile
//
//  Created by Jason Hocker on 6/25/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class OpenModuleAbstractOperation: Operation {

    var performAnimation = false

    func showViewController(_ controller: UIViewController) {

        let slidingViewController = findSlidingViewController()

        var controllerToShow = controller
        switch controller {
        case is UINavigationController:
            let navigationController = controller as! UINavigationController
            addMenuButton(navigationController.topViewController)
            controllerToShow = controller
        case is UITabBarController:
            let tabBarController = controller as! UITabBarController
            if let viewControllers = tabBarController.viewControllers {
                for c in viewControllers {
                    switch c {
                    case is UISplitViewController:
                        let splitViewController = c as! UISplitViewController
                        let navController = splitViewController.viewControllers[0] as! UINavigationController
                        let masterController = navController.topViewController!

                        if let masterController = masterController as? UISplitViewControllerDelegate {
                            splitViewController.delegate = masterController

                        }
                        if masterController.responds(to: #selector(UIViewController.revealMenu(_:))) {
                            addMenuButton(masterController)
                        }
                    case is UINavigationController:
                        let navigationController = c as! UINavigationController
                        addMenuButton(navigationController.topViewController)

                    default:
                        ()
                    }
                }
            }
            controllerToShow = controller
        case is UISplitViewController:
            let splitViewController = controller as! UISplitViewController
            splitViewController.presentsWithGesture = true

            var masterController = splitViewController.viewControllers[0]
            if masterController is UINavigationController {
                let navMasterController = masterController as! UINavigationController
                masterController = navMasterController.topViewController!
            }

            var detailController = splitViewController.viewControllers[1]
            if detailController is UINavigationController {
                let navDetailController = detailController as! UINavigationController
                detailController = navDetailController.topViewController!
            }


            if let masterController = masterController as? UISplitViewControllerDelegate {
                splitViewController.delegate = masterController

            }
            if let detailController = detailController as? UISplitViewControllerDelegate {
                splitViewController.delegate = detailController
            }
            if let detailController = detailController as? DetailSelectionDelegate {
                if let masterController = masterController as? MasterWithDetailSelectionDelegateProtocol {
                    masterController.detailSelectionDelegate = detailController;
                }
            }
            addMenuButton(masterController)

            controllerToShow = controller

        default:
            let navigationController = UINavigationController(rootViewController: controller)
            addMenuButton(controllerToShow)
            controllerToShow = navigationController
        }

        if let panGesture = slidingViewController.panGesture {
            controllerToShow.view.addGestureRecognizer(panGesture)
        }

        DispatchQueue.main.async(execute: {

            if self.performAnimation {
                let transition = CATransition()
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromRight
                transition.duration = 0.5
                transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
                transition.fillMode = kCAFillModeRemoved
                let slidingViewController = self.findSlidingViewController()
                slidingViewController.topViewController.view.window?.layer.add(transition, forKey: "transition")
            }

            let segue = ECSlidingSegue(identifier: "", source: slidingViewController.topViewController, destination: controllerToShow)
            slidingViewController.topViewController.prepare(for: segue, sender: nil)
            segue.perform()
        })


    }

    func findSlidingViewController() -> ECSlidingViewController {

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.slidingViewController!
    }

    private func addMenuButton(_ controller: UIViewController?) {
        if let controller = controller , controller.responds(to: #selector(UIViewController.revealMenu(_:))) {

            var buttonImage = UIImage(named: "icon-menu-iphone")

            //exception for home screens
            if controller is HomeViewController {
                buttonImage = UIImage(named: "home-menu-icon")
            }

            buttonImage?.isAccessibilityElement = false

            let button = UIBarButtonItem(image: buttonImage, style: UIBarButtonItemStyle.plain, target: controller, action:#selector(UIViewController.revealMenu(_:)))
            button.accessibilityLabel = NSLocalizedString("Menu", comment: "Accessibility menu label")
            controller.navigationItem.leftBarButtonItem = button
        }
    }
}
