//
//  OpenModuleOperation.swift
//  Mobile
//
//  Created by Jason Hocker on 6/29/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class OpenModuleOperation: OpenModuleAbstractOperation {

    private var module : Module?
    private var moduleName : String?
    private var moduleType : String?
    private var moduleId : String?
    var properties = [String : Any]()

    init (module: Module?) {
        self.module = module
    }

    init(name: String?, type: String?, id: String?) {
        self.moduleName = name
        self.moduleType = type
        self.moduleId = id
    }

    convenience init(name: String, type: String) {
        self.init(name: name, type: type, id: nil)
    }

    convenience init(type: String) {
        self.init(name: nil, type: type, id: nil)
    }


    convenience init(id: String) {
        self.init(name: nil, type: nil, id: id)
    }

    override func main() {
        if module == nil {
            if let moduleId = moduleId {
                self.module = ModuleManager.findModule(moduleId)
            } else {
                self.module = ModuleManager.findModule(name: moduleName, type: moduleType)
            }
        }
        if let module = module {

            if module.requiresAuthentication() && CurrentUser.sharedInstance.showLoginChallenge()  {
                DispatchQueue.main.async(execute: {

                    let slidingViewController = self.findSlidingViewController()

                    LoginExecutor.doLogin(slidingViewController, successCompletionHandler: {
                        self.openModule(module)
                        }
                    )

                })
            } else {
                openModule(module)
            }
        }
    }

    private func findAndShowController(_ definition: Dictionary<String, AnyObject>, isEllucian: Bool) {
        var storyboardName = definition["Storyboard Name"] as! String?
        var storyboardIdentifier : String?
        if storyboardName != nil {

            storyboardIdentifier = definition["Storyboard Identifier"] as! String?

        } else {
            if UI_USER_INTERFACE_IDIOM() == .pad {
                storyboardIdentifier = definition["iPad Storyboard Identifier"] as! String?
                storyboardName = definition["iPad Storyboard Name"] as! String?

                if storyboardName == nil {
                    storyboardName = isEllucian ? "MainStoryboard_iPad" as String? : "CustomizationStoryboard_iPad" as String?
                }
            } else {
                storyboardIdentifier = definition["iPhone Storyboard Identifier"] as! String?
                storyboardName = definition["iPhone Storyboard Name"] as! String?

                if storyboardName == nil {
                    storyboardName = isEllucian ? "MainStoryboard_iPhone" as String? : "CustomizationStoryboard_iPhone" as String?
                }
            }
        }

        if let storyboardName = storyboardName, let storyboardIdentifier = storyboardIdentifier {
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: storyboardIdentifier)

            setModuleOnController(controller)
            addPropertiesToController(controller, properties: properties)

            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: UIViewController.SlidingViewChangeTopControllerNotification, object: nil)
                self.showViewController(controller)
            })

        }
    }

    func setModuleOnController(_ controller: UIViewController?) {
        if let controller = controller {
            if controller is EllucianMobileLaunchableControllerProtocol {
                controller.setValue(module, forKey: "module")
            }

            switch controller {
            case is UITabBarController:
                let tabController = controller as! UITabBarController
                if let controllers = tabController.viewControllers {
                    for c in controllers {
                        setModuleOnController(c)
                    }
                }
            case is UINavigationController:
                let navController = controller as! UINavigationController
                if let topViewController = navController.topViewController {
                    setModuleOnController(topViewController)
                }
            case is UISplitViewController:
                let splitController = controller as! UISplitViewController
                for c in splitController.viewControllers {
                    setModuleOnController(c)
                }

            default: ()
            }
        }
    }

    private func addPropertiesToController(_ controller: UIViewController, properties: [String: Any]) {
        for (key, value) in properties {
            controller.setValue(value, forKey: key)
        }
    }

    private func openModule(_ module: Module) {
        var match = false
        if module.roles.count == 0 { //upgrades from 3.0 or earlier
            match = true
        }
        let moduleRoles = Array(module.roles)
        let filteredRoles = moduleRoles.filter {
            let role = $0 as! ModuleRole
            if role.role == "Everyone" {
                return true
            }
            let roles = CurrentUser.sharedInstance.roles
            if(roles.count > 0) {
                for tempRole in roles {
                    if tempRole == role.role {
                        return true;
                    }
                }
                return false;
            }
            return false
        }

        if filteredRoles.count > 0 {
            match = true
        }

        if !match {
            DispatchQueue.main.async(execute: {
                self.showAccessDeniedAlert()
            })
            return
        }

        if module.type == "header" {
            return
        } else if module.type == "web" {
            if let property = module.property(forKey: "external") , property == "true" {
                DispatchQueue.main.async(execute: {
                    if let url = URL(string: module.property(forKey: "url")!) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                })
            } else {
                let storyboard = UIStoryboard(name: "WebStoryboard", bundle: nil)
                var webController : WebViewControllerProtocol?
                if LoginExecutor.isUsingBasicAuthentication() {
                    webController = storyboard.instantiateViewController(withIdentifier: "Web") as? WKWebViewController
                } else {
                    webController = storyboard.instantiateViewController(withIdentifier: "UIWeb") as? WebViewController
                }
                if var webController = webController {
                    let controller = UINavigationController(rootViewController: webController as! UIViewController)
                    if let url = URL(string: module.property(forKey: "url")!) {
                        webController.loadRequest = URLRequest(url: url)
                        webController.title = module.name
                        var secure = false
                        if let secureProperty = module.property(forKey: "secure") {
                            secure = secureProperty == "true"
                        }

                        webController.secure = secure
                        webController.analyticsLabel = module.name
                        webController.module = module

                        showViewController(controller)
                    }
                }
            }
        } else if module.type == "appLauncher" {
            if let urlString = module.property(forKey: "appUrl") {
                 UIApplication.shared.open(URL(string: urlString)!, options: [:], completionHandler: {
                        (success) in
                    if !success {
                        if let urlString = module.property(forKey: "storeUrl") {
                            
                            let alertController = UIAlertController(title: NSLocalizedString("Install App", comment: "Install App title"), message: NSLocalizedString("You do not have the required app. Would you like to install it?", comment: "You do not have the required app. Would you like to install it? message"), preferredStyle: .alert)
                            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default) { (action) in
                                UIApplication.shared.open(URL(string: urlString)!, options: [:], completionHandler: nil)
                            }
                            alertController.addAction(okAction)
                            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil)
                            alertController.addAction(cancelAction)
                            
                            DispatchQueue.main.async(execute: {
                                let slidingViewController = self.findSlidingViewController()
                                slidingViewController.underLeftViewController.show(alertController, sender: nil)
                            })
                            
                            
                        } else {
                            let alertController = UIAlertController(title: NSLocalizedString("Unsupported", comment: "Unsupported alert title"), message: NSLocalizedString("There are no installed applications available to respond to this request.", comment: "Targeted app not installed alert message"), preferredStyle: .alert)
                            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
                            alertController.addAction(okAction)
                            DispatchQueue.main.async(execute: {
                                let slidingViewController = self.findSlidingViewController()
                                slidingViewController.underLeftViewController.show(alertController, sender: nil)
                            })
                        }
                    }
                 })
                
            } else {
                let alertController = UIAlertController(title: NSLocalizedString("Unavailable Application", comment: "Unavailable Application alert title"), message: NSLocalizedString("This application is not available on iOS.", comment: "Unsupported feature alert message"), preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
                alertController.addAction(okAction)
                DispatchQueue.main.async(execute: {
                    let slidingViewController = self.findSlidingViewController()
                    slidingViewController.underLeftViewController.show(alertController, sender: nil)
                })
            }
        } else if module.type == "custom" {
            if let customModuleType = module.property(forKey: "custom-type") {

                if let customizationsPath = Bundle.main.path(forResource: "Customizations", ofType: "plist"), let customizationsDictionary = NSDictionary(contentsOfFile: customizationsPath) as? Dictionary<String, AnyObject> {

                    let customModuleDefinitions = customizationsDictionary["Custom Modules"] as! Dictionary<String, AnyObject>
                    let moduleDefinition = customModuleDefinitions[customModuleType] as! Dictionary<String, AnyObject>

                    findAndShowController(moduleDefinition, isEllucian: false)
                }
            }
        } else {
            if let ellucianPath = Bundle.main.path(forResource: "EllucianModules", ofType: "plist"), let ellucianDictionary = NSDictionary(contentsOfFile: ellucianPath) as? Dictionary<String, AnyObject> {

                let moduleDefinitions = ellucianDictionary
                let moduleDefinition = moduleDefinitions[module.type] as! Dictionary<String, AnyObject>
                findAndShowController(moduleDefinition, isEllucian: true)
            }
        }
    }

    private func showAccessDeniedAlert() {
        let slidingViewController = self.findSlidingViewController()
        let topController = slidingViewController.topViewController

        let alertController = UIAlertController(title: NSLocalizedString("Access Denied", comment:"access denied error message"), message: NSLocalizedString("You do not have permission to use this feature.", comment:"permission access error message"), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default)  { (action) in
            if let topController = topController as? UINavigationController {
                let childController = topController.childViewControllers[0]
                if childController is HomeViewController {
                    DispatchQueue.main.async(execute: {
                        OperationQueue.main.addOperation(OpenModuleHomeOperation())
                    })
                }
            }
        }
        alertController.addAction(cancelAction)
        topController?.present(alertController, animated: true, completion: nil)
    }
}
