//
//  MapsFetchOperation.swift
//  Mobile
//
//  Created by Bret Hansen on 9/11/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class MapsFetchOperation: Operation {
    private let internalKey: String
    private let url: String
    
    var campuses: [[String: Any]] = []
    
    init(internalKey: String, url: String) {
        self.internalKey = internalKey
        self.url = url
    }
    
    override func main() {
        
        // load maps data from server
        MapsFetcher.fetch(CoreDataManager.sharedInstance.managedObjectContext, withURL: url, moduleKey: internalKey)
        
        let request = NSFetchRequest<Map>(entityName: "Map")
        request.predicate = NSPredicate(format: "moduleName = %@", internalKey)
        request.sortDescriptors = [NSSortDescriptor(key: "moduleName", ascending: true)]
        
        do {
            let maps = try CoreDataManager.sharedInstance.managedObjectContext.fetch(request)
            for map : Map in maps {
                if let campuses = map.campuses as? Set<MapCampus> {
                    for campus : MapCampus in campuses {
                        if let points = campus.points as? Set<MapPOI> {
                            var pois: [[String: Any]] = []
                            for poi in points {
                                var poiDictionary: [String: Any] = [
                                    "name": poi.name!
                                ]
                                
                                if (poi.additionalServices != nil) {
                                    poiDictionary["additionalServices"] = poi.additionalServices
                                }
                                if (poi.address != nil) {
                                    poiDictionary["address"] = poi.address
                                }
                                if (poi.description_ != nil) {
                                    poiDictionary["description"] = poi.description_
                                }
                                if (poi.latitude != nil) {
                                    poiDictionary["latitude"] = poi.latitude
                                }
                                if (poi.longitude != nil) {
                                    poiDictionary["longitude"] = poi.longitude
                                }
                                
                                pois.append(poiDictionary)
                            }
                            self.campuses.append( [
                                "name": campus.name!,
                                "buildings": pois
                                ])
                        }
                    }
                    
                }
            }
        } catch {
            print("Unable to query for Maps")
        }
    }
}
