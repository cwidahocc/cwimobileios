//
//  AppDelegate.swift
//  AppDelegateMaker
//
//  Created by Jason Hocker on 2/11/16.
//  Copyright © 2016 Ellucian. All rights reserved.
//

import UIKit
import CoreData
import WebKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let localNotification = Notification.Name("GoLocalNotification")
    static let wkProcessPool = WKProcessPool()
    private var reachability : Reachability!
    
    var window: UIWindow?
    
    var openModuleWhenActiveModuleKey: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {

        bootstrapReachability()
        
        let _ = WatchConnectivityManager.sharedInstance.ensureWatchConnectivityInitialized()
        
        // boot strap Launch Beacon Manager
        //this is where notifications are getting configured now
        LaunchBeaconManager.start()
        
        NSSetUncaughtExceptionHandler { exception in
            print("uncaught exception: \(exception.description)")
            print(exception.callStackSymbols)
        }
        
        
        //bootstrap notification
        UNUserNotificationCenter.current().delegate = NotificationManager.shared

        //Google Analytics
        bootstrapGoogleAnalytics()
                
        migrateToSharedAppGroup()
        
        bootstrapMenu()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationDidTimeout(_:)), name: MobileUIApplication.ApplicationDidTimeoutNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.applicationDidTouch(_:)), name: MobileUIApplication.ApplicationDidTouchNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.returnHome(_:)), name: CurrentUser.SignOutNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.returnHome(_:)), name: CurrentUser.SignInReturnToHomeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.forceConfigurationSelection(_:)), name: ConfigurationFetcher.ConfigurationFetcherErrorNotification, object: nil)
        let currentUser = CurrentUser.sharedInstance
        if currentUser.isLoggedIn && logoutOnStartup != false {
            if currentUser.useFingerprint {
                currentUser.fingerprintValid = false
            } else if !currentUser.remember {
                currentUser.logout( false)
            }
        }
        
        // for when swapping the application in, honor the current logged in/out state
        logoutOnStartup = false
        
        forceUpgradeOnVersionChange()
        
        //no longer using badge number.  reset to zero for users who upgrade
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            let _ = handleShortcut(shortcutItem)
            return false
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        if (CurrentUser.sharedInstance.useFingerprint) {
            //save time
            if let defaults = AppGroupUtilities.userDefaults() {
                defaults.setValue(Date(), forKey: "applicationDidEnterBackgroundDate")
            }
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if (CurrentUser.sharedInstance.useFingerprint && CurrentUser.sharedInstance.fingerprintValid) {
            //compare time
            if let defaults = AppGroupUtilities.userDefaults() {
                if let date = defaults.value(forKey: "applicationDidEnterBackgroundDate") as? Date {
                    let minutes = (Date().timeIntervalSince(date)) / 60
                    CurrentUser.sharedInstance.fingerprintValid = minutes <= 5
                } else {
                    CurrentUser.sharedInstance.fingerprintValid = false
                }
            }
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if let _ = AppGroupUtilities.userDefaults() {
            if AppDelegate.openURL != true {
                NotificationCenter.default.post(name: ConfigurationSelectionViewController.ConfigurationListRefreshIfPresentNotification, object: nil)
            }
            AppDelegate.openURL = false
            
            if LoginExecutor.isUsingBasicAuthentication() {
                let currentUser = CurrentUser.sharedInstance
                if currentUser.isLoggedIn && !currentUser.remember && !currentUser.useFingerprint
                {
                    if let timestampLastActivity = timestampLastActivity {
                        let compareDate = timestampLastActivity.addingTimeInterval(MobileUIApplication.ApplicationTimeoutInMinutes * 60)
                        let currentDate = Date()
                        if (compareDate.compare(currentDate) == .orderedAscending) || (logoutOnStartup != false) {
                            if let controller = UIApplication.shared.keyWindow?.rootViewController {
                                controller.sendEvent(category: .authentication, action: .timeout, label: "Password Timeout")
                            }
                            currentUser.logout( false)
                        }
                    }
                }
                
            }
            
        }
        
        if openModuleWhenActiveModuleKey != nil {
            // Notification from tray action occurred while not active, if openModuleWhenActiveModuleKey is set then open it
            let operation: OpenModuleOperation = OpenModuleOperation(id: openModuleWhenActiveModuleKey!)
            OperationQueue.main.addOperation(operation)
            openModuleWhenActiveModuleKey = nil
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        let currentUser = CurrentUser.sharedInstance
        if currentUser.isLoggedIn && !currentUser.remember && !currentUser.useFingerprint {
            currentUser.logout( false)
        }
        
        self.saveContext()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        AppDelegate.openURL = true
        
        let urlComponents = URLComponents(string: url.absoluteString)
        let type = urlComponents?.host
        let queryItems = urlComponents?.queryItems
        
        let pathComponents = url.pathComponents
        if (type == "mobilecloud") {
            if pathComponents.count >= 2 {
                
                let scheme = pathComponents[1]
                let host = pathComponents[2]
                
                let newPath = pathComponents[3...].joined(separator: "/")
                
                let components = NSURLComponents()
                components.scheme = scheme
                components.host = host
                components.path = "/\(newPath)"
                let newUrl = components.url
                
                let defaults = AppGroupUtilities.userDefaults()
                defaults?.set(newUrl?.absoluteString, forKey: "mobilecloud-url")
                let storyboard: UIStoryboard = UIStoryboard(name: "ConfigurationSelectionStoryboard", bundle: nil)
                let navcontroller = storyboard.instantiateViewController(withIdentifier: "ConfigurationSelector") as! UINavigationController
                let vc = navcontroller.childViewControllers[0] as! ConfigurationSelectionViewController
                vc.modalPresentationStyle = .fullScreen
                self.window?.rootViewController = navcontroller
            }
        }
        else if (type == "configuration") {
            if pathComponents.count >= 2 {
                let scheme = pathComponents[1]
                let host = pathComponents[2]
                let newPath = pathComponents[3...].joined(separator: "/")
                
                CurrentUser.sharedInstance.logoutWithoutUpdatingUI()
                self.window?.rootViewController?.dismiss(animated: false, completion: nil)
                let passcode = queryItems?.filter({$0.name == "passcode"}).first?.value
                DispatchQueue.main.async(execute: {() -> Void in
                    let storyboard: UIStoryboard = UIStoryboard(name: "HomeStoryboard", bundle: nil)
                    let vc: UIViewController = storyboard.instantiateViewController(withIdentifier: "Loading")
                    self.window?.rootViewController = vc
                    DispatchQueue.main.async(execute: {() -> Void in
                        self.loadConfigurationInBackground(scheme, host: host, newPath: newPath, passcode: passcode)
                    })
                })
            }
            
        }
        else if (type == "module-type") {
            if pathComponents.count >= 1 {
                if (pathComponents[1] == "ilp") {
                    UIApplication.shared.keyWindow?.rootViewController?.sendEvent(category: .widget, action: .list_Select, label: "Assignments")
                    self.window?.rootViewController?.dismiss(animated: false, completion: nil)
                    let operation: OpenModuleOperation = OpenModuleOperation(type: "ilp")
                    if let urlToAssignment = queryItems?.filter({$0.name == "url"}).first
                    {
                        //sign in will not pass a url to open
                        operation.properties = ["requestedAssignmentId": urlToAssignment.value!]
                    }
                    OperationQueue.main.addOperation(operation)
                }
            }
        }
        
        return true
    }
    
    // MARK: - 3d touch
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem))
    }
    
    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        let shortcutType = shortcutItem.type
        
        let operation: OpenModuleOperation = OpenModuleOperation(id: shortcutType)
        
        OperationQueue.main.addOperation(operation)
        return true
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file.
        return (AppGroupUtilities.applicationDocumentsDirectory()! as URL)
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        return CoreDataManager.sharedInstance.managedObjectContext;
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        CoreDataManager.sharedInstance.save()
    }
    
    // MARK: Noficiations
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("Application deviceToken: \(deviceTokenString)")
        NotificationManager.registerDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to get token, error: \(error)")
    }

    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
        self.application(application, didReceiveRemoteNotification: userInfo) { (UIBackgroundFetchResult) in
            
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Swift.Void) {
        
        let uuid = userInfo["uuid"] as? String
        if let uuid = uuid {
            print("didReceiveRemoteNotification - for uuid: \(uuid)")
        }
        if application.applicationState == .active {
            print("application active - show notification message alert")
            // log activity to Google Analytics
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.sendEvent(category: .push_Notification, action: .receivedMessage, label: "whileActive")
            }
            
            if let aps = userInfo["aps"] as? NSDictionary {
                //                if let alert = aps["alert"] as? NSDictionary {
                //                    if let message = alert["message"] as? NSString {
                //                        //Do stuff
                //                    }
                //                } else
                if let alertMessage = aps["alert"] as? String {
                    let alert: UIAlertController = UIAlertController(title: NSLocalizedString("New Notification", comment: "new notification has arrived"), message: alertMessage, preferredStyle: .alert)
                    let view: UIAlertAction = UIAlertAction(title: NSLocalizedString("View", comment: "view label"), style: .default, handler: {(action: UIAlertAction) -> Void in
                        let operation: OpenModuleOperation = OpenModuleOperation(type: "notifications")
                        if let uuid = uuid {
                            operation.properties = ["uuid": uuid]
                        }
                        OperationQueue.main.addOperation(operation)
                    })
                    let cancel: UIAlertAction = UIAlertAction(title: NSLocalizedString("Close", comment: "Close"), style: .cancel, handler: {(action: UIAlertAction) -> Void in
                        alert.dismiss(animated: true, completion: nil)
                    })
                    alert.addAction(cancel)
                    alert.addAction(view)
                    self.window?.makeKeyAndVisible()
                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            // navigate to notifications
            print("application not active - open from notifications")
            // log activity to Google Analytics
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.sendEvent(category:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      .push_Notification, action: .receivedMessage, label: "whileInActive")
            }
            self.window?.rootViewController?.dismiss(animated: false, completion: nil)
            let operation: OpenModuleOperation = OpenModuleOperation(type: "notifications")
            if let uuid = uuid {
                operation.properties = ["uuid": uuid]
            }
            OperationQueue.main.addOperation(operation)
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        var result = false
        if userActivity.activityType == "com.ellucian.go.open.module" {
            if let moduleKey = userActivity.userInfo?["moduleKey"] as! String? {
                let operation: OpenModuleOperation = OpenModuleOperation(id: moduleKey)
                OperationQueue.main.addOperation(operation)
                if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                    rootViewController.sendEvent(category: Analytics.Category.location, action: Analytics.Action.launch, label: Analytics.Label.beaconLaunch.rawValue)
                    result = true
                }
            }
        }
        
        return result
    }
    
    // MARK: - Ellucian Mobile
    var slidingViewController : ECSlidingViewController?
    var timestampLastActivity : Date?
    var logoutOnStartup = true
    static var openURL = false
    
    var useDefaultConfiguration: Bool {
        
        if let plistPath = Bundle.main.path(forResource: "Customizations", ofType: "plist"), let customizationsDictionary = NSDictionary(contentsOfFile: plistPath) as? Dictionary<String, AnyObject> {
            
            let useDefaultConfiguration = customizationsDictionary["Use Default Configuration"] as! Bool
            return useDefaultConfiguration
        } else {
            return false
        }
    }
    
    var defaultConfigUrl : String? {
        
        if let plistPath = Bundle.main.path(forResource: "Customizations", ofType: "plist"), let customizationsDictionary = NSDictionary(contentsOfFile: plistPath) as? Dictionary<String, AnyObject> {
            
            if let url = customizationsDictionary["Default Configuration URL"] {
                return url as? String
            }
            
        }
        return nil
        
    }
    
    var allowSwitchSchool: Bool {
        
        if let plistPath = Bundle.main.path(forResource: "Customizations", ofType: "plist"), let customizationsDictionary = NSDictionary(contentsOfFile: plistPath) as? Dictionary<String, AnyObject> {
            
            let allowSwitchSchool = customizationsDictionary["Allow Switch School"] as! Bool
            return allowSwitchSchool
        } else {
            return true
        }
    }
    
    func reset() {
        print("reset")
        let sharedCache: URLCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        URLCache.shared = sharedCache
        let appDomain = Bundle.main.bundleIdentifier
        //must persist this property when switching configurations
        if let appGroupDefaults = AppGroupUtilities.userDefaults() {
            let cloudUrl = appGroupDefaults.string(forKey: "mobilecloud-url")
            let appVersion = appGroupDefaults.string(forKey: "app-version")
            let didMigrateToAppGroups = UserDefaults.standard.bool(forKey: "didMigrateToAppGroups")
            let appGroupDefaultsDictionary = appGroupDefaults.dictionaryRepresentation()
            
            UserDefaults.standard.removePersistentDomain(forName: appDomain!)
            for key: String in appGroupDefaultsDictionary.keys {
                appGroupDefaults.removeObject(forKey: key)
            }
            
            if let cloudUrl = cloudUrl {
                appGroupDefaults.set(cloudUrl, forKey: "mobilecloud-url")
            }
            if let appVersion = appVersion {
                appGroupDefaults.set(appVersion, forKey: "app-version")
            }
            
            UserDefaults.standard.set(didMigrateToAppGroups, forKey: "didMigrateToAppGroups")
            
        }
        
        CurrentUser.sharedInstance.logoutWithoutUpdatingUI()
        CurrentUser.sharedInstance.reset()
        CoreDataManager.sharedInstance.reset()
        ImageCache.sharedCache.reset()
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications() // To remove all delivered notifications
        center.removeAllPendingNotificationRequests() // To remove all pending notifications which are not delivered yet but scheduled.
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        UIApplication.shared.shortcutItems = nil
    }
    
    func loadDefaultConfiguration(_ defaultConfigUrl: String) {
        if let hudView = self.window?.rootViewController?.view {
            let hud = MBProgressHUD.showAdded(to: hudView, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let manager = ConfigurationManager.shared
                manager.loadConfiguration(configurationUrl: defaultConfigUrl, completionHandler: {(result: Any) -> Void in
                    DispatchQueue.main.async(execute: {() -> Void in
                        MBProgressHUD.hide(for: hudView, animated: true)
                        if result is Bool && (result as! Bool) {
                            AppearanceChanger.applyAppearanceChanges()
                            OperationQueue.main.addOperation(OpenModuleHomeOperation())
                        }
                    })
                })
            }
        }
    }
    
    func loadConfigurationInBackground(_ scheme: String, host: String, newPath: String, passcode: String?) {
        let components = NSURLComponents()
        components.scheme = scheme
        components.host = host
        components.path = "/\(newPath)"
        
        if let passcode = passcode {
            components.queryItems = [ URLQueryItem(name: "passcode", value: passcode)]
        }
        
        let newUrl = components.url
        
        if let prefs = AppGroupUtilities.userDefaults() {
            prefs.set(newUrl?.absoluteString, forKey: "configurationUrl")
        }
        loadConfigurationInBackground(newUrl!)
    }
    
    func loadConfigurationInBackground(_ url: URL) {
        self.reset()
        let manager = ConfigurationManager.shared
        manager.loadConfiguration(configurationUrl: url.absoluteString, completionHandler:  {(result: Any) -> Void in
            
            manager.loadMobileServerConfiguration() {
                (result2) in
                
                DispatchQueue.main.async(execute: {() -> Void in
                    
                    var resultBool = false
                    if result is NSNumber {
                        let num = result as! NSNumber
                        resultBool = num.boolValue
                    }
                    
                    if let prefs = AppGroupUtilities.userDefaults() {
                        prefs.removeObject(forKey: "configurationUrl")
                        prefs.set(url.absoluteString, forKey: "configurationUrl")
                    }
                    
                    if resultBool || self.useDefaultConfiguration {
                        AppearanceChanger.applyAppearanceChanges()
                        //the case may be that the user was on the modal "configuration selection" screen.  dismiss in case that's the case.
                        self.window?.rootViewController?.dismiss(animated: false, completion: nil)
                        let storyboard: UIStoryboard = UIStoryboard(name: "HomeStoryboard", bundle: nil)
                        let slidingVC = storyboard.instantiateViewController(withIdentifier: "SlidingViewController") as! ECSlidingViewController
                        slidingVC.anchorRightRevealAmount = 276
                        slidingVC.anchorLeftRevealAmount = 276
                        slidingVC.topViewAnchoredGesture = [ECSlidingViewControllerAnchoredGesture.tapping , ECSlidingViewControllerAnchoredGesture.panning]
                        let menu: UIViewController = storyboard.instantiateViewController(withIdentifier: "Menu")
                        
                        let direction: UIUserInterfaceLayoutDirection = UIView.userInterfaceLayoutDirection(for: slidingVC.view.semanticContentAttribute)
                        if direction == .rightToLeft {
                            slidingVC.underRightViewController = menu
                        }
                        else {
                            slidingVC.underLeftViewController = menu
                        }
                        
                        self.window?.rootViewController = slidingVC
                        self.slidingViewController = slidingVC
                        OperationQueue.main.addOperation(OpenModuleHomeOperation())
                    }
                    else {
                        let storyboard: UIStoryboard = UIStoryboard(name: "ConfigurationSelectionStoryboard", bundle: nil)
                        let navcontroller = storyboard.instantiateViewController(withIdentifier: "ConfigurationSelector") as! UINavigationController
                        let vc = navcontroller.childViewControllers[0] as! ConfigurationSelectionViewController
                        vc.modalPresentationStyle = .fullScreen
                        DispatchQueue.main.async(execute: {() -> Void in
                            self.window?.rootViewController = navcontroller
                            ConfigurationFetcher.showErrorAlertView(controller: navcontroller)
                        })
                    }
                    
                })
            }
        })
    }
    
    // MARK: responds to notification center
    @objc func applicationDidTimeout(_ notif: Notification) {
        print("time exceeded!!")
        let currentUser = CurrentUser.sharedInstance
        if (currentUser.isLoggedIn) {
            if (currentUser.remember) {
                () //do nothing
            } else if (currentUser.useFingerprint) {
                //                currentUser.fingerprintValid = false
                () //do nothing
            } else {
                if let authenticationMode = AppGroupUtilities.userDefaults()!.string(forKey: "login-authenticationType") {
                    if authenticationMode == "native" {
                        currentUser.logout( false)
                    }
                } else {
                    currentUser.logout( false)
                }
            }
        }
        
    }
    
    @objc func applicationDidTouch(_ notif: Notification) {
        timestampLastActivity = Date()
    }
    
    @objc func returnHome(_ sender: AnyObject) {
        AppearanceChanger.applyAppearanceChanges()
        OperationQueue.main.addOperation(OpenModuleHomeOperation())
    }
    
    @objc func forceConfigurationSelection(_ sender: AnyObject) {
        DispatchQueue.main.async(execute: {() -> Void in
            if let rootViewController = self.window?.rootViewController {
                ConfigurationFetcher.showErrorAlertView(controller: rootViewController)
                AppearanceChanger.applyAppearanceChanges()
                OperationQueue.main.addOperation(OpenModuleConfigurationSelectionOperation())
            }
        })
    }
    
    func bootstrapGoogleAnalytics() {
        let gai = GAI.sharedInstance()
        gai?.trackUncaughtExceptions = true
        gai?.dispatchInterval = 20
        gai?.logger.logLevel = GAILogLevel.error
    }
    
    func forceUpgradeOnVersionChange() {
        if let prefs = AppGroupUtilities.userDefaults() {
            if let _ = prefs.string(forKey: "configurationUrl") {
                
                //reload if upgrading app version
                let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                
                if prefs.string(forKey: "app-version") != currentVersion {
                    prefs.set(currentVersion, forKey: "app-version")
                    if self.useDefaultConfiguration && !self.allowSwitchSchool, let defaultConfigUrl = self.defaultConfigUrl {
                        prefs.set(defaultConfigUrl, forKey: "configurationUrl")
                    }
                    
                    DispatchQueue.main.async(execute: {() -> Void in
                        let storyboard: UIStoryboard = UIStoryboard(name: "HomeStoryboard", bundle: nil)
                        let vc: UIViewController = storyboard.instantiateViewController(withIdentifier: "Loading")
                        self.window?.rootViewController = vc
                        DispatchQueue.main.async(execute: {() -> Void in
                            self.loadConfigurationInBackground(URL(string: prefs.string(forKey: "configurationUrl")!)!)
                        })
                    })
                }
                
                AppearanceChanger.applyAppearanceChanges()
                OperationQueue.main.addOperation(OpenModuleHomeOperation())
                
            } else {
                if prefs.string(forKey: "app-version") == nil {
                    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                    prefs.set(currentVersion, forKey: "app-version")
                }
                
                if self.useDefaultConfiguration {
                    prefs.set(self.defaultConfigUrl, forKey: "configurationUrl")
                    self.loadDefaultConfiguration(self.defaultConfigUrl!)
                } else {
                    let storyboard: UIStoryboard = UIStoryboard(name: "ConfigurationSelectionStoryboard", bundle: nil)
                    let navcontroller = storyboard.instantiateViewController(withIdentifier: "ConfigurationSelector") as! UINavigationController
                    let vc = navcontroller.childViewControllers[0] as! ConfigurationSelectionViewController
                    vc.modalPresentationStyle = .fullScreen
                    self.window?.rootViewController = navcontroller
                    AppearanceChanger.applyAppearanceChanges()
                    
                }
            }
        }

    }
    
    func bootstrapReachability() {
        reachability = Reachability()!
        
        reachability.whenReachable = { reachability in
            DispatchQueue.main.async {
                if reachability.isReachableViaWiFi {
                    print("Reachable via WiFi")
                } else {
                    print("Reachable via Cellular")
                }
            }
        }
        reachability.whenUnreachable = { reachability in
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: nil, message: NSLocalizedString("You are unable to connect to retrieve information. The Internet connection seems to be down.", comment: "message to user when network is not present"), preferredStyle: .alert)
                let okAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
                alertController.addAction(okAction)
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start reachability notifier")
        }

    }
    
    func migrateToSharedAppGroup() {
        if !UserDefaults.standard.bool(forKey: "didMigrateToAppGroups") {
            var oldDefaults = UserDefaults.standard.dictionaryRepresentation()
            
            for key: String in oldDefaults.keys {
                AppGroupUtilities.userDefaults()?.set(oldDefaults[key], forKey: key)
            }
            if let appDomain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: appDomain)
                UserDefaults.standard.set(true, forKey: "didMigrateToAppGroups")
            }
        }
    }
    
    func bootstrapMenu() {
        let slidingViewController = self.window?.rootViewController as? ECSlidingViewController
        if let slidingViewController = slidingViewController {
            self.slidingViewController = slidingViewController
            slidingViewController.anchorRightRevealAmount = 276
            slidingViewController.anchorLeftRevealAmount = 276
            slidingViewController.topViewAnchoredGesture = [ECSlidingViewControllerAnchoredGesture.tapping , ECSlidingViewControllerAnchoredGesture.panning]
            let storyboard = UIStoryboard(name: "HomeStoryboard", bundle: nil)
            let menu: UIViewController = storyboard.instantiateViewController(withIdentifier: "Menu")
            
            
            let direction: UIUserInterfaceLayoutDirection = UIView.userInterfaceLayoutDirection(for: (self.window?.rootViewController!.view.semanticContentAttribute)!)
            if direction == .rightToLeft {
                slidingViewController.underRightViewController = menu
            } else {
                slidingViewController.underLeftViewController = menu
            }
        }
    }
}
