//
//  GoogleAnalyticsExtensions.swift
//  Mobile
//
//  Created by Jason Hocker on 7/12/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

extension UIViewController {

    @objc func sendView(_ screen: String, moduleName: String? = nil) {
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults() {
            var trackingIds = [String]()
            if let trackingId = defaults.string(forKey: "gaTracker1") {
                trackingIds.append(trackingId)
            }
            if let trackingId = defaults.string(forKey: "gaTracker2") {
                trackingIds.append(trackingId)
            }
            self.sendViewToGoogleAnalytics(screen: screen, moduleName: moduleName, trackingIds: trackingIds)
        }
    }
    
    @objc func sendViewToTracker1(_ screen: String, moduleName: String? = nil) {
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults() {
            var trackingIds = [String]()
            if let trackingId = defaults.string(forKey: "gaTracker1") {
                trackingIds.append(trackingId)
            }
            self.sendViewToGoogleAnalytics(screen: screen, moduleName: moduleName, trackingIds: trackingIds)
        }
    }
    
    @objc func sendViewToTracker2(_ screen: String, moduleName: String? = nil) {
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults() {
            var trackingIds = [String]()
            if let trackingId = defaults.string(forKey: "gaTracker2") {
                trackingIds.append(trackingId)
            }
            self.sendViewToGoogleAnalytics(screen: screen, moduleName: moduleName, trackingIds: trackingIds)
        }
    }
    
    private func sendViewToGoogleAnalytics(screen: String, moduleName: String? = nil, trackingIds: [String]) {

        let builder: GAIDictionaryBuilder = GAIDictionaryBuilder.createScreenView()
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults(), let configurationName = defaults.string(forKey: "configurationName") {
            builder.set(configurationName, forKey: GAIFields.customDimension(for: 1))
        }
        if let moduleName = moduleName {
            builder.set(moduleName, forKey: GAIFields.customDimension(for: 2))
        }
        builder.set(screen, forKey: kGAIScreenName)
        let buildDictionary = builder.build() as [NSObject : AnyObject]
        for trackingId in trackingIds {
            let tracker: GAITracker = GAI.sharedInstance().tracker(withTrackingId: trackingId)
            tracker.send(buildDictionary)
        }
    }
    
    func sendEvent(category: Analytics.Category, action: Analytics.Action, label: String, value: Int? = nil, moduleName: String? = nil) {
        sendEvent(category: category.rawValue, action: action.rawValue, label: label, value: value, moduleName: moduleName)
    }
    
    //objc-compatibility
//    func sendEvent(category: String, action: String, label: String, moduleName: String) {
//        sendEvent(category: category, action: action, label: label, value: value, moduleName: moduleName)
//    }

    @objc func sendEventToTracker1(category: String, action: String, label: String, moduleName: String? = nil) {
        sendEventToTracker1(category: category, action: action, label: label, value: nil, moduleName: moduleName)
    }
    @objc func sendEvent(category: String, action: String, label: String, moduleName: String? = nil) {
            sendEvent(category: category, action: action, label: label, value: nil, moduleName: moduleName)
    }
    @objc func sendEvent(category: String, action: String, label: String, value: Int, moduleName: String? = nil) {
        sendEvent(category: category, action: action, label: label, value: value, moduleName: moduleName)
    }
    
    func sendEvent(category: String, action: String, label: String, value: Int? = nil, moduleName: String? = nil) {
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults() {
            var trackingIds = [String]()
            if let trackingId = defaults.string(forKey: "gaTracker1") {
                trackingIds.append(trackingId)
            }
            if let trackingId = defaults.string(forKey: "gaTracker2") {
                trackingIds.append(trackingId)
            }
            self.sendEventToGoogleAnalytics(category: category, action: action, label: label, value: value, moduleName: moduleName, trackingIds: trackingIds)
        }
    }
    
    func sendEventToTracker1(category: Analytics.Category, action: Analytics.Action, label: String, value: Int? = nil, moduleName: String? = nil) {
        sendEventToTracker1(category: category.rawValue, action: action.rawValue, label: label, value: value, moduleName: moduleName)
    
    }
    
