//
//  LaunchBeaconEntity.swift
//  Mobile
//
//  Created by Bret Hansen on 7/28/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import CoreData

@objc(LaunchBeaconEntity)
class LaunchBeaconEntity: GoBeaconEntity {
    static let launchBeaconEntityName = "LaunchBeacon"
    
    @NSManaged var moduleKey: String
    @NSManaged var message: String?
    
    @nonobjc class func fetchRequest() -> NSFetchRequest<LaunchBeaconEntity> {
        return NSFetchRequest<LaunchBeaconEntity>(entityName: LaunchBeaconEntity.launchBeaconEntityName);
    }
    
//    override var hashValue: Int {
//        get {
//            return moduleKey.hashValue
//        }
//    }
    
    @nonobjc static func ==(lhs: LaunchBeaconEntity, rhs: LaunchBeaconEntity) -> Bool {
        return lhs.moduleKey == rhs.moduleKey
    }

    override var debugDescription: String {
        get {
            var description = "uuid: \(uuid) major: \(major) minor: \(minor) triggerDistance: \(triggerDistance) moduleKey: \(moduleKey)"
            if let message = message {
                description += " message: \(message)"
            }
            return description
        }
    }
}
