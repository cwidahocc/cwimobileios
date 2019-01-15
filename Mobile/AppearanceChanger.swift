//
//  AppearanceChanger.swift
//  Mobile
//
//  Created by Jason Hocker on 7/7/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import MapKit

//todo change to protocol? and get rid of NSObject.  Needed temporarily for objective-c interop
class AppearanceChanger {
    
    class func applyAppearanceChanges() {

        //UIKit appearance
        UINavigationBar.appearance().barTintColor = UIColor.primary
        UINavigationBar.appearance().tintColor = UIColor.headerText
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.headerText]
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).tintColor = UIColor.white

        UISearchBar.appearance().barTintColor = UIColor.primary
        UISearchBar.appearance().tintColor = UIColor.black
        
        UISegmentedControl.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.headerText
        
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.headerText], for: .normal)
        
        UIToolbar.appearance().barTintColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        
        UIToolbar.appearance().tintColor = UIColor.primary
        UITabBar.appearance().barTintColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        UITabBar.appearance().tintColor = UIColor.primary
        
        UIPageControl.appearance().backgroundColor = UIColor.primary
        
        MKPinAnnotationView.appearance().pinTintColor = UIColor.primary
        
        //Configuration Selection
        let configurationSelectionNavigationBarAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [ConfigurationSelectionNavigationController.self])
        configurationSelectionNavigationBarAppearance.barTintColor = UIColor.defaultPrimary
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [ConfigurationSelectionNavigationController.self]).tintColor = UIColor.defaultHeader
        configurationSelectionNavigationBarAppearance.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.defaultHeader]
        let configurationSelectionSearchBarAppearance = UISearchBar.appearance(whenContainedInInstancesOf: [ConfigurationSelectionViewController.self])
        configurationSelectionSearchBarAppearance.barTintColor = UIColor.defaultPrimary

        //Daily Calendar
        CalendarViewDayEventView.appearance().backgroundColor = UIColor(red: 0.30, green: 0.30, blue: 0.30, alpha: 0.85)
        CalendarViewDayEventView.appearance().fontColor = UIColor.white
        
    }
}
