//
//  UIButtonExtensions.swift
//  Mobile
//
//  Created by Jason Hocker on 8/5/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

extension UIButton {
    
    func addBorderAndColor() {
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = UIColor.primary.cgColor
        tintColor = UIColor.primary
        contentEdgeInsets = UIEdgeInsetsMake(4, 8, 4, 8)
    }
}
