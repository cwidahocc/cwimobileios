//
//  CurrentUser.swift
//  Mobile
//
//  Created by Jason Hocker on 7/8/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WebKit
import UserNotifications

let kAES256Key = "key"

let kLoginRoles: String = "login-roles"

let kLoginRemember: String = "login-remember"

let kLoginUserauth: String = "login-userauth"

let kLoginUserid: String = "login-userid"

let kLoginUseFingerprint: String = "login-fingerprint"


class CurrentUser : NSObject { //TODO objc interop
    
    @objc static let SignInReturnToHomeNotification = Notification.Name("SignInReturnToHomeNotification")
    @objc static let SignOutNotification = Notification.Name("SignOutNotification")
    @objc static let SignInNotification = Notification.Name("SignInNotification")
    @objc static let LoginExecutorSuccessNotification = Notification.Name("Login Executor Success")

    @objc static let sharedInstance = CurrentUser()
    
    var userauth : String?
    @objc var userid : String?

//    private var password : String?

    @objc var isLoggedIn: Bool
    @objc var roles = [String]()
    var remember: Bool
    var lastLoggedInDate : Date?
    var email : String?

    var useFingerprint : Bool {
        get {
            let defaults = UserDefaults.standard
            return defaults.bool(forKey: kLoginUseFingerprint)
        }
        set {
            let defaults = UserDefaults.standard
            defaults.set(newValue, forKey: kLoginUseFingerprint)
        }
    }
    var fingerprintValid = false
    
    override init() {

        let defaults = AppGroupUtilities.userDefaults()
        if let defaultsUserauth = defaults?.data(forKey: kLoginUserauth) {
            if let decryptedUserAuthData = try? RNCryptor.decrypt(data: defaultsUserauth, withPassword: kAES256Key) {
                self.userauth = String(data: decryptedUserAuthData, encoding: .utf8)
            }
        }
        if let defaultsUserid = defaults?.data(forKey: kLoginUserid) {
            if let decryptedUseridData = try? RNCryptor.decrypt(data: defaultsUserid, withPassword: kAES256Key) {
                self.userid = String(data: decryptedUseridData, encoding: .utf8)
            }
        }

        if let roles = defaults?.object(forKey: kLoginRoles) as? [String] {
            self.roles = roles
        }
        
        self.remember = (defaults?.bool(forKey: kLoginRemember))!

        self.isLoggedIn = false
        super.init() //todo objc interop
        if let _ = self.userauth {
            if let password = getPassword(), !password.isEmpty {
                if self.remember {
                    self.isLoggedIn = true
                }
            }
        }
    }
    
    func logoutWithoutUpdatingUI() {
        self.logoutWithNotification(postNotification: false, requestedByUser: true)
    }
    
    func logout(_ requestedByUser: Bool) {
        self.logoutWithNotification(postNotification: true, requestedByUser: requestedByUser)
    }
    
    func logoutWithNotification(postNotification: Bool, requestedByUser: Bool) {
        let defaults = AppGroupUtilities.userDefaults()!
        
        if !self.useFingerprint {
            
            defaults.removeObject(forKey: kLoginRoles)
            defaults.removeObject(forKey: kLoginRemember)
            defaults.removeObject(forKey: kLoginUserid)
            defaults.removeObject(forKey: kLoginUserauth)

            UserDefaults.standard.removeObject(forKey: kLoginUseFingerprint)
            self.useFingerprint = false
            if let userauth = self.userauth {
                do {
                    try KeychainWrapper.deleteItem(forUsername: userauth.sha1(), andServiceName: (Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String))
                } catch {
                    //No password recorded
                }
                self.userauth = nil
            }
        }

        self.isLoggedIn = false
        self.userid = nil
        self.roles = [String]()
        self.remember = false
        //remove persisted cookies
        let cookies = HTTPCookieStorage.shared
        if let allCookies = cookies.cookies {
            //remove all cookies persisted in app groups
            defaults.removeObject(forKey: "cookieArray")
            for cookie in allCookies {
                cookies.deleteCookie(cookie)
            }
        }
        
        //WKWebView
        let websiteDataTypes = Set<String>( [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeCookies])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: date, completionHandler:{ })
        
        self.removeSensitiveData(requestedByUser: requestedByUser)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
        if postNotification {
            NotificationCenter.default.post(name: CurrentUser.SignOutNotification, object: nil)
        }
        WatchConnectivityManager.sharedInstance.userLoggedOut(true)
        
