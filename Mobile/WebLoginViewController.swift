//
//  WebLoginViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 5/16/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import LocalAuthentication
import JavaScriptCore

class WebLoginViewController : UIViewController, UIWebViewDelegate, LoginProtocol {
    
    @IBOutlet weak var webView: UIWebView!
    var dismissed = false
    var completionBlock: (() -> Void)?
    var context : JSContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        CurrentUser.sharedInstance.useFingerprint = false
    
        let urlString = AppGroupUtilities.userDefaults()?.string(forKey: "login-web-url")
        if let urlString = urlString {
            if let url = URL(string: urlString) {
                let request = URLRequest(url: url)
                self.webView.delegate = self
                self.webView.scalesPageToFit = true
                self.webView.loadRequest(request)
            }
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        //As soon as we can, get a reference to JSContext from the UIWebView and create the javascript EllucianMobileDevice object
        self.observeJSContext()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        //Once the page is loaded, call the EllucianMobile method _ellucianMobileInternalReady so its queue can start calling the functions.
        let jsFunction = self.context?.objectForKeyedSubscript("EllucianMobile").objectForKeyedSubscript("_ellucianMobileInternalReady")
        let _ = jsFunction?.call(withArguments: nil)
        
        if self.dismissed {
            return
        }
        let title = webView.stringByEvaluatingJavaScript(from: "document.title")!
        if (title == "Authentication Success") {
            self.sendEvent(category: .authentication, action: .login, label: "Authentication using web login", moduleName: nil)
            let _ = LoginExecutor.getUserInfo(refreshOnly: false)
            // register the device if needed
            self.dismissed = true
            if let completionBlock = self.completionBlock {
                completionBlock()
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
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
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.sendEvent(category: .authentication, action: .cancel, label: "Click Cancel")
        //For cases where the user was previously signed in and timedout and canceled the prompt
        CurrentUser.sharedInstance.logoutWithoutUpdatingUI()
        NotificationCenter.default.post(name: CurrentUser.SignInReturnToHomeNotification, object: nil)
        self.dismiss(animated: true, completion: nil)
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
