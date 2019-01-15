//
//  DirectoryUnmanagedDefinition.swift
//  Mobile
//
//  Created by Jason Hocker on 2/9/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

@objc protocol DirectoryDefinitionProtocol {
    
    var authenticatedOnly: Bool { get set }
    var displayName: String? { get set }
    var internalName: String? { get set }
    var key: String? { get set }
    
}

@objc class DirectoryUnmanagedDefinition : NSObject, DirectoryDefinitionProtocol {
    
    override init() {
        authenticatedOnly = false
    }
    var authenticatedOnly: Bool
    var displayName: String?
    var internalName: String?
    var key: String?
}
