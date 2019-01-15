//
//  BeaconManager.swift
//  Mobile
//
//  Created by Bret Hansen on 7/22/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//


import Foundation
import UserNotifications
import CoreBluetooth

class BeaconManager: NSObject {

    // BeaconManager is a singleton
    static let shared = BeaconManager()
    
    static let didEnterRegion = Notification.Name("GoBeaconDidEnterRegion")
    static let didExitRegion = Notification.Name("GoBeaconDidExitRegion")
    static let didEnterRange = Notification.Name("GoBeaconDidEnterRange")
    
    static let oneDayInterval:TimeInterval = 60*60*24 // one day
    
    private var started = false
    
    private let locationManager = CLLocationManager()
    
    private var monitoredBeacons = [MonitoredBeacon]()

    private var cbCentralManager: CBCentralManager?

    private override init() {
        super.init()
    }

    class func start() {
        shared.startManager()
    }
    
    private func startManager() {
        if !started {
            print("Starting BeaconManager")

            stopMonitoring()
            
            locationManager.delegate = self
            
            started = true
        }
    }
    
    func stopMonitoring(source: String) {
        stopMonitoring(source: source, forgetBeacons: true)
    }
    
    func addBeacon(toMonitor beacon: GoBeacon) {
        monitoredBeacons.append(MonitoredBeacon(beacon))
    }
    
    func doneAddingBeacons() {
        refreshMonitoredBeacons()
    }
    
    func addBeacons(toMonitor beacons: [GoBeacon]) {
        self.monitoredBeacons.append(contentsOf: beacons.map { MonitoredBeacon($0) })
        
        refreshMonitoredBeacons()
    }
    
