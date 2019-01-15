//
//  Analytics.swift
//  Mobile
//
//  Created by Jason Hocker on 7/12/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

@objc class Analytics : NSObject {
    
    //For objective-c compatibility

        @objc static let Authentication = "Authentication"
        @objc static let Courses = "Courses"
        @objc static let UI_Action = "UI_Action"
        @objc static let Push_Notification = "Push_Notification"
        @objc static let Widget = "Widget"

    
    
        @objc static let Button_Press = "Button_Press"
        @objc static let Cancel = "Cancel"
        @objc static let Follow_web = "Follow_web"
        @objc static let Invoke_Native = "Invoke_Native"
        @objc static let List_Select = "List_Select"
        @objc static let Login = "Login"
        @objc static let Logout = "Logout"
        @objc static let Menu_selection = "Menu_selection"
        @objc static let Search = "Search"
        @objc static let Slide_Action = "Slide_Action"
        @objc static let Timeout = "Timeout"
        @objc static let ReceivedMessage = "Received_Message"
 

    
    enum Category : String {
        case authentication = "Authentication"
        case courses = "Courses"
        case ui_Action = "UI_Action"
        case push_Notification = "Push_Notification"
        case widget = "Widget"
        case location = "Location"
    }
    
    enum Action : String {
        case button_Press = "Button_Press"
        case cancel = "Cancel"
        case follow_web = "Follow_web"
        case invoke_Native = "Invoke_Native"
        case list_Select = "List_Select"
        case login = "Login"
        case logout = "Logout"
        case menu_selection = "Menu_selection"
        case search = "Search"
        case slide_Action = "Slide_Action"
        case timeout = "Timeout"
        case receivedMessage = "Received_Message"
        case launch = "Launch"
        case mute = "Mute"
        case notify = "Notify"
        case resetMute = "Reset_Mute"
    }
    
    enum Label : String {
        case beaconNotify = "User notified of beacon"
        case beaconLaunch = "Module launched from beacon"
        case beaconMuteForever = "User muted beacon notification"
        case beaconMuteForToday = "User temporarily muted beacon notification"
        case resetMute = "User reset their muted beacon notifications"
    }
}
