//
//  LoginSignInOperation.swift
//  Mobile
//
//  Created by Jason Hocker on 6/29/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class LoginSignInOperation: Operation {
    
    let controller: UIViewController
    var successCompletionHandler :  (() -> Void)?

    init(controller: UIViewController) {
        self.controller = controller
    }
    
    override func main() {
        LoginExecutor.doLogin(controller, successCompletionHandler: successCompletionHandler)
    }
}
