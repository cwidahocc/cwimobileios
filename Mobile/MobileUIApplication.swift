//
//  MobileUIApplication.swift
//  Mobile
//
//  Created by Jason Hocker on 2/11/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class MobileUIApplication : UIApplication {
    
    static let ApplicationTimeoutInMinutes = 30.0
    static let ApplicationDidTimeoutNotification = Notification.Name("AppTimeOut")
    static let ApplicationDidTouchNotification = Notification.Name("AppTouch")
    
    var timer : Timer?
    
    //here we are listening for any touch. If the screen receives touch, the timer is reset
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        if let _ = timer {
            self.resetIdleTimer()
        }
        if let allTouches = event.allTouches {
            if allTouches.count > 0 {
                let phase = allTouches.first?.phase
                if phase == .began {
                    self.resetIdleTimer()
                    NotificationCenter.default.post(name: MobileUIApplication.ApplicationDidTouchNotification, object: nil)
                }
            }
        }
    }
    //as labeled...reset the timer
    
    func resetIdleTimer() {
        if let timer = timer {
            timer.invalidate()
        }
        //convert the wait period into seconds rather than minutes
        let timeout = MobileUIApplication.ApplicationTimeoutInMinutes * 60
        timer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(MobileUIApplication.idleTimerExceeded), userInfo: nil, repeats: false)
    }
    
    //if the timer reaches the limit as defined in kApplicationTimeoutInMinutes, post this notification
    //the catcher of the notification will determine if any action should occur
    @objc func idleTimerExceeded() {
        
        UIApplication.shared.keyWindow?.rootViewController?.sendEvent(category: .authentication, action: .timeout, label: "Password Timeout")
        NotificationCenter.default.post(name: MobileUIApplication.ApplicationDidTimeoutNotification, object: nil)
    }
}
