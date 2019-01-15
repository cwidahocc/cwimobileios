//
//  OpenModuleAboutOperation.swift
//  Mobile
//
//  Created by Jason Hocker on 6/26/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class OpenModuleAboutOperation: OpenModuleAbstractOperation {

    override func main() {
        let storyboard = UIStoryboard(name: "AboutStoryboard", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "About") as! AboutViewController
        controller.title = NSLocalizedString("About", comment: "About menu item")
        showViewController(controller)
    }
}
