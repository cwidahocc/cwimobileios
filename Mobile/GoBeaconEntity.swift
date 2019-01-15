//
//  GoBeaconEntity.swift
//  Mobile
//
//  Created by Bret Hansen on 7/28/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import CoreData

@objc(GoBeaconEntity)
class GoBeaconEntity: NSManagedObject {
    static let goBeaconEntityName = "GoBeacon"

    @nonobjc class func fetchRequest() -> NSFetchRequest<GoBeaconEntity> {
        return NSFetchRequest<GoBeaconEntity>(entityName: GoBeaconEntity.goBeaconEntityName);
    }
    
    @NSManaged var uuid: String
    @NSManaged var major: Int16
    @NSManaged var minor: Int16
    @NSManaged var triggerDistance: String

    func id() -> String {
        return BeaconManager.beaconId(uuidString: uuid, major: major, minor: minor)
    }
    
    override var hashValue: Int {
        get {
            return id().hashValue
        }
    }
    
    @nonobjc static func ==(lhs: GoBeaconEntity, rhs: GoBeaconEntity) -> Bool {
        return lhs.id() == rhs.id()
    }

    override var debugDescription: String {
        get {
            return "uuid: \(uuid) major: \(major) minor: \(minor) triggerDistance: \(triggerDistance)"
        }
    }
}
