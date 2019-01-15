//
//  LaunchBeaconManager.swift
//  Mobile
//
//  Created by Bret Hansen on 7/27/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import UserNotifications

class LaunchBeaconManager: NSObject {
    
    static let sourceName = "LaunchBeaconManager"
    private static let notificationCategory = "LaunchBeaconCategory"
    static let notificationMuteForeverActionId = "LaunchBeaconMuteAction"
    static let notificationMuteForTodayActionId = "LaunchBeaconMuteForTodayAction"
    static let notificationViewActionId = "LaunchBeaconViewAction"
    private static let notificationDefaultActionId = "LaunchBeaconDefaultAction"
    
    static let closeToTimeInterval:TimeInterval = 20
    static let fiveMinuteInterval:TimeInterval = 60*5 // five minutes
    static let dayInterval:TimeInterval = 60*60*24 // one day
    
    private var monitoredLaunchBeacons = [String:LaunchBeacon]()
    private var processedModuleKeys = [String]()
    
    private var started = false
    private var userNotificationSettingsIsSetup = false
    private var ios9AlertQueue = [UIAlertController]()
    
    // LaunchBeaconManager is a singleton
    static let shared = LaunchBeaconManager()
    private override init() {
        super.init()
    }
    
    class func start() {
        shared.startManager()
    }
    
