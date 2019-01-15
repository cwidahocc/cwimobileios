//
//  UserInfo.swift
//  Mobile
//
//  Created by Jason Hocker on 1/26/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

public struct UserInfo {
    
    public static func userauth() -> String? {
        let defaults = AppGroupUtilities.userDefaults()
        if let defaults = defaults, let stored = defaults.object(forKey: "login-userauth") as! Data? {
            let decryptedData: Data!
            do {
                decryptedData = try RNCryptor.decrypt(data: stored, withPassword: "key")
            } catch _ {
                decryptedData = nil
            }
                let nsstring = NSString(data: decryptedData, encoding: String.Encoding.utf8.rawValue)
                if let userauth = nsstring as String? {
                    return userauth
                }
        }
        return nil
    }
    
    public static func userid() -> String? {
        let defaults = AppGroupUtilities.userDefaults()
        if let defaults = defaults, let stored = defaults.object(forKey: "login-userid") as! Data? {
            let decryptedData: Data!
            do {
                decryptedData = try RNCryptor.decrypt(data: stored, withPassword: "key")
            } catch _ {
                decryptedData = nil
            }
            let nsstring = NSString(data: decryptedData, encoding: String.Encoding.utf8.rawValue)
            if let userid = nsstring as String? {
                return userid
            }
        }
        return nil
    }
    
    public static func roles() -> Set<String>? {
        let defaults = AppGroupUtilities.userDefaults()
        if let defaults = defaults , let data = defaults.object(forKey: "login-roles") as? Set<String> {
            return data
        }
        return nil
    }
    
    public static func password() -> String? {
        if let userauth = UserInfo.userauth() {
            let shaUserauth = UserInfo.sha1(userauth)
            if let identifier = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String {
                let index = identifier.range(of: ".", options: .backwards)?.lowerBound
                let service = "\(identifier[..<index!])"
                do {
                    return try KeychainWrapper.getPasswordForUsername(shaUserauth, andServiceName: service)
                } catch {
                    return nil
                }
            }
        }
        
        return nil
    }
    
    static func sha1(_ input: String?) -> String? {
        if let input = input {
            let data = input.data(using: String.Encoding.utf8)!
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
            CC_SHA1((data as NSData).bytes, CC_LONG(data.count), &digest)
            let output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
            for byte in digest {
                output.appendFormat("%02x", byte)
            }
            return output as String
        }
        return nil
        
    }

}