    private func checkBluetooth() {
        // ensure CBCentralManager has been created. Creating it, keeping it and using self as delegate ensures we get told if bluetooth is off
        if cbCentralManager == nil {
            cbCentralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background), options: [CBCentralManagerOptionShowPowerAlertKey: false])
        } else {
            var warn = false
            switch cbCentralManager!.state {
            case .poweredOff:
                print("centralManagerDidUpdateState Bluetooth is off")
                warn = true
            case .poweredOn, .resetting:
                print("centralManagerDidUpdateState Bluetooth is on")
            case .unsupported:
                print("centralManagerDidUpdateState Bluetooth is not supported")
            case .unauthorized:
                print("centralManagerDidUpdateState Bluetooth is not authorized")
            case .unknown:
                print("centralManagerDidUpdateState Bluetooth state is unknown")
            }
            
            if warn {
                self.warnBluetoothIsOff()
            }
        }
    }
    
    fileprivate func warnBluetoothIsOff() {
        // warn bluetooth is off after checking to make sure we aren't warning too often or if they ask to not be reminded
        if let defaults = AppGroupUtilities.userDefaults() {
            var muteForever = false
            if let muteForeverSetting = defaults.object(forKey: "bluetooth-off-mute-forever") as! Bool? {
                muteForever = muteForeverSetting
            }
            
            if !muteForever {
                // check if it has been more than one day since last warning
                var warn = true
                if let lastWarnSetting = defaults.object(forKey: "bluetooth-off-last-warn") as! Date? {
                    let warnDate = Date(timeInterval: BeaconManager.oneDayInterval, since: lastWarnSetting)
                    let now = Date()
                    warn = now > warnDate
                }

                if warn {
                    showBluetoothOffAlert()
                    let startOfDay = Calendar.current.startOfDay(for: Date())
                    defaults.set(startOfDay, forKey: "bluetooth-off-last-warn")
                }
            }
        }
    }
    
    fileprivate func showBluetoothOffAlert() {
        let title = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let message = NSLocalizedString("Bluetooth is used at your institution to alert you when you are near location specific information or services. Please enable Bluetooth in your device settings.", comment: "Message to encourage them to turn on bluetooth")
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let muteForToday: UIAlertAction = UIAlertAction(title: NSLocalizedString("Mute For Today", comment: "Mute For Today button label"), style: .cancel, handler: {(action: UIAlertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
        })
        let muteForever: UIAlertAction = UIAlertAction(title: NSLocalizedString("Mute Forever", comment: "Mute Forever label"), style: .destructive, handler: {(action: UIAlertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
            
            // set user pref to not remind
            if let defaults = AppGroupUtilities.userDefaults() {
                defaults.set(true, forKey: "bluetooth-off-mute-forever")
            }
        })
        
        alert.addAction(muteForever)
        alert.addAction(muteForToday)
        
        let application = UIApplication.shared
        application.delegate?.window??.makeKeyAndVisible()
        application.delegate?.window??.rootViewController?.present(alert, animated: true, completion: nil)

    }
    
    private func warnLocationAccess() {
        // warn if location access isn't Always after checking to make sure we aren't warning too often or if they ask to not be reminded
        if let defaults = AppGroupUtilities.userDefaults() {
            var muteForever = false
            if let muteForeverSetting = defaults.object(forKey: "location-access-mute-forever") as! Bool? {
                muteForever = muteForeverSetting
            }
            
            if !muteForever {
                // check if it has been more than one day since last warning
                var warn = true
                if let lastWarnSetting = defaults.object(forKey: "location-access-last-warn") as! Date? {
                    let warnDate = Date(timeInterval: BeaconManager.oneDayInterval, since: lastWarnSetting)
                    let now = Date()
                    warn = now > warnDate
                }
                
                if warn {
                    showLocationAccessAlert()
                    let startOfDay = Calendar.current.startOfDay(for: Date())
                    defaults.set(startOfDay, forKey: "location-access-last-warn")
                }
            }
        }
    }
    
    private func showLocationAccessAlert() {
        let title = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        let message = NSLocalizedString("Location services are used at your institution to alert you when you are near location specific information or services. Please allow location access \"Always\" in your device settings.", comment: "Message to encourage them to turn on Location Access to Always. The text in quotes is the label used by iOS. Arabic=دائما Spanish=Siempre French=Tourjous Portuguese=Sempre")
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let muteForToday: UIAlertAction = UIAlertAction(title: NSLocalizedString("Mute For Today", comment: "Mute For Today button label"), style: .cancel, handler: {(action: UIAlertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
        })
        let muteForever: UIAlertAction = UIAlertAction(title: NSLocalizedString("Mute Forever", comment: "Mute Forever label"), style: .destructive, handler: {(action: UIAlertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
            
            // set user pref to not remind
            if let defaults = AppGroupUtilities.userDefaults() {
                defaults.set(true, forKey: "location-access-mute-forever")
            }
        })
        let settings: UIAlertAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Settings application name. This is part of iOS.  Apple translates this to be Arabic = الإعدادات Spanish/Portuguese=Ajustes French=Réglages"), style: .default, handler: {(action: UIAlertAction) -> Void in
            alert.dismiss(animated: true, completion: nil)
            
            OperationQueue.main.addOperation(OpenModuleSettingsOperation())
        })
        
        alert.addAction(settings)
        alert.addAction(muteForever)
        alert.addAction(muteForToday)
        
        let application = UIApplication.shared
        application.delegate?.window??.makeKeyAndVisible()
        application.delegate?.window??.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func refreshMonitoredBeacons() {
        print("refreshMonitoredBeacons")

        // stop the monitor for each source
        var sources = Set<String>()
        for monitoredBeacon in monitoredBeacons {
            let beacon = monitoredBeacon.goBeacon
            if let source = beacon.source {
                sources.insert(source)
            }
        }
        
        for source in sources {
            stopMonitoring(source: source, forgetBeacons: false)
        }
        
        if monitoredBeacons.count > 0 {
            // ensure bluetooth is on
            checkBluetooth()
            
            // make sure authorization has been requested
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                locationManager.requestAlwaysAuthorization()
            case CLAuthorizationStatus.denied:
                print("User denied location permission - beacons will not work")
                warnLocationAccess()
            case CLAuthorizationStatus.authorizedWhenInUse:
                locationManager.requestAlwaysAuthorization()
                print("Beacon monitoring won't work with WhenInUserAuthorization")
            case CLAuthorizationStatus.authorizedAlways:
                print("Wahoo, location authorized")
            default:
                print("location authorization status unknown")
            }

            // build a list of 20 or less to monitor
            var done = false
            var idsCount = 0
            var beaconsToMonitor: [String:MonitoredBeacon]
            repeat {
                beaconsToMonitor = [:]
                idsCount += 1
                for monitoredBeacon in monitoredBeacons {
                    let beacon = monitoredBeacon.goBeacon
                    let major: Int16? = idsCount <= 2 ? beacon.major : nil
                    let minor: Int16? = idsCount <= 1 ? beacon.minor : nil
                    let beaconId = BeaconManager.beaconId(uuidString: beacon.uuid, major: major, minor: minor)
                    
                    beaconsToMonitor[beaconId] = monitoredBeacon
                }
                
                done = beaconsToMonitor.count <= 20
            } while !done && idsCount < 3

            for (_, monitoredBeacon) in beaconsToMonitor {
                let beacon = monitoredBeacon.goBeacon
                let major: Int16? = idsCount <= 2 ? beacon.major : nil
                let minor: Int16? = idsCount <= 1 ? beacon.minor : nil
                let beaconId = BeaconManager.beaconSourceId(source: beacon.source, uuidString: beacon.uuid, major: major, minor: minor)
                let beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: beacon.uuid)!, major: CLBeaconMajorValue(beacon.major), minor: CLBeaconMinorValue(beacon.minor), identifier: beaconId)
                locationManager.startMonitoring(for: beaconRegion)
                print("Monitoring for beacon: \(beaconId)")
            }
        }
    }

    private func stopMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
            locationManager.stopRangingBeacons(in: region as! CLBeaconRegion)
        }
    }

    private func stopMonitoring(source: String, forgetBeacons: Bool) {
        let prefixCheck = source + "."
        for region in locationManager.monitoredRegions {
            if region.identifier.hasPrefix(prefixCheck) {
                locationManager.stopMonitoring(for: region)
                locationManager.stopRangingBeacons(in: region as! CLBeaconRegion)
            }
        }
        
        if forgetBeacons {
            for monitoredBeacon in monitoredBeacons {
                let beacon = monitoredBeacon.goBeacon
                if beacon.source == source {
                    print("removed beacon from montiored beacons: \(beacon.id())")
                    monitoredBeacons.remove(at: monitoredBeacons.index(of: monitoredBeacon)!)
                }
            }
        }
    }

    static func beaconId(uuid: UUID, major: NSNumber?, minor: NSNumber?) -> String {
        var id = uuid.uuidString
        if major != nil {
            id += ".\(major!)"
            if minor != nil {
                id += ".\(minor!)"
            }
        }
        
        return id
    }
    
    static func beaconId(uuidString: String, major: Int16?, minor: Int16?) -> String {
        var id = uuidString
        if major != nil {
            id += ".\(major!)"
            if minor != nil {
                id += ".\(minor!)"
            }
        }
        
        return id
    }
    
    static func beaconSourceId(source: String?, uuidString: String, major: Int16?, minor: Int16?) -> String {
        var id = ""
        if source != nil {
            id = "\(source!)."
        }
        id += uuidString
        if major != nil {
            id += ".\(major!)"
            if minor != nil {
                id += ".\(minor!)"
            }
        }
        
        return id
    }
    
    static func insideDistance(proximity: CLProximity, triggerDistance: String) -> Bool {
        let proximityValue = proximity.rawValue
        let distanceValue = triggerDistance == "far" ? CLProximity.far.rawValue : triggerDistance == "near" ? CLProximity.near.rawValue : CLProximity.immediate.rawValue
        
        return proximityValue <= distanceValue
    }
    
    private func findMatchingBeacons(uuid: UUID, major: NSNumber?, minor: NSNumber?) -> [MonitoredBeacon] {
        let majorInt = major != nil ? major?.int16Value : nil
        let minorInt = major != nil ? minor?.int16Value : nil
        return findMatchingBeacons(uuid: uuid.uuidString, major: majorInt, minor: minorInt)
    }
    
    private func findMatchingBeacons(uuid: String, major: Int16?, minor: Int16?) -> [MonitoredBeacon] {
        let id = BeaconManager.beaconId(uuidString: uuid, major: major, minor: minor)

        return monitoredBeacons.filter {
            let checkId = BeaconManager.beaconId(uuidString: $0.goBeacon.uuid, major: $0.goBeacon.major, minor: $0.goBeacon.minor)
            return checkId.hasPrefix(id)
        }
    }
    
    private func markBeaconsOutOfRegion(for region: CLBeaconRegion) {
        // find any beacons in the region and ensure they are marked out of range
        let regionBeacons = findMatchingBeacons(uuid: region.proximityUUID, major: region.major, minor: region.minor)

        for monitoredBeacon in regionBeacons {
            print("marked beacon out of region beacon: \(monitoredBeacon.id())")
            monitoredBeacon.inRegion = false
            monitoredBeacon.inRange = false
        }
    }
    
    func didStartMonitoring(manager: CLLocationManager, for region: CLBeaconRegion) {
        // request current state so we trigger if they are already in a region
        manager.requestState(for: region)
    }

    
    func didDetermineState(manager: CLLocationManager, state: CLRegionState, for region: CLBeaconRegion) {
        
        let stateString = state == CLRegionState.inside ? "inside" : "outside"
        print("didDetermineState: \(stateString) \(region.identifier)")
        
        // This captures the case where we start up within a region
        switch(state) {
        case .inside:
            // treat as though we entered the region
            didEnterRegion(manager: manager, region: region)
        case .outside:
            // treat as though we exited the region
            didExitRegion(manager: manager, region: region)
        case .unknown: break // noop
        }
    }
    
    fileprivate func didEnterRegion(manager: CLLocationManager, region: CLBeaconRegion) {
        print("Region entered id: \(region.identifier)")
        
        var data: [String: NSObject] = ["region": region]
        
        if region.major != nil && region.minor != nil {
            let matchingBeacons = findMatchingBeacons(uuid: region.proximityUUID, major: region.major, minor: region.minor)
            for matchingBeacon in matchingBeacons {
                if !matchingBeacon.inRegion {
                    matchingBeacon.inRegion = true
                    
                    // notify this beacon is withing region
                    data["goBeacon"] = matchingBeacon.goBeacon
                    NotificationCenter.default.post(name: BeaconManager.didEnterRegion, object: data)
                    
                    print("matching beacon: \(matchingBeacon.id()) marked in region")
                } else {
                    print("monitored beacon already marked in region beacon: \(matchingBeacon.id())")
                }
            }
        } else {
            NotificationCenter.default.post(name: BeaconManager.didEnterRegion, object: data)
        }

        manager.startRangingBeacons(in: region)
    }
    
    fileprivate func didExitRegion(manager: CLLocationManager, region: CLBeaconRegion) {
        print("Region exited id: \(region.identifier)")

        let data = ["region": region]
        NotificationCenter.default.post(name: BeaconManager.didExitRegion, object: data)

        manager.stopRangingBeacons(in: region)
        
        markBeaconsOutOfRegion(for: region)
    }
    
    fileprivate func didRangeBeacons(manager: CLLocationManager, beacons: [CLBeacon], region: CLBeaconRegion) {
        for beacon in beacons {
            //let beaconId = "\(beacon.proximityUUID.uuidString.uppercased()).\(beacon.major).\(beacon.minor)"
            //print("ranged beacon: \(beaconId) proximity: \(beacon.proximity.rawValue)")
            
            // see if beacon is now in range
            let matchingBeacons = findMatchingBeacons(uuid: beacon.proximityUUID, major: beacon.major, minor: beacon.minor)
            for matchingBeacon in matchingBeacons {
                if !matchingBeacon.inRegion {
                    matchingBeacon.inRegion = true
                    // notify this beacon is withing region
                    let data : [String : Any] = ["clBeacon": beacon, "goBeacon": matchingBeacon.goBeacon, "region": region]
                    NotificationCenter.default.post(name: BeaconManager.didEnterRegion, object: data)
                }
                // did it just come into range
                if !matchingBeacon.inRange {
                    // see if proximity is the same or closer
                    if BeaconManager.insideDistance(proximity: beacon.proximity, triggerDistance: matchingBeacon.goBeacon.triggerDistance) {
                        matchingBeacon.inRange = true
                        
                        // notify
                        let data : [String : Any] = ["clBeacon": beacon, "goBeacon": matchingBeacon.goBeacon, "region": region]
                        NotificationCenter.default.post(name: BeaconManager.didEnterRange, object: data)
                    }
                }
            }
        }
    }
}

