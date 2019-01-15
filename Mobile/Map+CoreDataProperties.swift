//
//  Map+CoreDataProperties.swift
//  Mobile
//
//  Created by Jason Hocker on 8/22/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import CoreData

extension Map {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Map> {
        return NSFetchRequest<Map>(entityName: "Map");
    }

    @NSManaged public var moduleName: String?
    @NSManaged public var campuses: NSSet?

}

// MARK: Generated accessors for campuses
extension Map {

    @objc(addCampusesObject:)
    @NSManaged public func addToCampuses(_ value: MapCampus)

    @objc(removeCampusesObject:)
    @NSManaged public func removeFromCampuses(_ value: MapCampus)

    @objc(addCampuses:)
    @NSManaged public func addToCampuses(_ values: NSSet)

    @objc(removeCampuses:)
    @NSManaged public func removeFromCampuses(_ values: NSSet)

}