        let logoutUrl = defaults.string(forKey: "logout-url")
        if let logoutUrl = logoutUrl {
    
            var request = URLRequest(url: URL(string: logoutUrl)!)
            request.httpMethod = "POST"
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if data == nil {
                    if let error = error {
                        print("logout error=\(error)")
                        return
                    }
                }
            }
            task.resume()
        }
    }
    
    func login(auth: String, andPassword pass: String, andUserid uID: String, andRoles roleSet: [String], andRemember remember: Bool, fingerprint: Bool) {
        self.userauth = auth
        self.userid = uID
        self.roles = roleSet
        self.isLoggedIn = true
        self.remember = remember
        self.useFingerprint = fingerprint
        if self.useFingerprint {
            self.fingerprintValid = true
        }
        //logging in the user stores the user in the keychain
        
        try! KeychainWrapper.storeUsername(self.userauth!.sha1(), andPassword: pass, forServiceName: (Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String), updateExisting: true)
        let defaults = AppGroupUtilities.userDefaults()
        //set the new config for about
        defaults?.set(roleSet, forKey:kLoginRoles)
        defaults?.set(self.remember, forKey: kLoginRemember)
        UserDefaults.standard.set(self.useFingerprint, forKey: kLoginUseFingerprint)
        var encryptedUserAuthData = self.userauth?.data(using: .utf8)
        encryptedUserAuthData = RNCryptor.encrypt(data: encryptedUserAuthData!, withPassword: kAES256Key)
        defaults?.set(encryptedUserAuthData, forKey: kLoginUserauth)
        
        var encryptedUserIdData = self.userid?.data(using: .utf8)
        encryptedUserIdData = RNCryptor.encrypt(data: encryptedUserIdData!, withPassword: kAES256Key)
        defaults?.set(encryptedUserIdData, forKey: kLoginUserid)

        self.lastLoggedInDate = Date()
        NotificationCenter.default.post(name: CurrentUser.SignInNotification, object: nil)
        WatchConnectivityManager.sharedInstance.userLoggedIn(self.userAsPropertyListDictionary(), notifyOtherSide: true)
    }
    
    func login(auth: String, andUserid uID: String, andRoles roleSet: [String]) {
        self.userauth = auth
        self.userid = uID
        self.roles = roleSet
        self.isLoggedIn = true

        let defaults = AppGroupUtilities.userDefaults()
        //set the new config for about
        defaults?.set(roleSet, forKey:kLoginRoles)
        var encryptedUserAuthData = self.userauth?.data(using: .utf8)
        encryptedUserAuthData = RNCryptor.encrypt(data: encryptedUserAuthData!, withPassword: kAES256Key)
        defaults?.set(encryptedUserAuthData, forKey: kLoginUserauth)
        
        var encryptedUserIdData = self.userid?.data(using: .utf8)
        encryptedUserIdData = RNCryptor.encrypt(data: encryptedUserIdData!, withPassword: kAES256Key)
        defaults?.set(encryptedUserIdData, forKey: kLoginUserid)
        
        self.lastLoggedInDate = Date()
        NotificationCenter.default.post(name: CurrentUser.SignInNotification, object: nil)
        WatchConnectivityManager.sharedInstance.userLoggedIn(self.userAsPropertyListDictionary(), notifyOtherSide: true)
    }
    
    func userAsPropertyListDictionary() -> [String : Any] {
        var userDictionary = [String : Any]()
        if let userid = self.userid {
            userDictionary["userid"] = userid
        }
        userDictionary["isLoggedIn"] = self.isLoggedIn
        userDictionary["roles"] = self.roles
        if let email = self.email {
            userDictionary["email"] = email
        }
        if let lastLoggedInDate = self.lastLoggedInDate {
            userDictionary["lastLoggedInDate"] = lastLoggedInDate
        }
        return userDictionary
    }
    
    func getPassword() -> String? {
        do {
            let password = try KeychainWrapper.getPasswordForUsername(self.userauth!.sha1(), andServiceName: (Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as!  String))
            return password
        } catch {
            //Not present
            return nil;
        }
    }

    func getRoles() -> [String] {
        if self.isLoggedIn {
            let defaults = AppGroupUtilities.userDefaults()
            //set the new config for about
            return defaults?.array(forKey: "roles") as! [String]
        }
        else {
            return [String]()
        }
    }
    
    func removeSensitiveData(requestedByUser: Bool) {
        let entities = ["CourseAnnouncement", "CourseDetail", "CourseEvent", "CourseRoster", "CourseTerm", "GradeTerm", "Notification"]
        for entity: String in entities {
            self.removeData(entity: entity)
            if (entity == "Notification") {
                NotificationCenter.default.post(name: NotificationsFetcher.NotificationsUpdatedNotification, object: nil)
            }
        }
        if requestedByUser {
            self.removeData(entity: "CourseAssignment")
            let appGroupUserDefaults = AppGroupUtilities.userDefaults()
            appGroupUserDefaults?.removeObject(forKey: "today-widget-assignments")
            appGroupUserDefaults?.synchronize()
        }
    }
    
    private func removeData(entity: String) {
        let appDelegate = (UIApplication.shared.delegate as! AppDelegate)
        let managedObjectContext: NSManagedObjectContext = appDelegate.managedObjectContext
        let request = NSFetchRequest<NSManagedObject>()
        request.entity = NSEntityDescription.entity(forEntityName: entity, in: managedObjectContext)
        request.includesPropertyValues = false
        //only fetch the managedObjectID
        if let objects = try? managedObjectContext.fetch(request) {
            for object in objects {
                managedObjectContext.delete(object)
            }
        }
        try! managedObjectContext.save()
    }
    
    func reset() {
        self.userauth = nil
        self.userid = nil
        self.isLoggedIn = false
        self.roles = [String]()
        self.remember = false
        self.lastLoggedInDate = nil
        self.email = nil
        self.useFingerprint = false
        self.fingerprintValid = false
    }
    
    func showLoginChallenge() -> Bool {
        if !self.isLoggedIn {
            return true
        }
        else if self.useFingerprint && !self.fingerprintValid {
            return true
        }
        
        return false
    }
}