extension BeaconManager:CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("authorization did change: \(status.rawValue)")
        refreshMonitoredBeacons()
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("didStartMonitoringFor region: \(region.identifier)")
        didStartMonitoring(manager: manager, for: region as! CLBeaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        didDetermineState(manager: manager, state: state, for: region as! CLBeaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed monitoring region: \(error.localizedDescription)")
        // might mean bluetooth is turned off
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        didEnterRegion(manager: manager, region: region as! CLBeaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        didRangeBeacons(manager: manager, beacons: beacons, region: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        didExitRegion(manager: manager, region: region as! CLBeaconRegion)
    }
}


extension BeaconManager:CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("CBCentralManager did update state")

        var warn = false
        switch central.state {
        case .poweredOff:
            print("centralManagerDidUpdateState Bluetooth is off")
            warn = true
        case .poweredOn, .resetting:
            print("centralManagerDidUpdateState Bluetooth is on")
            // refresh monintoring beacons now that bluetooth is on
            refreshMonitoredBeacons()
        case .unsupported:
            print("centralManagerDidUpdateState Bluetooth is not supported")
        case .unauthorized:
            print("centralManagerDidUpdateState Bluetooth is not authorized")
        case .unknown:
            print("centralManagerDidUpdateState Bluetooth state is unknown")
        }
        
        if warn {
            self.warnBluetoothIsOff()
        }
    }
}
