//
//  LaunchModule.swift
//  Mobile
//
//  Created by Bret Hansen on 8/23/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import CoreData

@objc(LaunchModule)
class LaunchModule: NSManagedObject {
    static let launchModuleEntityName = "LaunchModule"
    
    @NSManaged var moduleKey: String
    @NSManaged var muteNotification: Bool
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<LaunchModule> {
        return NSFetchRequest<LaunchModule>(entityName: LaunchModule.launchModuleEntityName);
    }
    
    override var hashValue: Int {
        get {
            return moduleKey.hashValue
        }
    }
    
    @nonobjc static func ==(lhs: LaunchModule, rhs: LaunchModule) -> Bool {
        return lhs.moduleKey == rhs.moduleKey
    }

    override var debugDescription: String {
        get {
            return "moduleKey: \(moduleKey) muteNotification: \(muteNotification)"
        }
    }
}
