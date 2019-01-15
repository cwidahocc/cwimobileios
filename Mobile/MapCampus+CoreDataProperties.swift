//
//  MapCampus+CoreDataProperties.swift
//  Mobile
//
//  Created by Jason Hocker on 8/22/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import CoreData

extension MapCampus {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MapCampus> {
        return NSFetchRequest<MapCampus>(entityName: "MapCampus");
    }

    @NSManaged public var campusId: String?
    @NSManaged public var centerLatitude: NSNumber?
    @NSManaged public var centerLongitude: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var spanLatitude: NSNumber?
    @NSManaged public var spanLongitude: NSNumber?
    @NSManaged public var map: Map?
    @NSManaged public var points: NSSet?

}

// MARK: Generated accessors for points
extension MapCampus {

    @objc(addPointsObject:)
    @NSManaged public func addToPoints(_ value: MapPOI)

    @objc(removePointsObject:)
    @NSManaged public func removeFromPoints(_ value: MapPOI)

    @objc(addPoints:)
    @NSManaged public func addToPoints(_ values: NSSet)

    @objc(removePoints:)
    @NSManaged public func removeFromPoints(_ values: NSSet)

}