    func sendEventToTracker1(category: String, action: String, label: String, value: Int? = nil, moduleName: String? = nil) {
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults() {
            var trackingIds = [String]()
            if let trackingId = defaults.string(forKey: "gaTracker1") {
                trackingIds.append(trackingId)
            }
            self.sendEventToGoogleAnalytics(category: category, action: action, label: label, value: value, moduleName: moduleName, trackingIds: trackingIds)
        }
    }
    
    func sendEventToTracker2(category: String, action: String, label: String, value: Int? = nil, moduleName: String? = nil) {
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults() {
            var trackingIds = [String]()
            if let trackingId = defaults.string(forKey: "gaTracker2") {
                trackingIds.append(trackingId)
            }
            self.sendEventToGoogleAnalytics(category: category, action: action, label: label, value: value, moduleName: moduleName, trackingIds: trackingIds)
        }
    }
    
    private func sendEventToGoogleAnalytics(category: String, action: String, label: String, value: Int? = nil, moduleName: String? = nil, trackingIds: [String]) {
        let builder: GAIDictionaryBuilder = GAIDictionaryBuilder.createEvent(withCategory: category, action: action, label: label, value: value as NSNumber?)
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults(), let configurationName = defaults.string(forKey: "configurationName") {
            builder.set(configurationName, forKey: GAIFields.customDimension(for: 1))
        }
        if let moduleName = moduleName {
            builder.set(moduleName, forKey: GAIFields.customDimension(for: 2))
        }

        let buildDictionary = builder.build() as [NSObject : AnyObject]
        for trackingId in trackingIds {
            let tracker: GAITracker = GAI.sharedInstance().tracker(withTrackingId: trackingId)
            tracker.send(buildDictionary)
        }
    }
    
    func sendUserTiming(category: Analytics.Category, time: TimeInterval, name: String, label: String?, moduleName: String? = nil) {
        sendUserTiming(category: category.rawValue, time: time, name: name, label: label, moduleName: moduleName)
    }
    
    @objc func sendUserTiming(category: String, time: TimeInterval, name: String, label: String?, moduleName: String? = nil) {
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults() {
            var trackingIds = [String]()
            if let trackingId = defaults.string(forKey: "gaTracker1") {
                trackingIds.append(trackingId)
            }
            if let trackingId = defaults.string(forKey: "gaTracker2") {
                trackingIds.append(trackingId)
            }
            self.sendUserTimingToGoogleAnalytics(category: category, time: time, name: name, label: label, moduleName: moduleName, trackingIds: trackingIds)
        }
    }
    
    @objc func sendUserTimingToTracker1(category: String, time: TimeInterval, name: String, label: String?, moduleName: String? = nil) {
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults() {
            var trackingIds = [String]()
            if let trackingId = defaults.string(forKey: "gaTracker1") {
                trackingIds.append(trackingId)
            }
            self.sendUserTimingToGoogleAnalytics(category: category, time: time, name: name, label: label, moduleName: moduleName, trackingIds: trackingIds)
        }
    }
    
    @objc func sendUserTimingToTracker2(category: String, time: TimeInterval, name: String, label: String?, moduleName: String? = nil) {
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults() {
            var trackingIds = [String]()
            if let trackingId = defaults.string(forKey: "gaTracker2") {
                trackingIds.append(trackingId)
            }
            self.sendUserTimingToGoogleAnalytics(category: category, time: time, name: name, label: label, moduleName: moduleName, trackingIds: trackingIds)
        }
    }

    private func sendUserTimingToGoogleAnalytics(category: String?, time: TimeInterval, name: String, label: String?, moduleName: String? = nil, trackingIds: [String]) {
        let interval = time * 1000
        let builder: GAIDictionaryBuilder = GAIDictionaryBuilder.createTiming(withCategory: category, interval: interval as NSNumber, name: name, label: label)
        if let defaults: UserDefaults = AppGroupUtilities.userDefaults(), let configurationName = defaults.string(forKey: "configurationName") {
            builder.set(configurationName, forKey: GAIFields.customDimension(for: 1))
        }
        if let moduleName = moduleName {
            builder.set(moduleName, forKey: GAIFields.customDimension(for: 2))
        }
        
        let buildDictionary = builder.build() as [NSObject : AnyObject]
        for trackingId in trackingIds {
            let tracker: GAITracker = GAI.sharedInstance().tracker(withTrackingId: trackingId)
            tracker.send(buildDictionary)
        }
    }
    
}
