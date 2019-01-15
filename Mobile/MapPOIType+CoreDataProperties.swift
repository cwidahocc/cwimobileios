//
//  MapPOIType+CoreDataProperties.swift
//  Mobile
//
//  Created by Jason Hocker on 8/22/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import CoreData

extension MapPOIType {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MapPOIType> {
        return NSFetchRequest<MapPOIType>(entityName: "MapPOIType");
    }

    @NSManaged public var moduleInternalKey: String?
    @NSManaged public var name: String?
    @NSManaged public var pointsOfInterest: NSSet?

}

// MARK: Generated accessors for pointsOfInterest
extension MapPOIType {

    @objc(addPointsOfInterestObject:)
    @NSManaged public func addToPointsOfInterest(_ value: MapPOI)

    @objc(removePointsOfInterestObject:)
    @NSManaged public func removeFromPointsOfInterest(_ value: MapPOI)

    @objc(addPointsOfInterest:)
    @NSManaged public func addToPointsOfInterest(_ values: NSSet)

    @objc(removePointsOfInterest:)
    @NSManaged public func removeFromPointsOfInterest(_ values: NSSet)

}
