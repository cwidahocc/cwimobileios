//
//  ConfigurationManager.swift
//  Mobile
//
//  Shared code to manage fetching configuration and sending updated configuration between iPhone and watch
//
//  Created by Bret Hansen on 8/24/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import UIKit

class ConfigurationManager: NSObject {
    
    static let ConfigurationLoadStartedNotification = Notification.Name("Configuration Load Started")
    static let ConfigurationLoadSucceededNotification = Notification.Name("Configuration Load Succeeded")
    static let ConfigurationProcessingModulesStartedNotification = Notification.Name("Configuration Processing Modules Started")
    static let ConfigurationProcessingModuleNotification = Notification.Name("Configuration Processing Module")
    static let ConfigurationProcessingModulesCompletedNotification = Notification.Name("Configuration Processing Modules Completed")
    static let ConfigurationLoadFailedNotification = Notification.Name("Configuration Load Failed")
    static let MobileServerConfigurationLoadSucceededNotification = Notification.Name("Mobile Server Configuration Load Succeeded")
    static let MobileServerConfigurationLoadFailedNotification = Notification.Name("Mobile Server Configuration Load Failed")
    
    static let shared = ConfigurationManager()
    
    private let refreshInterval: Double = 1200  //seconds for 20 minutes = 1200 seconds
    
    private var configurationData: Data?
    
    lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    // make init private for singleton
    override private init() {
    }
    
    func isConfigurationLoaded() -> Bool {
        return mostRecentConfigurationData() != nil
    }
    
    func shouldConfigurationBeRefreshed() -> Bool {
        var result = false
        
        // check if it is time to refresh
        if let defaults = AppGroupUtilities.userDefaults() {
            if let refreshDate = defaults.object(forKey: "configuration refresh date") {
                let intervals = (Date().timeIntervalSince(refreshDate as! Date)) / refreshInterval
                result = intervals >= 1
            } else {
                return true
            }
            
            
            guard let lastUpdated = defaults.string(forKey: "lastUpdated-configuration") else {
                return result
            }
            
            
            if let baseConfigurationUrl = getConfigurationUrl() , result {
                let configurationUrl = baseConfigurationUrl + "?onlyLastUpdated=true"
                if let theUrl = URL(string: configurationUrl) {
                    do {
                        let configurationData = try Data(contentsOf: theUrl, options: NSData.ReadingOptions())
                        
                        let jsonResults = JSON(data: configurationData)
                        let lastUpdatedFromServer = jsonResults["lastUpdated"].stringValue
                        result = lastUpdatedFromServer != lastUpdated
                        defaults.set(lastUpdatedFromServer, forKey: "lastUpdated-configuration")
                        
                    } catch {
                        print(error)
                    }
                }
                
            }
            
        }
        return result
    }
    
    func mostRecentConfigurationData() -> Data? {
        var configurationData: Data? = self.configurationData
        
        if configurationData == nil {
            if let defaults = AppGroupUtilities.userDefaults() {
                if let defaultConfigurationData = defaults.object(forKey: "configuration data") as! Data? {
                    configurationData = defaultConfigurationData
                }
            }
        }
        
        return configurationData
    }
    
    func getConfigurationUrl(configurationUrl pConfigurationUrl: String? = nil) -> String? {
        var configurationUrl = pConfigurationUrl
        if configurationUrl == nil {
            // use the defaults configurationUrl
            if let defaults = AppGroupUtilities.userDefaults() {
                configurationUrl = defaults.string(forKey: "configurationUrl")
            }
        }
        
        return configurationUrl
    }
    
    // true return value means either configuration is loaded and doesn't need to be refreshed or configuration was refreshed
    // false return value indicates configuration has not been loaded and can't. In Watch case this may mean the user needs to select a configuration
    func refreshConfigurationIfNeeded(configurationUrl: String? = nil, completionHandler: @escaping ((_ result: Any) -> Void)) {
        var respondWithFailureToCompletionHandler = true
        
        if mostRecentConfigurationData() == nil || shouldConfigurationBeRefreshed() {
            // time to refresh
            print("ConfigurationManager refreshConfigurationIfNeeded needs to be refreshed")
            loadConfiguration(configurationUrl: configurationUrl, completionHandler: completionHandler)
            respondWithFailureToCompletionHandler = false
        }
        
        if shouldMobileServerConfigurationBeRefreshed() {
            // time to refresh
            loadMobileServerConfiguration(nil)
        }
        
        if respondWithFailureToCompletionHandler {
            completionHandler(false)
        }
    }
    
