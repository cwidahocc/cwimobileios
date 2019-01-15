//
//  EllucianNotification+CoreDataProperties.swift
//  Mobile
//
//  Created by Jason Hocker on 8/23/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import CoreData

extension EllucianNotification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EllucianNotification> {
        return NSFetchRequest<EllucianNotification>(entityName: "Notification");
    }

    @NSManaged public var hyperlink: String?
    @NSManaged public var linkLabel: String?
    @NSManaged public var noticeDate: NSDate?
    @NSManaged public var notificationDescription: String?
    @NSManaged public var notificationId: String?
    @NSManaged public var read: NSNumber?
    @NSManaged public var sticky: NSNumber?
    @NSManaged public var title: String?

}
