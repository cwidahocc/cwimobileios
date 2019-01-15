//
//  MapsController.swift
//  Mobile
//
//  Created by Jason Hocker on 4/26/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import WatchKit
import Foundation
import CoreData


class MapsController: WKInterfaceController {
    
    @IBOutlet var noCampusesLabel: WKInterfaceLabel!
    @IBOutlet var mapsTable: WKInterfaceTable!
    @IBOutlet var spinner: WKInterfaceImage!
    @IBOutlet var retrievingDataLabel: WKInterfaceLabel!
    var campuses : [Dictionary<String, AnyObject>]!
    var internalKey : String?
    var urlString : String?
    
    var cache: DefaultsCache?
    
    override func awake(withContext context: Any?) {
        let dictionary = context! as! Dictionary<String, AnyObject>
        self.internalKey = dictionary["internalKey"] as? String
        self.setTitle(dictionary["title"] as? String)
        self.urlString = dictionary["campuses"] as? String
        
        cache = DefaultsCache(key: "maps campuses \(internalKey!)", clearOnLogout: false)
        
        fetchMaps()
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        if (segueIdentifier == "maps buildings list") {
            return self.campuses![rowIndex]
        }
        return nil
    }
    
    func populateTable() {
        
        mapsTable.setNumberOfRows(self.campuses.count, withRowType: "CampusTableRowController")
        
        var haveMapsData = false
        
        self.campuses.sort() {
            return ($0["name"] as! String) < ($1["name"] as! String)
        }

        for (index, campus) in campuses.enumerated() {
            haveMapsData = true
            let row = mapsTable.rowController(at: index) as! CampusTableRowController
            row.campusNameLabel.setText(campus["name"] as! String!)
        }
        
        noCampusesLabel.setHidden(haveMapsData)
    }
    
    func fetchMaps() {
        
        var data: [String: String] = [:]
        
        if let urlString = self.urlString {
            data["url"] = urlString
        }
        if let internalKey = self.internalKey {
            data["internalKey"] = internalKey
        }
        
        if let campuses = cache?.fetch() as! [[String:AnyObject]]? {
            self.campuses = campuses
            self.populateTable()
            
            self.retrievingDataLabel.setHidden(true)
            self.spinner.stopAnimating()
            self.spinner.setHidden(true)
        } else {
            // show the spinner because we don't have data yet
            retrievingDataLabel.setHidden(false)
            self.spinner.startAnimating()
            self.spinner.setHidden(false)
        }
        
        WatchConnectivityManager.sharedInstance.sendActionMessage("fetch maps", data: data, replyHandler: {
            (data) -> Void in
            
            DispatchQueue.main.async(execute: {
                self.retrievingDataLabel.setHidden(true)
                self.spinner.stopAnimating()
                self.spinner.setHidden(true)
                
                self.campuses = data["campuses"] as! [[String:AnyObject]]
                self.cache?.store(self.campuses)
                self.populateTable()
            })
            }, errorHandler: {
                (error) -> Void in
                
                DispatchQueue.main.async(execute: {
                    self.retrievingDataLabel.setHidden(true)
                    self.spinner.stopAnimating()
                    self.spinner.setHidden(true)
                    // show error message
                })
        })
    }
}
