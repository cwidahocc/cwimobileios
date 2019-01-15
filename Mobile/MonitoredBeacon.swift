//
//  MonitoredBeacon.swift
//  Mobile
//
//  Created by Bret Hansen on 7/30/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class MonitoredBeacon: NSObject {
    var goBeacon: GoBeacon
    var inRegion = false
    var inRange = false
    
    init(_ beacon: GoBeacon) {
        self.goBeacon = beacon
    }
    
    func id() -> String {
        return goBeacon.id()
    }
    
    override var debugDescription: String {
        get {
            return "goBeacon: \(goBeacon.debugDescription) inRegion: \(inRegion) inRange: \(inRange)"
        }
    }
}