    private func startManager() {
        if !started {
            
            // register for application notifications
            NotificationCenter.default.removeObserver(self)
//            NotificationCenter.default.addObserver(self, selector: #selector(didReceiveLocalNotification(_:)), name: AppDelegate.localNotification, object: nil)
            
            // register for user defaults notifications
            NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
            
            // register for configuration notifications
            NotificationCenter.default.addObserver(self, selector: #selector(configurationProcessingModulesStarted(_:)), name: ConfigurationManager.ConfigurationProcessingModulesStartedNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(configurationProcessingModule(_:)), name: ConfigurationManager.ConfigurationProcessingModuleNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(configurationLoaded(_:)), name: ConfigurationManager.ConfigurationProcessingModulesCompletedNotification, object: nil)
            
            // register for beacon notifications
            NotificationCenter.default.addObserver(self, selector: #selector(didEnterRegion(_:)), name: BeaconManager.didEnterRegion, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(didExitRegion(_:)), name: BeaconManager.didExitRegion, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(didEnterRange(_:)), name: BeaconManager.didEnterRange, object: nil)
            
            // register for Watch messages
            NotificationCenter.default.addObserver(self, selector: #selector(watchMessage(_:)), name: WatchConnectivityManager.receivedMessage, object: nil)
            
            BeaconManager.start()
            stopMonitoringForLaunchBeacons()
            
            if ConfigurationManager.shared.isConfigurationLoaded() {
                monitorLaunchBeacons()
            }
            
            started = true
        }
    }
    
    private func ensureUserNotificationSettingsSetup() {
        if !userNotificationSettingsIsSetup {
            // set up actions for location notifications
            
            
            let muteForeverAction = UNNotificationAction(identifier: LaunchBeaconManager.notificationMuteForeverActionId, title: NSLocalizedString("Mute Forever", comment: "Mute Forever label"), options: [.destructive])
            let muteForTodayAction = UNNotificationAction(identifier: LaunchBeaconManager.notificationMuteForTodayActionId, title: NSLocalizedString("Mute For Today", comment: "Mute For Today label"), options: [])
            let viewAction = UNNotificationAction(identifier: LaunchBeaconManager.notificationViewActionId, title: NSLocalizedString("View", comment: "View label"), options: [.foreground])
            
            let launchBeaconCategory = UNNotificationCategory(identifier: LaunchBeaconManager.notificationCategory, actions: [viewAction, muteForeverAction, muteForTodayAction], intentIdentifiers: [], options: [])
            
            let center = UNUserNotificationCenter.current()
            
            center.getNotificationCategories() {(categoriesIn) in
                let categories = categoriesIn
                
                // remove any category with the same identifier
                var filteredCategories = categories.filter { $0.identifier != launchBeaconCategory.identifier }
                
                // add this newly defined category
                filteredCategories.insert(launchBeaconCategory)
                
                center.setNotificationCategories(Set(filteredCategories))
            }
            
            center.delegate = NotificationManager.shared
            center.requestAuthorization(options: [.alert, .sound]) {_,_ in}
            
        }
        userNotificationSettingsIsSetup = true
    }
    
    private func notifyUser(_ launchBeacon: LaunchBeacon) {
        
        // use UserNotifications API
        let content = UNMutableNotificationContent()
        content.body = launchBeacon.message!
        content.userInfo = ["moduleKey": launchBeacon.moduleKey, "beaconId": launchBeacon.id()]
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = LaunchBeaconManager.notificationCategory
        content.threadIdentifier = LaunchBeaconManager.sourceName
        let request = UNNotificationRequest(identifier: launchBeacon.moduleKey, content: content, trigger: nil)
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.add( request, withCompletionHandler: { (error) in
            if error != nil {
                print("Error adding NotificationCenter request")
            }
        })
        print("Sent user notification for beacon: \(launchBeacon.id())")
        
        
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            rootViewController.sendEvent(category: Analytics.Category.location, action: Analytics.Action.notify, label: Analytics.Label.beaconNotify.rawValue)
        }
    }
    
    private func removeNotification(_ launchBeacon: LaunchBeacon) {
        let identifier = launchBeacon.moduleKey
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("removed UserNotification id: \(identifier)")
        
    }
    
    func openModule(_ moduleKey: String) {
        if UIApplication.shared.applicationState == .active {
            let operation: OpenModuleOperation = OpenModuleOperation(id: moduleKey)
            OperationQueue.main.addOperation(operation)
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.sendEvent(category: Analytics.Category.location, action: Analytics.Action.launch, label: Analytics.Label.beaconLaunch.rawValue)
            }
        } else {
            // tell application delegate to launch when it becomes active
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.openModuleWhenActiveModuleKey = moduleKey
            NSLog("queuing up: \(moduleKey), the app is not active")
        }
    }
    
    func markModuleMuteForever(_ moduleKey: String) {
        do {
            let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
            let fetchRequest: NSFetchRequest<LaunchModule> = LaunchModule.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "moduleKey == %@", moduleKey)
            let launchModules = try managedObjectContext.fetch(fetchRequest)
            
            if launchModules.count == 0 {
                // need to create a row
                let launchModule = NSEntityDescription.insertNewObject(forEntityName: LaunchModule.launchModuleEntityName, into: managedObjectContext) as! LaunchModule
                launchModule.moduleKey = moduleKey
                launchModule.muteNotification = true
            } else {
                for launchModule in launchModules {
                    // will be at most one, but loop makes the logic easy
                    launchModule.muteNotification = true
                }
            }
            try managedObjectContext.save()
        } catch {
            print("Failed set Module Mute Forever on launchModule using moduleKey: \(moduleKey)")
        }
        
        
        // refresh the monitored beacons
        monitorLaunchBeacons()
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            rootViewController.sendEvent(category: Analytics.Category.location, action: Analytics.Action.mute, label: Analytics.Label.beaconMuteForever.rawValue)
        }
        
    }
    
    func markBeaconMuteForToday(_ beaconId: String) {
        // mute this beacon for the day
        let defaults = UserDefaults.standard
        let key = "beacon-mute-for-today-\(beaconId)"
        let startOfDay = Calendar.current.startOfDay(for: Date())
        defaults.set(startOfDay, forKey: key)
        
        // send event to analytics
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            rootViewController.sendEvent(category: Analytics.Category.location, action: Analytics.Action.mute, label: Analytics.Label.beaconMuteForToday.rawValue)
        }
        
    }
    
    private func resetAllModulesMuted() {
        do {
            let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
            let fetchRequest: NSFetchRequest<LaunchModule> = LaunchModule.fetchRequest()
            let launchModules = try managedObjectContext.fetch(fetchRequest)
            
            for launchModule in launchModules {
                launchModule.muteNotification = false
                try managedObjectContext.save()
            }
        } catch {
            print("Failed reset all Modules Muted")
        }
        
        let defaults = UserDefaults.standard
        let defaultsDictionary = defaults.dictionaryRepresentation()
        for (key, _) in defaultsDictionary {
            if key.hasPrefix("beacon-mute-for-today-") {
                defaults.removeObject(forKey: key)
            }
        }
        
        // refresh the monitored beacons
        monitorLaunchBeacons()
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            rootViewController.sendEvent(category: Analytics.Category.location, action: Analytics.Action.resetMute, label: Analytics.Label.resetMute.rawValue)
        }
        
    }
    
    private func resetBluetoothWarningsOff() {
        if let defaults = AppGroupUtilities.userDefaults() {
            defaults.set(false, forKey: "bluetooth-off-mute-forever")
            defaults.removeObject(forKey: "bluetooth-off-last-warn")
        }
    }
    
    private func stopMonitoringForLaunchBeacons() {
        BeaconManager.shared.stopMonitoring(source: LaunchBeaconManager.sourceName)
    }
    
    private func monitorLaunchBeacons() {
        do {
            let defaults = UserDefaults.standard
            let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
            let fetchRequest: NSFetchRequest<LaunchBeaconEntity> = LaunchBeaconEntity.fetchRequest()
            
            let launchBeaconEntities = try managedObjectContext.fetch(fetchRequest)
            
            // filter any muted modules
            let beaconsToMonitorEntities = try launchBeaconEntities.filter { (launchBeacon) -> Bool in
                var include = false
                
                let fetchRequest: NSFetchRequest<LaunchModule> = LaunchModule.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "moduleKey == %@", launchBeacon.moduleKey)
                let launchModules = try managedObjectContext.fetch(fetchRequest)
                
                if launchModules.count == 0 {
                    include = true
                } else {
                    // filter out muted forever modules
                    for launchModule in launchModules {
                        // will be at most one, but loop makes the logic easy
                        include = include ? true : !launchModule.muteNotification
                    }
                }
                
                return include
            }
            
            if beaconsToMonitorEntities.count > 0 {
                ensureUserNotificationSettingsSetup()
            }
            
            // remove any existing monitored beacons from Beacon Manager
            stopMonitoringForLaunchBeacons()
            
            monitoredLaunchBeacons.removeAll()
            for launchBeaconEntity in beaconsToMonitorEntities {
                // create a LaunchBeacon for each LaunchBeaconEntity
                let launchBeacon = LaunchBeacon(launchBeaconEntity: launchBeaconEntity)
                
                monitoredLaunchBeacons[launchBeacon.moduleKey] = launchBeacon
            }
            
            // hand the LaunchBeacons to BeaconManager
            BeaconManager.shared.addBeacons(toMonitor: Array(monitoredLaunchBeacons.values))
            
            // track the time the monitoring started so that any exits are not counted for the fiveMinuteInterval
            // otherwise beacons that come into range in the first 5 minutes are ignored
            let now = Date()
            print("Asked BeaconManager to monitor beacons at: \(now)")
            defaults.set(now, forKey: "beacon-start-monitoring")
            
        } catch {
            print("Unable monitor launch beacons")
        }
    }
    
    private func queueShowAlertNotification(moduleKey: String, beaconId: String) {
        // show them an alert
        print("application active - show local notification message alert")
        
        if let launchBeacon = monitoredLaunchBeacons[moduleKey] {
            let title = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            let alert: UIAlertController = UIAlertController(title: title, message: launchBeacon.message, preferredStyle: .alert)
            let view: UIAlertAction = UIAlertAction(title: NSLocalizedString("View", comment: "View label"), style: .default, handler: {(action: UIAlertAction) -> Void in
                self.openModule(moduleKey)
                self.showNextQueuedAlertNotification()
            })
            let dismiss: UIAlertAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Dismiss label"), style: .cancel, handler: {(action: UIAlertAction) -> Void in
                alert.dismiss(animated: true, completion: nil)
                self.showNextQueuedAlertNotification()
            })
            
            // add an Mute Forever action
            let muteForever: UIAlertAction = UIAlertAction(title: NSLocalizedString("Mute Forever", comment: "Mute Forever label"), style: .default, handler: {(action: UIAlertAction) -> Void in
                self.markModuleMuteForever(moduleKey)
                self.showNextQueuedAlertNotification()
            })
            
            // add an Mute For Today action
            let muteForToday: UIAlertAction = UIAlertAction(title: NSLocalizedString("Mute For Today", comment: "Mute For Today label"), style: .default, handler: {(action: UIAlertAction) -> Void in
                self.markBeaconMuteForToday(beaconId)
                self.showNextQueuedAlertNotification()
            })
            
            alert.addAction(view)
            alert.addAction(muteForever)
            alert.addAction(muteForToday)
            alert.addAction(dismiss)
            
            DispatchQueue.main.async {
                self.ios9AlertQueue.append(alert)
                
                if self.ios9AlertQueue.count == 1 {
                    self.showNextQueuedAlertNotification()
                }
            }
        }
    }
    
    private func showNextQueuedAlertNotification() {
        DispatchQueue.main.async {
            if self.ios9AlertQueue.count > 0 {
                let alert = self.ios9AlertQueue.remove(at: 0)
                let application = UIApplication.shared
                application.delegate?.window??.makeKeyAndVisible()
                application.delegate?.window??.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // AppDelegate Notifications - iOS < 10
    
    // User Defaults Notifications
    @objc private func userDefaultsChanged(_ notification: Notification) {
        let defaults = UserDefaults.standard
        
        let resetMuted = defaults.bool(forKey: "settings-notification-reset-muted-locations")
        if resetMuted {
            // user toggled it on, reset and set it back to false
            defaults.set(false, forKey: "settings-notification-reset-muted-locations")
            
            resetBluetoothWarningsOff()
            resetAllModulesMuted()
            
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.sendEvent(category: Analytics.Category.location, action: Analytics.Action.resetMute, label: Analytics.Label.resetMute.rawValue)
            }
        }
    }
    
    // Configuration Manager Notifications
    @objc private func configurationProcessingModulesStarted(_ notification: Notification) {
        // get ready to process launch beacons
        processedModuleKeys.removeAll()
    }
    
    @objc private func configurationProcessingModule(_ notification: Notification) {
        if let data = notification.object as? LaunchBeaconDefinition {
            let moduleKey = data.moduleKey
            let moduleDictionary = data.moduleDictionary
            let managedObjectContext = data.managedObjectContext
            if let useBeaconToLaunch = moduleDictionary["useBeaconToLaunch"].string {
                if useBeaconToLaunch == "true" {
                    if let launchBeaconsJson = moduleDictionary["launchBeacons"].array {
                        for beaconJson in launchBeaconsJson {
                            var uuid: String?
                            var major: Int16?
                            var minor: Int16?
                            var distance: String?
                            var message: String?
                            
                            if let uuidString = beaconJson["uuid"].string {
                                uuid = UUID(uuidString: uuidString)?.uuidString
                            }
                            if let majorString = beaconJson["major"].string {
                                major = Int16(majorString)
                            }
                            if let minorString = beaconJson["minor"].string {
                                minor = Int16(minorString)
                            }
                            if let distanceString = beaconJson["distance"].string {
                                let distanceStringLower = distanceString.lowercased()
                                if (distanceStringLower == "near" || distanceStringLower == "immediate" || distanceStringLower == "far") {
                                    distance = distanceStringLower
                                }
                            }
                            if let messageString = beaconJson["message"].string {
                                message = messageString
                            }
                            
                            if uuid != nil && major != nil && minor != nil && distance != nil {
                                do {
                                    let fetchRequest: NSFetchRequest<LaunchBeaconEntity> = LaunchBeaconEntity.fetchRequest()
                                    fetchRequest.predicate = NSPredicate(format: "moduleKey == %@", moduleKey)
                                    let launchBeaconEntities = try managedObjectContext.fetch(fetchRequest)
                                    
                                    var launchBeaconEntity: LaunchBeaconEntity
                                    if launchBeaconEntities.count == 1 {
                                        launchBeaconEntity = launchBeaconEntities[0]
                                    } else {
                                        launchBeaconEntity = NSEntityDescription.insertNewObject(forEntityName: LaunchBeaconEntity.launchBeaconEntityName, into: managedObjectContext) as! LaunchBeaconEntity
                                    }
                                    
                                    launchBeaconEntity.moduleKey = moduleKey
                                    launchBeaconEntity.uuid = uuid!
                                    launchBeaconEntity.major = major!
                                    launchBeaconEntity.minor = minor!
                                    launchBeaconEntity.triggerDistance = distance!
                                    launchBeaconEntity.message = message
                                    
                                    processedModuleKeys.append(moduleKey)
                                    
                                    print("Saving launch beacon: \(launchBeaconEntity.id())")
                                    try managedObjectContext.save()
                                } catch {
                                    print("Save on launchBeacon for module key: \(moduleKey) failed")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc private func configurationLoaded(_ notification: Notification) {
        // do we need to remove any launch beacons
        // see if any launch beacons are in CoreData that aren't in the processedModuleKeys list
        do {
            let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
            let fetchRequest: NSFetchRequest<LaunchBeaconEntity> = LaunchBeaconEntity.fetchRequest()
            let launchBeaconEntities = try managedObjectContext.fetch(fetchRequest)
            
            launchBeaconEntities.forEach {
                if !processedModuleKeys.contains($0.moduleKey) {
                    managedObjectContext.delete($0)
                }
            }
            
            try managedObjectContext.save()
        } catch {
            print("Failed to delete unused launch beacon(s)")
        }
        
        DispatchQueue.global(qos: .background).async {
            self.processedModuleKeys.removeAll()
            
            // refresh the monitoring
            self.monitorLaunchBeacons()
        }
    }
    
    // Beacon Manager Notifications
    @objc private func didEnterRegion(_ notification: Notification) {
        print("LaunchBeaconManager got a didEnterRegion")
        
        if let data = notification.object as! [String: Any]? {
            if let launchBeacon = data["goBeacon"] as! LaunchBeacon? {
                print("LaunchBeaconManager got a didEnterRegion with beacon data")
                var notifyUserFlag = false
                
                // ensure user is allowed to launch this module
                let checkModules = ModuleManager.findUserModules(includeDontDisplayInMenu: true).filter {
                    $0.internalKey == launchBeacon.moduleKey
                }
                if checkModules.count == 1 {
                    notifyUserFlag = true
                }
                
                let defaults = UserDefaults.standard
                
                // if muted for a day, make sure the time had expired
                if notifyUserFlag {
                    let key = "beacon-mute-for-today-\(launchBeacon.id())"
                    if let beaconMuteDate = defaults.object(forKey: key) as! Date? {
                        let unMuteDate = Date(timeInterval: LaunchBeaconManager.dayInterval, since: beaconMuteDate)
                        if Date() > unMuteDate {
                            // good to go, remove the default data since it isn't needed now
                            defaults.removeObject(forKey: key)
                        } else {
                            notifyUserFlag = false
                            print("beacon muted for the day: \(launchBeacon.id())")
                        }
                    }
                }
                
                if notifyUserFlag {
                    // make sure this beacon isn't on the edge of a region, meaning we keep getting enter and exit regions
                    // If they exited recently don't notify
                    let key = "beacon-exit-region-\(launchBeacon.id())"
                    if let beaconExitDate = defaults.object(forKey: key) as! Date? {
                        let exitPlusIntervalDate = Date(timeInterval: LaunchBeaconManager.fiveMinuteInterval, since: beaconExitDate)
                        let now = Date()
                        if now <= exitPlusIntervalDate {
                            // ignore this enter region
                            notifyUserFlag = false
                            print("Ignoring did enter region because it is too soon exit: \(beaconExitDate)")
                        }
                    }
                }
                
                if notifyUserFlag {
                    notifyUser(launchBeacon)
                }
            }
        }
    }
    
    @objc private func didExitRegion(_ notification: Notification) {
        print("LaunchBeaconManager got a didExitRegion")
        if let data = notification.object as! [String: Any]?, let region = data["region"] as! CLBeaconRegion? {
            let regionId = BeaconManager.beaconId(uuid: region.proximityUUID, major: region.major, minor: region.minor)
            // find launch beacons that match this region
            
            let matchingBeacons = monitoredLaunchBeacons.values.filter {
                $0.id().hasPrefix(regionId)
            }
            
            let defaults = UserDefaults.standard
            matchingBeacons.forEach { (launchBeacon: LaunchBeacon) -> Void in
                removeNotification(launchBeacon)
                
                // keep track of when it was last seen
                let now = Date()
                if let monitoringStartDate = defaults.object(forKey: "beacon-start-monitoring") as! Date? {
                    let monitoringStartPlusIntervalDate = Date(timeInterval: LaunchBeaconManager.closeToTimeInterval, since: monitoringStartDate)
                    if now > monitoringStartPlusIntervalDate {
                        // only mark the exit if it isn't close to the start monitoring time
                        let key = "beacon-exit-region-\(launchBeacon.id())"
                        print("beacon: \(launchBeacon.id()) exit region at: \(now)")
                        defaults.set(now, forKey: key)
                    }
                }
            }
        }
    }
    
    @objc private func didEnterRange(_ notification: Notification) {
        print("LaunchBeaconManager got a didEnterRange")
    }
    
    @objc private func watchMessage(_ notification: Notification) {
        print("LaunchBeaconManager got watch message")
        if let action = (notification.object as! [String: Any])["action"] as! String? {
            if action == "mute beacon" {
                
            }
        }
    }
}
