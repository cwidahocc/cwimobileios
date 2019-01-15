 //
 //  LoginExecutor.swift
 //  Mobile
 //
 //  Created by Jason Hocker on 5/13/16.
 //  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
 //
 
 import Foundation
 import LocalAuthentication
 
 @objc
 class LoginExecutor : NSObject {
    
    static let sharedInstance = LoginExecutor()
    
    override private init() { super.init() }
    
    class func getUserInfo(refreshOnly: Bool = false) -> Int {
        let defaults = AppGroupUtilities.userDefaults()!
        if var loginUrl = defaults.string(forKey: "login-url") {
            let authenticatedRequest: AuthenticatedRequest = AuthenticatedRequest()
            if refreshOnly {
                loginUrl = "\(loginUrl)?refresh=true"
            }
            
            let url = URL(string: loginUrl)
            var authHTTPHeader : [String : String] = [:]
            //normally we do not send basic auth headers if using native CAS, but we do in the "login".
            if let nativeCas = AppGroupUtilities.userDefaults()?.bool(forKey: "login-native-cas") , nativeCas {
                let user = CurrentUser.sharedInstance
                if let userauth = user.userauth, let password = user.getPassword() {
                    let loginString = "\(userauth):\(password)"
                    
                    let plainData = loginString.data(using: String.Encoding.utf8)
                    if let encodedLoginData = plainData?.base64EncodedString() {
                        let authHeader = "Basic ".appendingFormat("%@", encodedLoginData)
                        authHTTPHeader = ["Authorization" : authHeader]
                    }
                }
            }
            let data = authenticatedRequest.requestURL(url!, fromView: nil, addHTTPHeaderFields: authHTTPHeader)
            guard let response = authenticatedRequest.response else { return 0 }
            let httpResponse = response as HTTPURLResponse
            let responseStatusCode: Int = httpResponse.statusCode
            if let data = data, responseStatusCode == 200 {

                let json = JSON(data: data)
                let userId = json["userId"].stringValue
                let authId = json["authId"].stringValue
                let roles = json["roles"].arrayValue.map { $0.string! }
                
                let user: CurrentUser = CurrentUser.sharedInstance
                user.login(auth: authId, andUserid: userId, andRoles: roles)
                
                var headers = [String : String]()
                for (header, value) in httpResponse.allHeaderFields {
                    headers[(header as? String)!] = value as? String
                }
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: httpResponse.url!)
                for cookie: HTTPCookie in cookies {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                //save cookies
                var cookieArray: [[HTTPCookiePropertyKey : Any]] = [[HTTPCookiePropertyKey : Any]]()
                if let cookies = HTTPCookieStorage.shared.cookies {
                    for cookie in cookies {
                        var cookieProperties = [HTTPCookiePropertyKey : Any]()
                        cookieProperties[HTTPCookiePropertyKey.name] = cookie.name
                        cookieProperties[HTTPCookiePropertyKey.value] = cookie.value
                        cookieProperties[HTTPCookiePropertyKey.domain] = cookie.domain
                        cookieProperties[HTTPCookiePropertyKey.path] = cookie.path
                        cookieProperties[HTTPCookiePropertyKey.version] = cookie.version
                        if let date = cookie.expiresDate {
                            cookieProperties[HTTPCookiePropertyKey.expires] = date
                        }
                        cookieArray.append(cookieProperties)
                    }
                }
                defaults.setValue(cookieArray, forKey: "cookieArray")
                if !refreshOnly {
                    NotificationCenter.default.post(name: CurrentUser.LoginExecutorSuccessNotification, object: nil)
                }
                // register the device if needed
                NotificationManager.registerDeviceIfNeeded()
            }
            return responseStatusCode
        }
        return 0
    }
    
    class func isNativeLogin() -> Bool {
        var loginController = LoginExecutor.loginController()
        if loginController is UINavigationController {
            loginController = loginController.childViewControllers[0]
        }
        switch loginController {
        case is LoginViewController:
            return true
        default:
            return false
        }
    }
    
    class func loginController() -> UIViewController {
        let storyboard: UIStoryboard = UIStoryboard(name: "LoginStoryboard", bundle: nil)
        var vc: UIViewController
        let authenticationMode = AppGroupUtilities.userDefaults()?.string(forKey: "login-authenticationType")
        if (authenticationMode == "browser") {
            vc = storyboard.instantiateViewController(withIdentifier: "Web Login")
        }
        else {
            vc = storyboard.instantiateViewController(withIdentifier: "Login")
        }
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    
    class func doLogin(_ controller: UIViewController, successCompletionHandler: (() -> Void)? ) -> Void {
        let authenticationMode = AppGroupUtilities.userDefaults()?.string(forKey: "login-authenticationType")
        if CurrentUser.sharedInstance.useFingerprint && authenticationMode != "browser" {

            // Create the Local Authentication Context
            let touchIDContext = LAContext()
            var touchIDError : NSError?
            
            // Check if we can access local device authentication
            if touchIDContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error:&touchIDError) {
                // Check what the authentication response was
                touchIDContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("Confirm biometrics to continue", comment: "Confirm biometrics to continue"), reply: {
                    (success: Bool, error: Error?) -> Void in
                    // Check if we passed or failed
                    if success {
                        // User authenticated using Local Device Authentication Successfully!
                        
                        // Show a success alert
                        controller.sendEvent(category: .authentication, action: .login, label: "Fingerprint authentication", moduleName: nil)
                        
                        if(LoginExecutor.isNativeLogin()) {
                            CurrentUser.sharedInstance.fingerprintValid = true
                            CurrentUser.sharedInstance.isLoggedIn = true
                            let _ = self.getUserInfo(refreshOnly: false)
                            if let completionBlock = successCompletionHandler {
                                completionBlock()
                            }
                            
                        } else {
                            doLoginUsingController(controller, successCompletionHandler: successCompletionHandler)
                        }
                    } else if let error = error as? LAError {
                        // Unsuccessful
                        switch error.code {
                        case LAError.userCancel:
                            print("User Cancelled")
                        case LAError.authenticationFailed:
                            print("Authentication Failed")
                        case LAError.passcodeNotSet:
                            print("Passcode Not Set")
                        case LAError.systemCancel:
                            print("System Cancelled")
                        case LAError.userFallback:
                            print("User chose to try a password")
                            doLoginUsingController(controller, successCompletionHandler: successCompletionHandler)
                        case LAError.touchIDLockout:
                            print("TouchID lockout")
                            doLoginUsingController(controller, successCompletionHandler: successCompletionHandler)
                        default:
                            print("Unable to Authenticate!")
                        }
                    }
                })
            } else {
                // Unable to access local device authentication
                switch touchIDError!.code {
                case LAError.touchIDNotEnrolled.rawValue:
                    print("Touch ID is not enrolled")
                case LAError.touchIDNotAvailable.rawValue:
                    print("Touch ID not available")
                case LAError.passcodeNotSet.rawValue:
                    print("Passcode has not been set")
                default:
                    print("Local Authentication not available")
                }
                doLoginUsingController(controller, successCompletionHandler: successCompletionHandler)
            }
        } else {
            doLoginUsingController(controller, successCompletionHandler: successCompletionHandler)
        }
    }
    
    class func doLoginUsingController(_ controller: UIViewController, successCompletionHandler: (() -> Void)? ) -> Void {
        let loginController = LoginExecutor.loginController()
        var loginProtocol = loginController.childViewControllers[0] as! LoginProtocol
        if let successCompletionHandler = successCompletionHandler {
            loginProtocol.completionBlock = successCompletionHandler
        }
        loginController.modalPresentationStyle = UIModalPresentationStyle.formSheet
        controller.present(loginController, animated: true, completion: nil)
        
    }
    
    class func isUsingBasicAuthentication() -> Bool {
        let defaults = AppGroupUtilities.userDefaults()!
        let authenticationMode = defaults.string(forKey: "login-authenticationType")
        if authenticationMode == nil { //old configuration that didn't report this
            return true
        }
        if authenticationMode! == "native" {
            if defaults.bool(forKey: "login-native-cas") {
                return false //native login with cas backend
            } else {
                return true
            }
        }
        return false
    }
    
 }
 
