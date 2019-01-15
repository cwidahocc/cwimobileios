//
//  AuthenticatedRequest.swift
//  Mobile
//
//  Created by Jason Hocker on 5/13/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class AuthenticatedRequest : NSObject {
    
    var url : URL?
    var request : URLRequest?
    var data : Data?
    var response : HTTPURLResponse?
    var error : NSError?

    var dataTask: URLSessionDataTask?
    
    @objc func requestURL(_ url: URL?, fromView viewController: UIViewController?) -> Data? {
        return self.requestURL(url, fromView: viewController, addHTTPHeaderFields: nil)
    }
    
    @objc func requestURL(_ url: URL?, fromView viewController: UIViewController?, addHTTPHeaderFields headers: [String : String]?) -> Data? {
        doRequest(url: url, addHTTPHeaderFields: headers)
        
        //treat redirects from cas just like a log in is needed.  We can't detect which redirects are for cas and which are not.
        if self.error?.code == NSURLErrorUserCancelledAuthentication || self.response?.statusCode == 302 {
            presentLoginController(url: url, fromView: viewController, addHTTPHeaderFields: headers)
        } else if self.response?.statusCode == 401 {
            let controller = LoginExecutor.loginController().childViewControllers[0]
            if let loginViewController = controller as? LoginViewController {
                let responseStatusCode = loginViewController.backgroundLogin()
                if responseStatusCode != 200 {
                    presentLoginController(url: url, fromView: viewController, addHTTPHeaderFields: headers)
                } else {
                    doRequest(url: url, addHTTPHeaderFields: headers)
                    if self.error?.code == NSURLErrorUserCancelledAuthentication || self.response?.statusCode == 302 || self.response?.statusCode == 401 {
                        presentLoginController(url: url, fromView: viewController, addHTTPHeaderFields: headers)
                    }
                }
            } else {
                presentLoginController(url: url, fromView: viewController, addHTTPHeaderFields: headers)
            }
        }
        return self.data
    }
    
    func doRequest(url: URL?, addHTTPHeaderFields headers: [String : String]?) {
        self.url = url
        self.request = URLRequest(url: self.url!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 90)
        if (LoginExecutor.isUsingBasicAuthentication()) {
            self.request?.addAuthenticationHeader()
        }
        
        if let headers  = headers {
            for (name, headerValue) in headers {
                self.request?.addValue(headerValue, forHTTPHeaderField: name)
            }
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        let session = URLSession(configuration: .default)
        dataTask = session.dataTask(with: self.request! as URLRequest) {
            data, response, error in
            
            DispatchQueue.main.async() {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            if let error = error {
                print(error.localizedDescription)
                self.data = nil
                
            } else if let response = response as? HTTPURLResponse {
                self.data = data
                self.response = response
            }
            semaphore.signal()
        }
        dataTask?.resume()
        let _ = semaphore.wait(timeout: .distantFuture)
    }
    
    func presentLoginController(url: URL?, fromView viewController: UIViewController?, addHTTPHeaderFields headers: [String : String]?) {
        if let url = url {
            print("AuthenticatedRequest for url: \(url.absoluteString)")
        }
        let user: CurrentUser = CurrentUser.sharedInstance
        user.logoutWithNotification(postNotification: false, requestedByUser: false)
        
        let topViewController: UIViewController
        if let currViewController = viewController {
            topViewController = currViewController
        } else if let foundViewController = UIApplication.shared.topMostViewController() {
            topViewController = foundViewController
        } else {
            return
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        LoginExecutor.doLoginUsingController(topViewController, successCompletionHandler: {semaphore.signal()})
        let _ = semaphore.wait(timeout: .distantFuture)
        doRequest(url: url, addHTTPHeaderFields: headers)
    }
    
}

extension UIViewController {
    func topMostViewController() -> UIViewController? {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return self.keyWindow?.rootViewController?.topMostViewController()
    }
}
