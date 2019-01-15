//
//  ILPAllItemsViewControllerProtocol.swift
//  Ellucian GO
//
//  Created by Jason Hocker on 8/28/17.
//  Copyright © 2017 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

protocol ILPAllItemsViewControllerProtocol {

    var myManagedObjectContext: NSManagedObjectContext! { get set }
    var myTabBarController: UITabBarController! { get set }
    var module: Module! { get set }

}
