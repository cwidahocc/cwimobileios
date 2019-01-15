//
//  WebViewJavascriptInterface.swift
//  Mobile
//
//  Created by Jason Hocker on 7/22/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol WebViewJavascriptExports : JSExport {

    // Logs a message to the native app's log
    static func log(_ message: String)
    
    // Synchronously call to get roles.  Returns a success flag.
    static func refreshRoles() -> Bool
    
    // Open the first menu item found with that name and type.  Exported as "openMenu" to the javascript.
    static func openMenu(_ name: String, _ type: String)
    
    //Causes the web frame to load the original URL defined for this module.
    static func reloadWebModule()
    
    static func primaryColor() -> String
    static func headerTextColor() -> String
    static func accentColor() -> String
    static func subheaderTextColor() -> String
}

class WebViewJavascriptInterface : NSObject, WebViewJavascriptExports {
    
    // MARK: Ellucian Mobile 3.8
    class func log(_ message: String) {
        print("\(message)")
    }
    
    static func refreshRoles() -> Bool {
        var success = -1
        if Thread.isMainThread {
            success = LoginExecutor.getUserInfo(refreshOnly: true)
        }
        else {
            DispatchQueue.main.sync {
                success =  LoginExecutor.getUserInfo(refreshOnly: true)
            }
        }
        return success == 200
    }
    
    static func openMenu(_ name: String, _ type: String) {
        let operation = OpenModuleOperation(name: name, type: type)
        OperationQueue.main.addOperation(operation)
    }
    
    static func reloadWebModule() {
        let webView = self.webViewController()?.webView
        webView?.loadRequest(URLRequest(url: (self.webViewController()?.originalUrlCopy!)!))
    }
    
    private static func slidingViewController() -> ECSlidingViewController {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.slidingViewController!
    }
    
    private static func webViewController() -> WebViewController? {
        let topController: AnyObject = self.slidingViewController().topViewController!
        if (topController is WebViewController) {
            return (topController as! WebViewController)
        }
        else if (topController is UINavigationController) {
            let navigationController: UINavigationController = (topController as! UINavigationController)
            let webViewController = navigationController.childViewControllers.last as? WebViewController
            return webViewController
        }
        else if (topController is UISplitViewController) {
            let splitViewController: UISplitViewController = (topController as! UISplitViewController)
            let detailController: AnyObject = splitViewController.childViewControllers[1]
            if (detailController is WebViewController) {
                return (detailController as! WebViewController)
            }
            else if (detailController is UINavigationController) {
                let navigationController: UINavigationController = (detailController as! UINavigationController)
                let webViewController = navigationController.childViewControllers.last! as? WebViewController
                return webViewController
            }
        }
        
        return nil
    }
    
    // MARK: Ellucian Mobile 4.5
    static func primaryColor() -> String {
        return UIColor.primary.toHexString()
    }
    
    static func headerTextColor() -> String {
        return UIColor.headerText.toHexString()
    }
    
    static func accentColor() -> String {
        return UIColor.accent.toHexString()
    }
    
    static func subheaderTextColor() -> String {
        return UIColor.subheaderText.toHexString()
    }
}
