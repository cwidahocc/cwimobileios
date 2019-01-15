//
//  WebViewControllerProtocol.swift
//  Mobile
//
//  Created by Jason Hocker on 2/24/17.
//  Copyright © 2017 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

protocol WebViewControllerProtocol {
    var module : Module? { get set }
    var loadRequest : URLRequest? { get set }
    var secure : Bool { get set }
    var analyticsLabel : String? { get set }
    var title: String? { get set }

}
