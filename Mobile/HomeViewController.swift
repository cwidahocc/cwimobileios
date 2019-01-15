//
//  HomeViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 1/25/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class HomeViewController : UIViewController {
    
    @objc var backgroundImageView : UIImageView!
    
    @IBOutlet var menu1: UIView!
    @IBOutlet var menu2: UIView!
    @IBOutlet var menu3: UIView!
    @IBOutlet var menu4: UIView!
    @IBOutlet var menu5: UIView!
    
    @IBOutlet var blurredImageView: UIView!
    @IBOutlet var menuView: UIView!
    
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet var lightVisualEffectView: UIVisualEffectView!
    @IBOutlet var darkVisualEffectView: UIVisualEffectView!
    
    @IBOutlet var animationConstraint: NSLayoutConstraint!
    
    var modules: [Module]?
    
    var originalImage : UIImage?
    
    @IBOutlet var cwrhMenu1Constraint: NSLayoutConstraint!
    @IBOutlet var cwrhMenu2Constraint: NSLayoutConstraint!
    @IBOutlet var cwrhMenu3Constraint: NSLayoutConstraint!
    @IBOutlet var cwrhMenu4Constraint: NSLayoutConstraint!
    
    
    @IBOutlet var anyMenu1Constraint: NSLayoutConstraint!
    @IBOutlet var anyMenu2Constraint: NSLayoutConstraint!
    @IBOutlet var anyMenu3Constraint: NSLayoutConstraint!
    @IBOutlet var anyMenu4Constraint: NSLayoutConstraint!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.animationConstraint.priority =  UILayoutPriority(rawValue: UILayoutPriority.RawValue(Int(UILayoutPriority.defaultHigh.rawValue) + 1))
        
        if let navigationController = self.navigationController {
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navigationController.navigationBar.shadowImage = UIImage()
            navigationController.navigationBar.isTranslucent = true
            navigationController.view.backgroundColor = UIColor.clear
            navigationController.navigationBar.backgroundColor = UIColor.clear
            
        }
        
        let defaults = AppGroupUtilities.userDefaults()
        var schoolBackgroundImage = defaults?.string(forKey: "home-background")
        if let homeTabletBackground = defaults?.string(forKey: "home-tablet-background"), !homeTabletBackground.isEmpty {
            if UIDevice.current.userInterfaceIdiom == .pad {
                schoolBackgroundImage = homeTabletBackground
            }
        }
        if let schoolBackgroundImage = schoolBackgroundImage {
            ImageCache.sharedCache.getImage(schoolBackgroundImage) {
                (image: UIImage?) in
                
                if image != nil {
                    print("HomeViewController got background image")
                    DispatchQueue.main.async {
                    self.backgroundImageView.image = image
                    self.originalImage = image
                    }
                } else {
                    print("HomeViewController background image missing")
                }
            }
        }
        
        if let color = defaults?.string(forKey: "home-overlay-color") {
            if color == "light" {
                lightVisualEffectView.isHidden = false
            } else if color == "dark" {
                darkVisualEffectView.isHidden = false
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        let buildMenuOperation = OpenModuleFindModulesOperation()
        buildMenuOperation.limitToHomeScreen = true
        buildMenuOperation.completionBlock = {
            DispatchQueue.main.async(execute: {
                self.modules = buildMenuOperation.modules
                self.drawMenu()
                self.view.setNeedsDisplay()
                
                self.view.layoutIfNeeded()
                UIView.animate(withDuration: 0.5, animations: {() -> Void in
                    self.animationConstraint.priority = UILayoutPriority.defaultLow
                    self.view.layoutIfNeeded()
                })
                
            })
        }
        OperationQueue.main.addOperation(buildMenuOperation)
        
        self.sendView("Show Home Screen", moduleName: nil)
    }
    
    func drawMenu() {
        if let modules = self.modules {

            var shortcuts = [UIApplicationShortcutItem]()
            for index in 0..<modules.count {
                let module = modules[index]
                let shortcutItem = UIApplicationShortcutItem(type: module.internalKey, localizedTitle: module.name)
                shortcuts.append(shortcutItem)
            }
            UIApplication.shared.shortcutItems = shortcuts
            
            let menuItemCount = min(modules.count, 5) //in case cloud ever returns more than 5
            let menuViews = [menu1, menu2, menu3, menu4, menu5];
            
            switch menuItemCount {
            case 1:
                anyMenu1Constraint.priority = UILayoutPriority(rawValue: 995)
                cwrhMenu1Constraint.priority = UILayoutPriority(rawValue: 995)
            case 2:
                anyMenu2Constraint.priority = UILayoutPriority(rawValue: 995)
                cwrhMenu2Constraint.priority = UILayoutPriority(rawValue: 995)
            case 3:
                anyMenu3Constraint.priority = UILayoutPriority(rawValue: 995)
                cwrhMenu3Constraint.priority = UILayoutPriority(rawValue: 995)
            case 4:
                anyMenu4Constraint.priority = UILayoutPriority(rawValue: 995)
                cwrhMenu4Constraint.priority = UILayoutPriority(rawValue: 995)
            default:
                ()
            }
            
            for index in 0..<menuItemCount {
                let module = modules[index]
                if let cell = menuViews[index] {
                    cell.isHidden = false
                    
                    if let nameLabel = cell.viewWithTag(101) as? UILabel {
                        nameLabel.text = module.name
                        nameLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
                        nameLabel.layer.shadowColor = UIColor.black.cgColor
                        nameLabel.layer.shadowOpacity = 0.7
                        nameLabel.layer.shadowRadius = 1
                        cell.accessibilityLabel = module.name
                    }
                    if let imageView = cell.viewWithTag(102) as? UIImageView {
                        if let iconUrl = module.iconUrl , !module.iconUrl.isEmpty {
                            imageView.image = ImageCache.sharedCache.getCachedImage(iconUrl)
                            imageView.layer.shadowOffset = CGSize(width: 0, height: 1)
                            imageView.layer.shadowColor = UIColor.black.cgColor
                            imageView.layer.shadowOpacity = 0.4
                            imageView.layer.shadowRadius = 1
                            if UIDevice.current.userInterfaceIdiom == .pad {
                                
                                
                                if let iconBackgroundView = cell.viewWithTag(4) {
                                    
                                    let layer = iconBackgroundView.layer
                                    
                                    iconBackgroundView.layer.cornerRadius = iconBackgroundView.frame.size.width/2
                                    iconBackgroundView.clipsToBounds = true
                                    
                                    let gradientLayer = CAGradientLayer()
                                    gradientLayer.frame =  CGRect(origin: CGPoint.zero, size: layer.bounds.size)
                                    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
                                    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
                                    gradientLayer.colors =  [UIColor.clear.cgColor,UIColor.white.cgColor]
                                    
                                    let shapeLayer = CAShapeLayer()
                                    shapeLayer.lineWidth  = 1
                                    shapeLayer.path = UIBezierPath(ovalIn: layer.bounds).cgPath
                                    shapeLayer.fillColor = nil
                                    shapeLayer.strokeColor = UIColor.black.cgColor
                                    gradientLayer.mask = shapeLayer
                                    
                                    layer.addSublayer(gradientLayer)
                                }
                            }
                        } else {
                            imageView.image = nil
                            if let iconBackgroundView = cell.viewWithTag(4) {
                                iconBackgroundView.isHidden = true
                            }
                        }
                    }
                    if let countLabel = cell.viewWithTag(103) as? UILabel, let lockImageView = cell.viewWithTag(104) as? UIImageView  {
                        
                        countLabel.text = nil
                        countLabel.isHidden = true
                        lockImageView.isHidden = true
                        
                        if CurrentUser.sharedInstance.isLoggedIn {
                            
                            if module.type == "notifications" {
                                do{
                                    let managedObjectContext = CoreDataManager.sharedInstance.managedObjectContext
                                    let request = NSFetchRequest<EllucianNotification>(entityName: "Notification")

                                    request.predicate = NSPredicate(format: "read == %@", argumentArray: [false])
                                    request.includesSubentities = false
                                    let notifications = try managedObjectContext.fetch(request)
                                    let count = notifications.count
                                    countLabel.text = "\(count)"
                                    drawNotificationsLabel(countLabel)
                                    countLabel.isHidden = (count == 0)
                                } catch {
                                }
                            }
                            
                            lockImageView.isHidden = true
                        } else {
                            if module.requiresAuthentication() {
                                lockImageView.isHidden = false
                                lockImageView.layer.shadowOffset = CGSize(width: 0, height: 1)
                                lockImageView.layer.shadowColor = UIColor.black.cgColor
                                lockImageView.layer.shadowOpacity = 0.4
                                lockImageView.layer.shadowRadius = 1
                            }
                        }
                    }
                    
                    let gestureRecognizer = HomeMenuTapGestureRecognizer(target: self, action: #selector(HomeViewController.openMenuItem(_:)))
                    gestureRecognizer.module = module
                    cell.addGestureRecognizer(gestureRecognizer)
                }
            }
            for index in menuItemCount..<5 {
                if let cell = menuViews[index] {
                    cell.removeFromSuperview()
                }
            }
            if menuItemCount == 0 {
                menuContainerView.removeFromSuperview()
            }
        }
    }
    
    func drawNotificationsLabel(_ label: UILabel) {
        let layer = label.layer
        layer.cornerRadius = label.bounds.size.height / 2
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor(red: 102/255, green: 102/255, blue: 102/255, alpha: 1)
    }
    
    @objc func openMenuItem(_ gestureRecognizer: HomeMenuTapGestureRecognizer) {
        
        if let module = gestureRecognizer.module {
            let type = module.type
            if type == "web" && ( module.property(forKey: "external") ?? "false" ) == "true" {
                OperationQueue.main.addOperation(OpenModuleOperation(module: module))
            } else if module.type == "appLauncher" {
                OperationQueue.main.addOperation(OpenModuleOperation(module: module))
            } else {
                let operation = OpenModuleOperation(module: module)
                operation.performAnimation = true
                OperationQueue.main.addOperation(operation)
            }
        }
    }
}

class HomeMenuTapGestureRecognizer : UITapGestureRecognizer {
    var module : Module?
}
