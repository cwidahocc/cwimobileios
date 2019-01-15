//
//  MapPOI+CoreDataProperties.swift
//  Mobile
//
//  Created by Jason Hocker on 8/22/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import CoreData

extension MapPOI {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MapPOI> {
        return NSFetchRequest<MapPOI>(entityName: "MapPOI");
    }

    @NSManaged public var additionalServices: String?
    @NSManaged public var address: String?
    @NSManaged public var buildingId: String?
    @NSManaged public var description_: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var key: String?
    @NSManaged public var latitude: NSNumber?
    @NSManaged public var longitude: NSNumber?
    @NSManaged public var moduleInternalKey: String?
    @NSManaged public var name: String?
    @NSManaged public var campus: MapCampus?
    @NSManaged public var types: NSSet?

}

// MARK: Generated accessors for types
extension MapPOI {

    @objc(addTypesObject:)
    @NSManaged public func addToTypes(_ value: MapPOIType)

    @objc(removeTypesObject:)
    @NSManaged public func removeFromTypes(_ value: MapPOIType)

    @objc(addTypes:)
    @NSManaged public func addToTypes(_ values: NSSet)

    @objc(removeTypes:)
    @NSManaged public func removeFromTypes(_ values: NSSet)

}
