//
//  WKWebViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 9/6/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit
import WebKit

class WKWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, EllucianMobileLaunchableControllerProtocol, WebViewControllerProtocol {
    
    var module : Module?
    
    var webView: WKWebView?
    var webViewToLoadCookies : WKWebView? //Way to load up a starter page to get the cookies
    @objc var loadRequest : URLRequest?
    var secure = false
    @objc var analyticsLabel : String?
    var originalUrlCopy : URL?
    @IBOutlet var containerView: UIView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    @IBOutlet var stopButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIBarButtonItem!
    
    //true while we start this view.  Once we load the secure page, then we set this to false and load the page we really want.
    var booting = true
    
    // MARK: view loading
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.endEditing), name: UIViewController.SlidingViewOpenMenuAppearsNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        self.originalUrlCopy = self.loadRequest?.url
        
        let preferences = WKPreferences()
        
        let configuration = WKWebViewConfiguration()
        configuration.processPool = AppDelegate.wkProcessPool
        configuration.preferences = preferences
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
        
        addEllucianLibrary(configuration)
        
        checkIfBackgroundLoginNeeded()
        
        if let cookies = HTTPCookieStorage.shared.cookies {
            let script = getJSCookiesString(cookies: cookies)
            let cookieInScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            userContentController.addUserScript(cookieInScript)
        }
        webViewToLoadCookies = WKWebView(frame: CGRect(x:0, y:0, width:0, height:0), configuration: configuration)

        webView = WKWebView(frame: CGRect(x:0, y:0, width:containerView.frame.width, height:containerView.frame.height), configuration: configuration)
        webView?.autoresizingMask = [UIViewAutoresizing.flexibleWidth , UIViewAutoresizing.flexibleHeight]
        
        self.sendView("Display web frame", moduleName: self.analyticsLabel)
        
        
        if let webView = webView, let webViewToLoadCookies = webViewToLoadCookies, let initialRequest = self.loadRequest  {

            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
            
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webViewToLoadCookies.navigationDelegate = self
            webViewToLoadCookies.uiDelegate = self
            containerView.addSubview(webView)
            //This is to give it time to copy over the cookies before the page we really want gets loaded
            
            if let module = self.module, let property = module.property(forKey: "secure"), property == "true" {

                let urlString = AppGroupUtilities.userDefaults()?.string(forKey: "login-web-url")
                if let urlString = urlString, let url = URL(string: urlString) {
                    //web-based CAS/SAML authentication
                    let request = URLRequest(url: url)
                    webViewToLoadCookies.load(request)
                } else if !LoginExecutor.isUsingBasicAuthentication() {
                    //cas "native" 
                    webViewToLoadCookies.load(initialRequest)
                } else {
                    //basic authentication
                    webView.load(initialRequest)
                    booting = false
                }

            } else {
                webView.load(initialRequest)
                booting = false
            }
        }
    }
    
    public func getJSCookiesString(cookies: [HTTPCookie]) -> String {
        var result = ""
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
        
        for cookie in cookies {
            result += "document.cookie='\(cookie.name)=\(cookie.value); domain=\(cookie.domain); path=\(cookie.path); "
            if let date = cookie.expiresDate {
                result += "expires=\(dateFormatter.string(from: date)); "
            }
            if (cookie.isSecure) {
                result += "secure; "
            }
            result += "'; "
        }
        return result
    }
    
    func addEllucianLibrary(_ configuration: WKWebViewConfiguration) {
        //Add Ellucian library
        let scriptURL = Bundle.main.path(forResource: "ellucianmobiledevice", ofType: "js")
        var scriptContent = ""
        do {
            scriptContent = try String(contentsOfFile: scriptURL!, encoding: String.Encoding.utf8)
        } catch{
            print("Cannot Load File")
        }
        let script = WKUserScript(source: scriptContent, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(script)
        let colorScriptContent = "window.EllucianMobileDevice.primaryColor = function() { return \"\(UIColor.primary.toHexString())\"; } ; window.EllucianMobileDevice.accentColor = function() { return \"\(UIColor.accent.toHexString())\"; } ; window.EllucianMobileDevice.headerTextColor = function() { return \"\(UIColor.headerText.toHexString())\"; } ; window.EllucianMobileDevice.subheaderTextColor = function() { return \"\(UIColor.subheaderText.toHexString())\"; };"
        let colorScript = WKUserScript(source: colorScriptContent, injectionTime: .atDocumentStart, forMainFrameOnly: true) ;
        configuration.userContentController.addUserScript(colorScript)
        configuration.userContentController.add(self, name: "ellucian")
    }
    
    // MARK: user management
    func checkIfBackgroundLoginNeeded() {
        // If more than 30 minutes, do background login
        if self.secure {
            let timeNow = Date()
            let user = CurrentUser.sharedInstance
            let lastLoggedInDate = user.lastLoggedInDate
            
            if (lastLoggedInDate == nil) || timeNow.timeIntervalSince(lastLoggedInDate!) > 1800 {
                self.sendEvent(category: .authentication, action: .login, label: "Background re-authenticate", moduleName: self.analyticsLabel)
                let controller = LoginExecutor.loginController().childViewControllers[0]
                if let loginViewController = controller as? LoginViewController {
                    let responseStatusCode = loginViewController.backgroundLogin()
                    if responseStatusCode != 200 {
                        let alertController = UIAlertController(title: NSLocalizedString("Sign In Failed", comment: "title for failed sign in"), message: NSLocalizedString("The password or user name you entered is incorrect. Please try again.", comment: "message for failed sign in"), preferredStyle: .alert)
                        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK action"), style: .default, handler: {(action: UIAlertAction) -> Void in
                            user.logout(true)
                        })
                        alertController.addAction(okAction)
                        DispatchQueue.main.async {
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Button actions
    @IBAction func didTapBackButton(_ sender: AnyObject) {
        let _ = self.webView?.goBack()
    }
    
    @IBAction func didTapForwardButton(_ sender: AnyObject) {
        let _ = self.webView?.goForward()
    }
    
    @IBAction func didTapRefreshButton(_ sender: AnyObject) {
        let _ = self.webView?.reload()
    }
    
    @IBAction func didTapStopButton(_ sender: AnyObject) {
        self.webView?.stopLoading()
    }
    
    @IBAction func didTapShareButton(_ sender: AnyObject) {
        if let webView = webView, let url = webView.url {
            let activityItems = [url]
            let avc = UIActivityViewController(activityItems: activityItems, applicationActivities: [SafariActivity()])
            avc.completionWithItemsHandler = {
                (activityType, success, returnedItems, error) in
                if success {
                    if let activityType = activityType {
                        let label: String = "Tap Share Icon - \(activityType.rawValue)"
                        self.sendEventToTracker1(category: Analytics.UI_Action, action: Analytics.Invoke_Native, label: label, value: nil, moduleName: self.analyticsLabel)
                    }
                }
            }
            let buttonItem = sender as? UIBarButtonItem
            avc.popoverPresentationController?.barButtonItem = buttonItem
            self.present(avc, animated: true, completion: nil)
        }
    }
    
    // MARK: WKWebView
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let webView = self.webView {
            DispatchQueue.main.async {
                self.backButton.isEnabled = webView.canGoBack
                self.forwardButton.isEnabled = webView.canGoForward
            }
        }
        
        switch navigationAction.navigationType {
        case .linkActivated:
            if navigationAction.targetFrame == nil {
                if let _ = navigationAction.request.url {
                    //                if UIApplication.shared.canOpenURL(url) {
                    //                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    //                }
                    webView.load(navigationAction.request)
                    decisionHandler(.cancel);
                }
            }
            
        default: break
        }
        
        //Check if we should turn this URL over to OS to operate outside the app
        if let url = navigationAction.request.url {
        
            // To connnect app store
            if url.host == "itunes.apple.com" {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                    return
                }
            }
            
            
            let elements = url.absoluteString.components(separatedBy:":")
            
            if elements[0] != "http" && elements[0] != "https" {
                let application = UIApplication.shared
                if application.canOpenURL(url) {
                    application.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                    return
                }
            }
        }
    
        decisionHandler(.allow)
    
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if let response = navigationResponse.response as? HTTPURLResponse {
            var headers = [String : String]()
            for (header, value) in response.allHeaderFields {
                headers[(header as? String)!] = value as? String
            }
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: response.url!)
            
            for cookie: HTTPCookie in cookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
        decisionHandler(.allow)
        
    }
    
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        var buttonIndex: Int = 0
        for button: UIBarButtonItem in self.toolbar.items! {
            if button.tag == 3 {
                var newItems = self.toolbar.items
                newItems?[buttonIndex] = self.stopButton
                self.toolbar.items = newItems
            }
            buttonIndex += 1
        }
        self.backButton.isEnabled = self.webView!.canGoBack
        self.forwardButton.isEnabled = self.webView!.canGoForward
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let alert = alertForAuthentication(challenge: challenge, completionHandler: completionHandler) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        present(alert, animated: true, completion: nil)
    }
    
    public func alertForAuthentication(challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> UIAlertController? {
        let space = challenge.protectionSpace
        let alert: UIAlertController?
        if space.authenticationMethod == "NSURLAuthenticationMethodHTTPBasic" {
            alert = UIAlertController(title: "\(space.`protocol`!)://\(space.host):\(space.port)", message: space.realm, preferredStyle: .alert)
            alert?.addTextField {
                $0.placeholder = NSLocalizedString("User Name", comment: "User Name")
            }
            alert?.addTextField {
                $0.placeholder = NSLocalizedString("Password", comment: "Password")
                $0.isSecureTextEntry = true
            }
            alert?.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel) { _ in
                completionHandler(.cancelAuthenticationChallenge, nil)
            })
            alert?.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default) { _ in
                let textFields = alert!.textFields!
                let credential = URLCredential(user: textFields[0].text!, password: textFields[1].text!, persistence: .forSession)
                completionHandler(.useCredential, credential)
            })
        } else {
            return nil
        }
        return alert
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        handleResponse()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        if(booting) {
            handleResponse()
        } else {
            self.webView(self.webView!, didFinish: navigation)
            handleError(error)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if(booting) {
            handleResponse()
        } else {
            self.webView(self.webView!, didFinish: navigation)
            handleError(error)
        }
    }
    
    func handleResponse() {
        if(booting) {
            booting = false
            if let loadRequest = self.loadRequest {
                let _ = self.webView?.load(loadRequest)
            }
        } else {
        
            let script = "typeof EllucianMobile != 'undefined' && window.EllucianMobile._ellucianMobileInternalReady();"
            self.webView?.evaluateJavaScript(script) { (result, error) in
                if let error = error {
                    print(error)
                }
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                MBProgressHUD.hide(for: self.view, animated: true)
            }
            var buttonIndex: Int = 0
            for button in self.toolbar.items! {
                if button.tag == 3 {
                    var newItems = self.toolbar.items
                    newItems?[buttonIndex] = self.refreshButton
                    self.toolbar.items = newItems
                }
                buttonIndex += 1
            }
            self.backButton.isEnabled = self.webView!.canGoBack
            self.forwardButton.isEnabled = self.webView!.canGoForward
        }

    }
    
    private func handleError(_ swiftError: Error) {
        
        let error = swiftError as NSError
        
        if error.code == NSURLErrorCancelled {
            return
            // this is Error -999
        }
        else if error.code == 101 {
            return
            // this is Error WebKitErrorDomain
        } else if error.code == 102 {
            return
            // this is Error sometimes occuring when launching outside the app from an <a> href
        } else if error.code == NSURLErrorTimedOut {
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
                let alertController = UIAlertController(title: NSLocalizedString("Poor Network Connection", comment: "title when data cannot load due to a poor netwrok connection"), message: NSLocalizedString("Data could not be retrieved.", comment: "message when data cannot load due to a poor netwrok connection"), preferredStyle: .alert)
                let OKAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: nil)
            }
        } else {
            let titleString: String = NSLocalizedString("Error Loading Page", comment: "title when error loading webpage")
            let messageString = ((error.localizedFailureReason) != nil) ? String(format: NSLocalizedString("WebView loading error", tableName: "Localizable", bundle: Bundle.main, value: "%@ %@", comment: "WebView loading error (description failure)"), (error.localizedDescription), (error.localizedFailureReason!)) : error.localizedDescription
            let alertController: UIAlertController = UIAlertController(title: titleString, message: messageString, preferredStyle: .alert)
            let okAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
            alertController.addAction(okAction)
            DispatchQueue.main.async {
                self.present(alertController, animated: true, completion: nil)
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
    }
    
    // MARK: keyboard close
    @objc func endEditing(sender: AnyObject) {
        self.webView?.endEditing(true)
    }
    
    //MARK: WKUIDelegate
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Swift.Void) {
        let alertController = UIAlertController(title: webView.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Close", comment:"Close"), style: .cancel, handler: {(action: UIAlertAction) -> Void in
            completionHandler()
        }))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Swift.Void) {
        let alertController = UIAlertController(title: webView.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: {(action: UIAlertAction) -> Void in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment:"Cancel"), style: .cancel, handler: {(action: UIAlertAction) -> Void in
            completionHandler(false)
        }))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Swift.Void) {
        let alertController = UIAlertController(title: prompt, message: webView.url?.host, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(textField: UITextField) -> Void in
            textField.text = defaultText
        })
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: {(action: UIAlertAction) -> Void in
            let input = alertController.textFields!.first!.text
            completionHandler(input)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: {(action: UIAlertAction) -> Void in
            completionHandler(nil)
        }))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

    // if window.open is used in a website, we will instead load that page in the current webview
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        let _ = self.webView?.load(navigationAction.request)
        return nil
        
    }
}
