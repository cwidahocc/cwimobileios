//
//  NSDate-TimeAgo.swift
//  Mobile
//
//  Created by Jason Hocker on 7/31/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

let kMinute = 60
let kDay = kMinute * 24
let kWeek = kDay * 7
let kMonth = kDay * 31
let kYear = kDay * 365

extension Date {
    
    // shows 1 or two letter abbreviation for units.
    // does not include 'ago' text ... just {value}{unit-abbreviation}
    // does not include interim summary options such as 'Just now'
    var timeAgoSimple: String {
        
        let now = Date()
        let deltaSeconds = Int(fabs(timeIntervalSince(now)))
        let deltaMinutes = deltaSeconds / 60
        
        var value: Int!
        
        if deltaSeconds < kMinute {
            // Seconds
            return String(format: NSLocalizedString("%ds", tableName: "NSDateTimeAgo", comment: "{value}s for seconds"), deltaSeconds)
        } else if deltaMinutes < kMinute {
            // Minutes
            return String(format: NSLocalizedString("%dm", tableName: "NSDateTimeAgo", comment: "{value}m for minutes"), deltaMinutes)
        } else if deltaMinutes < kDay {
            // Hours
            value = Int(floor(Float(deltaMinutes / kMinute)))
            return String(format: NSLocalizedString("%dh", tableName: "NSDateTimeAgo", comment: "{value}h for hours"), value)
        } else if deltaMinutes < kWeek {
            // Days
            value = Int(floor(Float(deltaMinutes / kDay)))
            return String(format: NSLocalizedString("%dd", tableName: "NSDateTimeAgo", comment: "{value}d for days"), value)
        } else if deltaMinutes < kMonth {
            // Weeks
            value = Int(floor(Float(deltaMinutes / kWeek)))
            return String(format: NSLocalizedString("%dw", tableName: "NSDateTimeAgo", comment: "{value}w for weeks"), value)
        } else if deltaMinutes < kYear {
            // Month
            value = Int(floor(Float(deltaMinutes / kMonth)))
            return String(format: NSLocalizedString("%dmo", tableName: "NSDateTimeAgo", comment: "{value}m for months"), value)
        } else {
            // Years
            value = Int(floor(Float(deltaMinutes / kYear)))
            return String(format: NSLocalizedString("%dyr", tableName: "NSDateTimeAgo", comment: "{value}y for years"), value)
        }
    }
    
    var timeAgo: String {
        
        let now = Date()
        let deltaSeconds = Int(fabs(timeIntervalSince(now)))
        let deltaMinutes = deltaSeconds / 60
        
        var value: Int!
        
        if deltaSeconds < 5 {
            // Just Now
            return NSLocalizedString("Just now", tableName: "NSDateTimeAgo", comment: "Just now")
        } else if deltaSeconds < kMinute {
            // Seconds Ago
            return String(format: NSLocalizedString("%d seconds ago", tableName: "NSDateTimeAgo", comment: "%d seconds ago"), deltaSeconds)
        } else if deltaSeconds < 120 {
            // A Minute Ago
            return NSLocalizedString("A minute ago", tableName: "NSDateTimeAgo", comment: "A minute ago")
        } else if deltaMinutes < kMinute {
            // Minutes Ago
            return String(format: NSLocalizedString("%d minutes ago", tableName: "NSDateTimeAgo", comment: "%d minutes ago"), deltaMinutes)
        } else if deltaMinutes < 120 {
            // An Hour Ago
            return NSLocalizedString("An hour ago", tableName: "NSDateTimeAgo", comment: "An hour ago")
        } else if deltaMinutes < kDay {
            // Hours Ago
            value = Int(floor(Float(deltaMinutes / kMinute)))
            return String(format: NSLocalizedString("%d hours ago", tableName: "NSDateTimeAgo", comment: "%d hours ago"), value)
        } else if deltaMinutes < (kDay * 2) {
            // Yesterday
            return NSLocalizedString("Yesterday", tableName: "NSDateTimeAgo", comment: "Yesterday")
        } else if deltaMinutes < kWeek {
            // Days Ago
            value = Int(floor(Float(deltaMinutes / kDay)))
            return String(format: NSLocalizedString("%d days ago", tableName: "NSDateTimeAgo", comment: "%d days ago"), value)
        } else if deltaMinutes < (kWeek * 2) {
            // Last Week
            return NSLocalizedString("Last week", tableName: "NSDateTimeAgo", comment: "Last week")
        } else if deltaMinutes < kMonth {
            // Weeks Ago
            value = Int(floor(Float(deltaMinutes / kWeek)))
            return String(format: NSLocalizedString("%d weeks ago", tableName: "NSDateTimeAgo", comment: "%d weeks ago"), value)
        } else if deltaMinutes < (kDay * 61) {
            // Last month
            return NSLocalizedString("Last month", tableName: "NSDateTimeAgo", comment: "Last month")
        } else if deltaMinutes < kYear {
            // Month Ago
            value = Int(floor(Float(deltaMinutes / kMonth)))
            return String(format: NSLocalizedString("%d months ago", tableName: "NSDateTimeAgo", comment: "%d months ago"), value)
        } else if deltaMinutes < (kDay * (kYear * 2)) {
            // Last Year
            return NSLocalizedString("Last Year", tableName: "NSDateTimeAgo", comment: "Last Year")
        } else {
            // Years Ago
            value = Int(floor(Float(deltaMinutes / kYear)))
            return String(format: NSLocalizedString("%d years ago", tableName: "NSDateTimeAgo", comment: "%d years ago"), value)
        }
    }
}
