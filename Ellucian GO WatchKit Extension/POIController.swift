//
//  POIController.swift
//  Mobile
//
//  Created by Jason Hocker on 4/26/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//


import WatchKit
import Foundation
import CoreData
import MapKit

class POIController: WKInterfaceController {
   
    
    @IBOutlet var nameLabel: WKInterfaceLabel!
    @IBOutlet var addressLabel: WKInterfaceLabel!
    @IBOutlet var descriptionLabel: WKInterfaceLabel!
    
    @IBOutlet var additionalServicesLabel: WKInterfaceLabel!
    @IBOutlet var map: WKInterfaceMap!
    
    
    override func awake(withContext context: Any?) {
        let poi = context as! Dictionary<String, AnyObject>
        
        self.nameLabel.setText(poi["name"] as? String)
        self.addressLabel.setText(poi["address"] as? String)
        self.descriptionLabel.setText(poi["description"] as? String)
        self.additionalServicesLabel.setText(poi["additionalServices"] as? String)
        
        // watch crashes if latitude is outside of -90.0 to 90.0 or longitude of -180.0 to 180.0
        var latitude = poi["latitude"] as! Double
        latitude = latitude - (Double(Int(latitude)/90) * 90.0)
        
        var longitude = poi["longitude"] as! Double
        longitude = longitude - (Double(Int(latitude)/180) * 180.0)
        
        while latitude > 90.0 {
            latitude = latitude - 90.0
        }
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        self.map.addAnnotation(location, with: .purple)
        
        self.map.setRegion(MKCoordinateRegion(center: location, span: coordinateSpan))
    }
    
}
