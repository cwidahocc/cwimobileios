//
//  AboutVersionPageController.swift
//  Mobile
//
//  Created by Jason Hocker on 4/26/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import WatchKit
import Foundation

class AboutVersionPageController: WKInterfaceController {
    
    @IBOutlet var clientVersionLabel: WKInterfaceLabel!
    @IBOutlet var serverVersionLabel: WKInterfaceLabel!
    override func awake(withContext context: Any?) {
        if let clientVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            self.clientVersionLabel.setText(clientVersion)
        }
        
        if let urlString = AppGroupUtilities.userDefaults()?.string(forKey: "about-version-url") {
            if let url = URL(string: urlString) {
                let task =  URLSession.shared.dataTask(with: url, completionHandler : {data, response, error -> Void in
                    if let httpRes = response as? HTTPURLResponse {
                        if let data = data , httpRes.statusCode == 200 {
                            let json = JSON(data: data)
                            let application = json["application"]
                            let version = application["version"].stringValue
                            
                            DispatchQueue.main.async(execute: {
                                self.serverVersionLabel.setText(version)
                            })
                        }
                    }
                })
                task.resume()
            }
        }
    }
}
