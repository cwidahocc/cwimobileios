//
//  OpenModuleHomeOperation.swift
//  Mobile
//
//  Created by Jason Hocker on 6/25/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class OpenModuleHomeOperation: OpenModuleAbstractOperation {

    override func main() {
        DispatchQueue.main.async(execute: {
            
            let storyboard = UIStoryboard(name: "HomeStoryboard", bundle: nil)
            let navController = storyboard.instantiateViewController(withIdentifier: "LandingPage") as! UINavigationController
            let controller = navController.childViewControllers[0] as! HomeViewController
            self.showViewController(controller)
        })

    }
}
