//
//  DefaultsCache.swift
//  Mobile
//
//  Created by Bret Hansen on 9/21/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class DefaultsCache {
    
    private static let cacheKeysKey = "cache keys"
    private static let cacheLogoutKeysKey = "cache logout keys"
    private let key: String
    private let clearOnLogout: Bool
    private let defaults: UserDefaults
    
    init(key: String, clearOnLogout: Bool = true) {
        self.key = key
        self.clearOnLogout = clearOnLogout
        defaults = AppGroupUtilities.userDefaults()!
    }
    
    func store(_ data: Any) {
        // key track of this key so it can be cleared later
        storeKey(key, keyCacheKey: DefaultsCache.cacheKeysKey)
        
        if clearOnLogout {
            storeKey(key, keyCacheKey: DefaultsCache.cacheLogoutKeysKey)
        }
        
        print("Stored cache data for key: \(key)")
        defaults.set(data, forKey: key)
    }
    
    func fetch() -> Any? {
        return defaults.object(forKey: key)
    }

    class func clearLogoutCaches() {
        let defaults = AppGroupUtilities.userDefaults()!
        
        if let cacheOfKeys = defaults.object(forKey: cacheLogoutKeysKey) as! [String]? {
            for key in cacheOfKeys {
                defaults.removeObject(forKey: key)
                print("Cleared cache data for key: \(key)")
            }
        }
        
        // for grins remove the cache of keys too
        defaults.removeObject(forKey: cacheLogoutKeysKey)
    }
    
    class func clearAllCaches() {
        let defaults = AppGroupUtilities.userDefaults()!

        if let cacheOfKeys = defaults.object(forKey: cacheKeysKey) as! [String]? {
            for key in cacheOfKeys {
                defaults.removeObject(forKey: key)
                print("Cleared cache data for key: \(key)")
            }
        }
        
        // for grins remove the cache of keys too
        defaults.removeObject(forKey: cacheKeysKey)
        defaults.removeObject(forKey: cacheLogoutKeysKey)
    }

    private func storeKey(_ key: String, keyCacheKey: String) {
        var cacheKeys = defaults.object(forKey: keyCacheKey) as! [String]?
        if cacheKeys == nil {
            cacheKeys = [String]()
        }
        
        if !cacheKeys!.contains(key) {
            cacheKeys?.append(key)
            defaults.set(cacheKeys, forKey: keyCacheKey)
        }
    }
}
