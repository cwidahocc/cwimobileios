//
//  LoginProtocol.swift
//  Mobile
//
//  Created by Jason Hocker on 5/17/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

protocol LoginProtocol {
        
    var completionBlock: (() -> Void)? {get set}
    
}