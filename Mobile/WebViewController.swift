//
//  WebViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 7/21/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import JavaScriptCore

class WebViewController : UIViewController, UIWebViewDelegate, WebViewControllerProtocol {
    var module : Module?
    var loadRequest : URLRequest?
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIBarButtonItem!
    
    @IBOutlet var actionButton: UIBarButtonItem!
    @IBOutlet var webView: UIWebView!
    
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var stopButton: UIBarButtonItem!
    
    var actionSheetUrl : URL?
    var secure = false
    var analyticsLabel : String?
    var originalUrl : String!
    
    var loadingUrl : URL?
    var originalUrlCopy : URL?
    var context : JSContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.endEditing), name: UIViewController.SlidingViewOpenMenuAppearsNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.originalUrlCopy = self.loadRequest?.url
        self.sendView("Display web frame", moduleName: self.analyticsLabel)
        let user = CurrentUser.sharedInstance
        let lastLoggedInDate = user.lastLoggedInDate
        let timeNow = Date()
        // If more than 30 minutes, do background login
        if self.secure {
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
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
        if let loadRequest = self.loadRequest {
            self.webView.loadRequest(loadRequest)
        }
    }
    
    func loginUser(data: Data, andPassword password: String) {
        
        let json = JSON(data: data)
        let userId = json["userId"].stringValue
        let authId = json["authId"].stringValue
        let roles = json["roles"].arrayValue.map { $0.string!}
        let user: CurrentUser = CurrentUser.sharedInstance
        user.login(auth: authId, andPassword: password, andUserid: userId, andRoles: roles, andRemember: false, fingerprint: false)
    }
    
    @IBAction func didTapBackButton(_ sender: AnyObject) {
        self.webView.goBack()
    }
    
    @IBAction func didTapForwardButton(_ sender: AnyObject) {
        self.webView.goForward()
    }
    
    @IBAction func didTapRefreshButton(_ sender: AnyObject) {
        self.webView.reload()
    }
    
    @IBAction func didTapShareButton(_ sender: AnyObject) {
        let activityItems = [self.URL().absoluteString]
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
        let buttonItem: UIBarButtonItem = (sender as! UIBarButtonItem)
        avc.popoverPresentationController?.barButtonItem = buttonItem
        self.present(avc, animated: true, completion: nil)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        //As soon as we can, get a reference to JSContext from the UIWebView and create the javascript EllucianMobileDevice object
        self.observeJSContext()
        self.loadingUrl = request.mainDocumentURL
        self.backButton.isEnabled = self.webView.canGoBack
        self.forwardButton.isEnabled = self.webView.canGoForward
        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
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
        self.backButton.isEnabled = self.webView.canGoBack
        self.forwardButton.isEnabled = self.webView.canGoForward
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        //Once the page is loaded, call the EllucianMobile method _ellucianMobileInternalReady so its queue can start calling the functions.
        let jsFunction = self.context?.objectForKeyedSubscript("EllucianMobile").objectForKeyedSubscript("_ellucianMobileInternalReady")
        let _ = jsFunction?.call(withArguments: nil)
        self.loadingUrl = nil
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
        self.backButton.isEnabled = self.webView.canGoBack
        self.forwardButton.isEnabled = self.webView.canGoForward
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.loadingUrl = nil
        self.webViewDidFinishLoad(self.webView)
        handleError(error)
        
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
        }
        else {
            let titleString: String = NSLocalizedString("Error Loading Page", comment: "title when error loading webpage")
            let messageString = ((error.localizedFailureReason) != nil) ? String(format: NSLocalizedString("WebView loading error", tableName: "Localizable", bundle: Bundle.main, value: "%@ %@", comment: "WebView loading error (description failure)"), (error.localizedDescription), (error.localizedFailureReason!)) : error.localizedDescription
            let alertController: UIAlertController = UIAlertController(title: titleString, message: messageString, preferredStyle: .alert)
            let okAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK action"), style: .default, handler: nil)
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func didTapStopButton(_ sender: AnyObject) {
        self.webView.stopLoading()
    }
    
    func URL() -> URL {
        return self.loadingUrl ?? (self.webView.request?.mainDocumentURL)!
    }
    
    
    @objc func endEditing(sender: AnyObject) {
        self.webView.endEditing(true)
    }
    
    //https://gist.github.com/shuoshi/f1757a7aa7ab8ec67483
    func observeJSContext() {
        let runLoop = CFRunLoopGetCurrent()
        // This is a idle mode of RunLoop, when UIScrollView scrolls, it jumps into "UITrackingRunLoopMode"
        // and won't perform any cache task to keep a smooth scroll.
        let runLoopMode = CFRunLoopMode.defaultMode
        
        let observer = CFRunLoopObserverCreateWithHandler( kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 0,{ obs, act in
            let context = self.webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext
            if self.context != context {
                CFRunLoopRemoveObserver(runLoop, obs, runLoopMode)
                self.context = context
                //Once the JSContext was established, define the EllucianMobileDevice object, and send console.log to the native log.
                context?.setObject( WebViewJavascriptInterface.self, forKeyedSubscript: "EllucianMobileDevice" as NSString)
                
                let logFunction : @convention(block) (String) -> Void =
                    {
                        (msg: String) in
                        
                        print("Web Console.log: \(msg)")
                }
                context?.objectForKeyedSubscript("console").setObject(unsafeBitCast(logFunction, to: AnyObject.self),
                                                                      forKeyedSubscript: "log" as NSString)
                
                //once page loads call EllucianMobile._ellucianMobileInternalReady in webViewDidFinishLoad
                //calling here too in case the javascript is ready to receive this call
                let js: String = "typeof EllucianMobile != 'undefined' && EllucianMobile._ellucianMobileInternalReady()"
                let _ = self.webView.stringByEvaluatingJavaScript(from: js)
            }
        })
        CFRunLoopAddObserver(runLoop, observer, runLoopMode)
        
    }
}
