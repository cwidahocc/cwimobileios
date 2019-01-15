//
//  EllucianJSWKScriptMessageHandler.swift
//  Mobile
//
//  Created by Jason Hocker on 9/13/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import WebKit

extension WKWebViewController {

    @objc(userContentController:didReceiveScriptMessage:)
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "ellucian" {
            let body = message.body as! [String : Any]
            switch body["name"] as! String {
            case "log":
                log(body["message"] as! String)
            case "openMenu":
                openMenu(name: body["moduleName"] as! String, type: body["moduleType"] as! String)
            case "refreshRoles":
                refreshRoles()
            case "reloadWebModule":
                reloadWebModule(body)
            case "primaryColor":
                primaryColor()
            case "accentColor":
                accentColor()
            case "headerTextColor":
                headerTextColor()
            case "subheaderTextColor":
                subheaderTextColor()
            default:
                ()
            }
        }
    }
    
    func log(_ text : String) {
        print(text)
    }
    
    func openMenu(name: String, type: String) {
        let operation = OpenModuleOperation(name: name, type: type )
        OperationQueue.main.addOperation(operation)
    }
    
    func refreshRoles() {
        if Thread.isMainThread {
            let _  = LoginExecutor.getUserInfo(refreshOnly: true)
        }
        else {
            DispatchQueue.main.sync {
                let _  = LoginExecutor.getUserInfo(refreshOnly: true)
            }
        }
    }
    
    func reloadWebModule(_ body: [String : Any]) {
        let _ = self.webView?.load(URLRequest(url: (self.originalUrlCopy!)))
    }
    func primaryColor() {
        let script = "window.EllucianMobileDevice.color = \"\(UIColor.primary)\";"
        webView?.evaluateJavaScript(script)
    }
    func accentColor() {
        let script = "window.EllucianMobileDevice.color = \"\(UIColor.accent)\";"
        webView?.evaluateJavaScript(script)
    }
    func headerTextColor() {
        let script = "window.EllucianMobileDevice.color = \"\(UIColor.headerText)\";"
        webView?.evaluateJavaScript(script)
    }
    func subheaderTextColor() {
        let script = "window.EllucianMobileDevice.color = \"\(UIColor.subheaderText)\";"
        webView?.evaluateJavaScript(script)
    }
}
