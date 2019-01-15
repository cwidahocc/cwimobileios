//
//  URLSessionExtensions.swift
//  Mobile
//
//  Created by Jason Hocker on 8/5/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

extension URLSession {
    
    public func ellucianDataTask(with request: inout URLRequest) -> URLSessionDataTask {
        addEllucianHeaders(&request)
        return self.dataTask( with: request)
    }
    
    public func ellucianDataTask(with request: inout URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
        addEllucianHeaders(&request)
        return self.dataTask(with: request, completionHandler: completionHandler)
    }
    
    public func ellucianDownloadTask(with request: inout URLRequest) -> URLSessionDownloadTask {
        addEllucianHeaders(&request)
        return self.downloadTask(with: request)
    }
    
    public func ellucianDownloadTask(with request: inout URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDownloadTask {
        addEllucianHeaders(&request)
        return self.downloadTask(with: request, completionHandler: completionHandler)
    }
    
    func addEllucianHeaders(_ request: inout URLRequest) {
        if let plistPath = Bundle.main.path(forResource: "HTTP Headers", ofType: "plist"), let dictionary = NSDictionary(contentsOfFile: plistPath) as? Dictionary<String, String> {
            
            for (key, value) in dictionary {
                request.addValue(value, forHTTPHeaderField: key)
            }
            
            
        }
    }
}