    func loadConfiguration(configurationUrl pConfigurationUrl: String? = nil, completionHandler: @escaping ((_ result: Bool) -> Void)) {
        var handleCompletionHandler = true
        
        NotificationCenter.default.post(name: ConfigurationManager.ConfigurationLoadStartedNotification, object: nil)

        if let configurationUrl = getConfigurationUrl(configurationUrl: pConfigurationUrl) {
            // download the configuration
            if let theUrl = URL(string: configurationUrl) {
                handleCompletionHandler = false
                var request = URLRequest(url: theUrl)
                let task = urlSession.ellucianDownloadTask(with: &request) {
                    (location, response, error) in
                    
                    if let location = location {
                        
                        handleCompletionHandler = true
                        #if os(iOS)
                            DispatchQueue.main.async {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            }
                        #endif
                        
                        if let error = error {
                            print("Cannot load configuration, unable to access data from: \(location) \(error.localizedDescription)")
                            NotificationCenter.default.post(name: ConfigurationManager.ConfigurationLoadFailedNotification, object: nil)
                        } else {
                            handleCompletionHandler = false
                            if let configurationData = try? Data(contentsOf: location) {
                                self.processConfigurationData(configurationData) {
                                    (result: Bool) in
                                    
                                    if result {
                                        NotificationCenter.default.post(name: ConfigurationManager.ConfigurationLoadSucceededNotification, object: nil)
                                    }
                                    completionHandler(result)
                                }
                            } else {
                                handleCompletionHandler = true
                                print("Cannot load configuration, unable to access data from: \(location)")
                                NotificationCenter.default.post(name: ConfigurationManager.ConfigurationLoadFailedNotification, object: nil)
                            }
                        }
                        
                        if handleCompletionHandler {
                            completionHandler(false)
                        }
                    }
                }
                task.resume()
                #if os(iOS)
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    }
                #endif
            } else {
                // failed to create NSURL
                // notify the failure
                print("Cannot load configuration, unable to create NSURL from: \"\(configurationUrl)\"")
                NotificationCenter.default.post(name: ConfigurationManager.ConfigurationLoadFailedNotification, object: nil)
            }
        } else {
            
            #if os(watchOS)
                handleCompletionHandler = false
                
                // don't know the configuration url - watch needs to ask phone for configuration
                WatchConnectivityManager.sharedInstance.sendActionMessage("fetch configuration", replyHandler: {
                    (reply: [String: Any]) -> Void in
                    var handleCompletionHandler = true
                    
                    if let configurationData = reply["configurationData"] as! Data? {
                        handleCompletionHandler = false
                        self.processConfigurationData(configurationData, notifyOtherSide: false, completionHandler: completionHandler)
                    } else if let configurationUrl = reply["configurationUrl"] as! String? {
                        handleCompletionHandler = false
                        self.loadConfiguration(configurationUrl: configurationUrl, completionHandler: completionHandler)
                    } else {
                        print("configurationData is missing from the data: \(reply)")
                    }
                    
                    
                    if handleCompletionHandler {
                        completionHandler(false)
                    }
                    },
                    errorHandler: {
                        (error: Error) -> Void in
                        
                        completionHandler(false)
                        print("Cannot load configuration fetched from Phone")
                })
            #endif
            
            
            // No Configuration URL notify the failure
            print("Cannot load configuration, no configurationUrl")
            NotificationCenter.default.post(name: ConfigurationManager.ConfigurationLoadFailedNotification, object: nil)
        }
        
