//
//  DirectoryDefinition+CoreDataProperties.swift
//  Mobile
//
//  Created by Jason Hocker on 2/5/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension DirectoryDefinition {

    @NSManaged var authenticatedOnly: Bool
    @NSManaged var displayName: String?
    @NSManaged var internalName: String?
    @NSManaged var key: String?

}
