//
//  LoginSignOutOperation.swift
//  Mobile
//
//  Created by Jason Hocker on 6/29/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class LoginSignOutOperation: Operation {

    override func main() {
        CurrentUser.sharedInstance.logout( true)
        NotificationCenter.default.post(name: CurrentUser.SignInReturnToHomeNotification, object: nil)
    }
}
