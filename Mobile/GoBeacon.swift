//
//  GoBeacon.swift
//  Mobile
//
//  Created by Bret Hansen on 7/28/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class GoBeacon: NSObject {

    var source: String?
    var uuid: String
    var major: Int16
    var minor: Int16
    var triggerDistance: String
    
    init(goBeaconEntity: GoBeaconEntity) {
        source = LaunchBeaconManager.sourceName
        uuid = goBeaconEntity.uuid
        major = goBeaconEntity.major
        minor = goBeaconEntity.minor
        triggerDistance = goBeaconEntity.triggerDistance
    }
    
    init(uuid: String, major: Int16, minor: Int16, triggerDistance: String) {
        self.uuid = uuid
        self.major = major
        self.minor = minor
        self.triggerDistance = triggerDistance
    }

    func id() -> String {
        return BeaconManager.beaconId(uuidString: uuid, major: major, minor: minor)
    }
    
//    override var hashValue: Int {
//        get {
//            return id().hashValue
//        }
//    }
    
    @nonobjc static func ==(lhs: GoBeacon, rhs: GoBeacon) -> Bool {
        return lhs.id() == rhs.id()
    }

    override var debugDescription: String {
        get {
            var description = "uuid: \(uuid) major: \(major) minor: \(minor) triggerDistance: \(triggerDistance)"
            if let source = source {
                description += " source: \(source)"
            }
            return description
        }
    }
}
