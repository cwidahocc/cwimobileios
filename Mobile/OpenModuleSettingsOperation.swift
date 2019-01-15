//
//  OpenModuleHomeOperation.swift
//  Mobile
//
//  Created by Jason Hocker on 6/25/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class OpenModuleSettingsOperation: OpenModuleAbstractOperation {

    override func main() {
        DispatchQueue.main.async(execute: {
            let slidingViewController = self.findSlidingViewController()
            slidingViewController.resetTopView(animated: true)
            UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        })

    }
}
