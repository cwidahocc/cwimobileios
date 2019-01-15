//
//  DictionaryExtension.swift
//  Mobile
//
//  Created by Bret Hansen on 9/11/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func merge<K, V>(_ dictionaries: Dictionary<K, V>...) {
        for dictionary in dictionaries {
            for (key, value) in dictionary {
                self.updateValue(value as! Value, forKey: key as! Key)
            }
        }
    }
}