        if handleCompletionHandler {
            completionHandler(false)
        }
    }
    
    func processConfigurationData(_ configurationData: Data, notifyOtherSide: Bool = true, completionHandler: @escaping ((_ result: Bool) -> Void)) {
        
        let json = JSON(data: configurationData)
        let processingDispatchGroup = DispatchGroup()
        processingDispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            self.processConfigurationData(json, dispatchGroup: processingDispatchGroup)
            processingDispatchGroup.leave()
        }
        
        processingDispatchGroup.notify(queue: DispatchQueue.main) {
            // cache the configuration data
            if let defaults = AppGroupUtilities.userDefaults() {
                defaults.set(configurationData, forKey: "configuration data")
                defaults.set(Date(), forKey: "configuration refresh date")
            }
            
            // clear watch cached data
            #if os(watchOS)
                DefaultsCache.clearAllCaches()
            #endif
            
            // let other side know
            if notifyOtherSide {
                WatchConnectivityManager.sharedInstance.notifyOtherSide("configurationLoaded", data: configurationData)
            }
            
            NotificationCenter.default.post(name: ConfigurationManager.ConfigurationLoadSucceededNotification, object: nil)
            
            completionHandler(true)
        }
    }
    
    func processConfigurationData(_ json: JSON, dispatchGroup: DispatchGroup) {
        if let versions = json["versions"].dictionary {
            let iosVersions = versions["ios"]?.arrayValue.map{ $0.string } as? [String]
            if let iosVersions = iosVersions {
                if VersionChecker.sharedInstance.checkVersion(iosVersions) {
                    let defaults = AppGroupUtilities.userDefaults()!
                    
                    if let lastUpdated = json["lastUpdated"].string {
                        defaults.set(lastUpdated, forKey: "lastUpdated-configuration")
                    }
                    
                    if let about = json["about"].dictionary {
                        if let contact = about["contact"]?.stringValue {
                            defaults.set(contact, forKey: "about-contact")
                        }
                        if let email = about["email"]?.dictionary {
                            if let address = email["address"]?.string {
                                defaults.set(address, forKey: "about-email-address")
                            }
                            if let display = email["display"]?.string {
                                defaults.set(display, forKey: "about-email-display")
                            }
                        }
                        if let aboutIcon = about["icon"]?.string {
                            defaults.set(aboutIcon, forKey: "about-icon")
                            ImageCache.sharedCache.cacheImageForLater(aboutIcon, dispatchGroup: dispatchGroup)
                        }

                        if let aboutLogoUrlPhone = about["logoUrlPhone"]?.string {
                            defaults.set(aboutLogoUrlPhone, forKey: "about-logoUrlPhone")
                            #if os(iOS)
                            ImageCache.sharedCache.cacheImageForLater(aboutLogoUrlPhone, dispatchGroup: dispatchGroup)
                            #endif
                        }
                        if let phone = about["phone"]?.dictionary {
                            if let display = phone["display"]?.string {
                                defaults.set(display, forKey: "about-phone-display")
                            }
                            if let number = phone["number"]?.string {
                            defaults.set(number, forKey: "about-phone-number")
                            }
                        }
                        if let privacy = about["privacy"]?.dictionary {
                            if let display = privacy["display"]?.string {
                                defaults.set(display, forKey: "about-privacy-display")
                            }
                            if let url = privacy["url"]?.string {
                                defaults.set(url, forKey: "about-privacy-url")
                            }
                        }
                        if let version = about["version"]?.dictionary {
                            if let url = version["url"]?.string {
                                defaults.set(url, forKey: "about-version-url")
                            }
                        }
                        if let website = about["website"]?.dictionary {
                            if let display = website["display"]?.string {
                                defaults.set(display, forKey: "about-website-display")
                            }
                            if let url = website["url"]?.string {
                                defaults.set(url, forKey: "about-website-url")
                            }
                        }
                    }
                    
                    if let login = json["login"].dictionary {
                        if let usernameHint = login["usernameHint"]?.string, usernameHint != "" {
                            defaults.set(usernameHint, forKey: "login-username-hint")
                        }
                        if let passwordHint = login["passwordHint"]?.string, passwordHint != "" {
                            defaults.set(passwordHint, forKey: "login-password-hint")
                        }
                        if let loginInstructions = login["instructions"]?.string, loginInstructions != "" {
                            defaults.set(loginInstructions, forKey: "login-instructions")
                        }
                        if let loginHelp = login["help"]?.dictionary {
                            if let loginHelpUrl = loginHelp["url"]?.string, loginHelpUrl != "" {
                                defaults.set(loginHelpUrl, forKey: "login-help-url")
                            }
                            if let loginHelpDisplay = loginHelp["display"]?.string, loginHelpDisplay != "" {
                                defaults.set(loginHelpDisplay, forKey: "login-help-display")
                            }
                        }
                    }
                    
                    if let layout = json["layout"].dictionary {
                        if let primaryColor = layout["primaryColor"]?.string {
                            defaults.set(primaryColor, forKey: "primaryColor")
                        }
                        if let headerTextColor = layout["headerTextColor"]?.string {
                            defaults.set(headerTextColor, forKey: "headerTextColor")
                        }
                        if let accentColor = layout["accentColor"]?.string {
                            defaults.set(accentColor, forKey: "accentColor")
                        }
                        if let subheaderTextColor = layout["subheaderTextColor"]?.string {
                            defaults.set(subheaderTextColor, forKey: "subheaderTextColor")
                        }
                        
                        if let homeUrlPhone = layout["homeUrlPhone"]?.string {
                            defaults.set(homeUrlPhone, forKey: "home-background")
                        }
                        
                        #if os(iOS)
                            if let homeUrlTablet = layout["homeUrlTablet"]?.string {
                                defaults.set(homeUrlTablet, forKey: "home-tablet-background")
                            }
                            
                            #if os(iOS)
                            if let homeUrlTablet = layout["homeUrlTablet"]?.string, UIDevice.current.userInterfaceIdiom == .pad && !homeUrlTablet.isEmpty {
                                ImageCache.sharedCache.cacheImageForLater(homeUrlTablet, dispatchGroup: dispatchGroup)
                            } else if let homeUrlPhone = layout["homeUrlPhone"]?.string, !homeUrlPhone.isEmpty {
                                ImageCache.sharedCache.cacheImageForLater(homeUrlPhone, dispatchGroup: dispatchGroup)
                            }
                            #endif
                        #endif
                    }
                    
                    if let security = json["security"].dictionary {
                        if let url = security["url"]?.string {
                            defaults.set(url, forKey: "login-url")
                            if let logoutUrl = security["logoutUrl"]?.string {
                                defaults.set(logoutUrl, forKey: "logout-url")
                            }
                        }
                        if let web = security["web"] {
                            defaults.set("browser", forKey:"login-authenticationType")
                            if let loginUrl = web["loginUrl"].string {
                                defaults.set(loginUrl, forKey: "login-web-url")
                            }
                        } else if let cas = security["cas"] {
                            if let loginType = cas["loginType"].string {
                                defaults.set(loginType, forKey: "login-authenticationType")
                            }
                            if let loginUrl = cas["loginUrl"].string {
                                defaults.set(loginUrl, forKey: "login-web-url")
                            }
                            defaults.set(true, forKey: "login-native-cas")
                        } else {
                            defaults.set("native", forKey: "login-authenticationType")
                            defaults.set(false, forKey: "login-native-cas")
                        }
                    }
                    
                    if let mobileServerConfig = json["mobileServerConfig"].dictionary {
                        if let url = mobileServerConfig["url"]?.string {
                            defaults.set(url, forKey: "mobileServerConfig-url")
                        }
                    }
                    
                    if let map = json["map"].dictionary {
                        if let buildings = map["buildings"]?.string {
                            defaults.set(buildings, forKey: "urls-map-buildings")
                        }
                        if let campuses = map["campues"]?.string {
                            defaults.set(campuses, forKey: "urls-map-campuses")
                        }
                    }
                    
                    if let directory = json["directory"].dictionary {
                        defaults.set(directory["allSearch"]?.stringValue, forKey: "urls-directory-allSearch")
                        defaults.set(directory["facultySearch"]?.stringValue, forKey: "urls-directory-facultySearch")
                        defaults.set(directory["studentSearch"]?.stringValue, forKey: "urls-directory-studentSearch")
                        if let baseSearch = directory["baseSearch"]?.string {
                            defaults.set(baseSearch, forKey: "urls-directory-baseSearch")
                        }
                    }
                    
                    if let notification = json["notification"].dictionary {
                        if let urls = notification["urls"]?.dictionary {
                            if let registration = urls["registration"]?.string {
                                defaults.set(registration, forKey: "notification-registration-url")
                            }
                            if let delivered = urls["delivered"]?.string {
                                defaults.set(delivered, forKey: "notification-delivered-url")
                            }
                        }
                    }
                    
                    // remove notifications enabled flag for this configuration until it is determined that notifications are enabled
                    defaults.removeObject(forKey: "notification-enabled")
                    
                    //Google Analytics
                    if let analytics = json["analytics"].dictionary {
                        if let ellucian = analytics["ellucian"]?.string {
                            defaults.set(ellucian, forKey:"gaTracker1")
                        }
                        if let client = analytics["client"]?.string {
                            defaults.set(client, forKey: "gaTracker2")
                        }
                    }
                    
                    if let home = json["home"].dictionary {
                        if let overlay = home["overlay"]?.string {
                            defaults.set(overlay, forKey: "home-overlay-color")
                        }
                    }

                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: ConfigurationManager.ConfigurationProcessingModulesStartedNotification, object: nil)
                        let context = CoreDataManager.sharedInstance.managedObjectContext
                        
                        var currentKeys = [String]()
                        if let modules = json["mapp"].dictionary {
                            for (key, moduleDictionary) in modules {

                                let data = LaunchBeaconDefinition(
                                    moduleKey: key,
                                    moduleDictionary: moduleDictionary,
                                    managedObjectContext: context
                                )
                                NotificationCenter.default.post(name: ConfigurationManager.ConfigurationProcessingModuleNotification, object: data)
                                
                                if self.validModuleDefinition(moduleDictionary) {
                                    let _ = Module.moduleFromJson( moduleDictionary, inManagedObjectContext: context, withKey: key, dispatchGroup: dispatchGroup)
                                    currentKeys.append(key)
                                }                                
                            }
                        }

                        let keysNoLongerUsedReqeust = NSFetchRequest<Module>(entityName: "Module")
                        keysNoLongerUsedReqeust.predicate = NSPredicate(format: "NOT (internalKey IN %@)", currentKeys)
                        
                        do {
                            let modules = try context.fetch(keysNoLongerUsedReqeust)
                            for module in modules {
                                context.delete(module)
                            }
                            do {
                                try context.save()
                            } catch {
                                print("Unable to save Managed Object context after deleting no longer used modules")
                            }
                            
                        } catch {
                            print("Unable to query for no longer used keys")
                        }
                        NotificationCenter.default.post(name: ConfigurationManager.ConfigurationProcessingModulesCompletedNotification, object: nil)
                    }
                    
                    defaults.set(Date(), forKey: "menu updated date")
                }
            }
        }
    }
    
    //way to test if configuration is complete and ready.  If not, drop the module
    func validModuleDefinition(_ dictionary: JSON) -> Bool {
        if let type = dictionary["type"].string, type == "web" {
            return dictionary["urls"] != nil
        }
        return true
    }
    //MARK: Mobile server
    
    
    func shouldMobileServerConfigurationBeRefreshed() -> Bool {
        var result = false
        
        // check if it is time to refresh
        if let defaults = AppGroupUtilities.userDefaults() {
            guard let baseConfigurationUrl = defaults.string(forKey: "mobileServerConfig-url") else {
                return false
            }
            
            if let refreshDate = defaults.object(forKey: "mobile server configuration refresh date") {
                let intervals = (Date().timeIntervalSince(refreshDate as! Date)) / refreshInterval
                result = intervals >= 1
            } else {
                return true
            }
            
            guard let lastUpdated = defaults.string(forKey: "lastUpdated-mobileServerConfiguration") else {
                return result
            }
            
            
            let configurationUrl = baseConfigurationUrl + "?onlyLastUpdated=true"
            if let theUrl = URL(string: configurationUrl) , result {
                do {
                    let configurationData = try Data(contentsOf: theUrl, options: NSData.ReadingOptions())
                    
                    
                    let jsonResults = JSON(data:configurationData)
                    let lastUpdatedFromServer = jsonResults.stringValue
                    result = lastUpdatedFromServer != lastUpdated
                    defaults.set(lastUpdatedFromServer, forKey: "lastUpdated-mobileServerConfiguration")
                    
                } catch {
                    print(error)
                }
            }
            
        }
        return result
    }
    
    func loadMobileServerConfiguration(_ completionHandler: ((_ result: Any) -> Void)?) {
        
        
        if let defaults = AppGroupUtilities.userDefaults() {
            guard let configurationUrl = defaults.string(forKey: "mobileServerConfig-url") else {
                if let completionHandler = completionHandler {
                    completionHandler(false)
                }
                return
            }
            
            // download the configuration
            if let theUrl = URL(string: configurationUrl) {
                
                let task = urlSession.downloadTask(with: theUrl) {
                    (location, response, error) in
                    
                    #if os(iOS)
                        DispatchQueue.main.async {
                            UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        }
                    #endif
                    
                    var loadSuccess = false
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode != 200 {
                            if let completionHandler = completionHandler {
                                completionHandler(loadSuccess)
                            }
                            
                            return
                        }
                    }

                    if let location = location {
                        if let _ = error {
                            print("Cannot load mobile server configuration, unable to access data from: \(location)")
                            NotificationCenter.default.post(name: ConfigurationManager.MobileServerConfigurationLoadFailedNotification, object: nil)
                        } else {
                            if let configurationData = try? Data(contentsOf: location) {
                                loadSuccess = self.processMobileServerConfiguration(configurationData)

                                NotificationCenter.default.post(name: ConfigurationManager.MobileServerConfigurationLoadSucceededNotification, object: nil)
                                
                            } else {
                                print("Cannot load mobile server configuration, unable to access data from: \(location)")
                                NotificationCenter.default.post(name: ConfigurationManager.MobileServerConfigurationLoadFailedNotification, object: nil)
                            }

                        }
                    }

                    
                    if let completionHandler = completionHandler {
                        completionHandler(loadSuccess)
                    }
                }
                task.resume()
                #if os(iOS)
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    }
                #endif
            } else {
                // failed to create NSURL
                // notify the failure
                print("Cannot load mobile server configuration, unable to create NSURL from: \"\(configurationUrl)\"")
            }
        } else {
            // No Configuration URL notify the failure
            print("Cannot load configuration, no mobile server configurationUrl")
            NotificationCenter.default.post(name: ConfigurationManager.MobileServerConfigurationLoadFailedNotification, object: nil)
        }
    }
    
    func processMobileServerConfiguration(_ responseData: Data) -> Bool {
        
        let json = JSON(data: responseData)
        
        let defaults = AppGroupUtilities.userDefaults()!
        
        if let lastUpdated = json["lastUpdated"].string {
            defaults.set(lastUpdated, forKey: "lastUpdated-mobileServerConfiguration")
        }
        
        if let codebaseVersion = json["codebaseVersion"].string {
            defaults.set(codebaseVersion, forKey: "mobileServerCodebaseVersion")
        }
        
        DispatchQueue.main.async {
            let context = CoreDataManager.sharedInstance.managedObjectContext
            
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = context
            privateContext.undoManager = nil
            
            privateContext.perform { () -> Void in
                
                do {
                    let request = NSFetchRequest<DirectoryDefinition>(entityName: "DirectoryDefinition")
                    let oldObjects = try privateContext.fetch(request)
                    
                    for object in oldObjects {
                        privateContext.delete(object)
                    }

                    for (key,subJson):(String, JSON) in json["directories"].dictionary! {
                        let directory = NSEntityDescription.insertNewObject(forEntityName: "DirectoryDefinition", into: privateContext) as! DirectoryDefinition
                        
                        if(subJson["internalName"] != nil) {
                            if let authenticated = subJson["authenticatedOnly"].string {
                                directory.authenticatedOnly = (authenticated == "true")
                            } else {
                                directory.authenticatedOnly = false
                            }
                            directory.internalName = subJson["internalName"].string
                            directory.displayName = subJson["displayName"].string
                            directory.key = key
                        }
                        
                    }
                    
                    
                    try privateContext.save()
                    
                    privateContext.parent?.perform({
                        do {
                            try privateContext.parent?.save()
                        } catch let error {
                            print (error)
                        }
                    })
                    
                    DispatchQueue.main.async {
                        if let defaults = AppGroupUtilities.userDefaults() {
                            //                                            defaults.setObject(configurationData, forKey: "mobile server configuration data")
                            defaults.set(Date(), forKey: "mobile server configuration refresh date")
                        }
                        
                    }
                    
                } catch let error {
                    print (error)
                }
            }
            
        }
        return true
    }
    
    @available(iOS 9, *)
    class func doesMobileServerSupportVersion(_ version: String) -> Bool {
        
        let defaults = AppGroupUtilities.userDefaults()!
        if let mobileServerCodebaseVersion = defaults.string(forKey: "mobileServerCodebaseVersion") {
            if version == mobileServerCodebaseVersion {
                return true
            }
            let askedVersion = version.components(separatedBy: ".")
                .map {
                    Int.init($0) ?? 0
            }
            let serverVersion = mobileServerCodebaseVersion.components(separatedBy: ".")
                .map {
                    Int.init($0) ?? 0
            }
            return askedVersion.lexicographicallyPrecedes(serverVersion)
        }
        return false //unknown
    }
}
