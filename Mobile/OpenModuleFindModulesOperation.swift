//
//  OpenModuleFindModulesOperation.swift
//  Mobile
//
//  Created by Jason Hocker on 6/29/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class OpenModuleFindModulesOperation: OpenModuleAbstractOperation {

    var modules = [Module]()
    var limitToHomeScreen = false
    
    override func main() {
        self.modules = ModuleManager.findUserModules(limitToHomeScreen: limitToHomeScreen)
    }
    
}
