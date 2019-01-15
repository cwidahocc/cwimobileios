//
//  SectionHeaderViewDelegate.swift
//  Mobile
//
//  Created by Jason Hocker on 7/13/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

@objc protocol SectionHeaderViewDelegate {
    
    @objc optional func sectionHeaderView(_ sectionHeaderView: MenuTableViewHeaderFooterView, sectionOpened: Int)
    @objc optional func sectionHeaderView(_ sectionHeaderView: MenuTableViewHeaderFooterView, sectionClosed: Int)

}
