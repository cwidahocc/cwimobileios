//
//  MenuViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 6/19/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SectionHeaderViewDelegate {

    var useSwitchSchool = true
    var managedObjectContext : NSManagedObjectContext?
    @IBOutlet var tableView: UITableView!
    var menuSectionInfo: [MenuSectionInfo]?
    var loaded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MenuViewController.reload), name: CurrentUser.SignInNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuViewController.applicationDidBecomeActive(_:)), name: CurrentUser.SignInNotification, object: nil)

        tableView .register(MenuTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Header")
        tableView .register(MenuTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "CollapseableHeader")
        
        readCustomizationsPropertyList()
        NotificationCenter.default.addObserver(self, selector: #selector(MenuViewController.registerObservers), name: ConfigurationManager.ConfigurationLoadSucceededNotification, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.post(name: UIViewController.SlidingViewOpenMenuAppearsNotification, object: nil)
        
        reload()
        DispatchQueue.global(qos: .userInteractive).async (execute: {() -> Void in

            //Ellucian Mobile 4.0 -> 4.1 upgrade... if configurationUrl was known but doesn't have it cached in new structure, go refresh
            let configurationManager = ConfigurationManager.shared
            let defaults = AppGroupUtilities.userDefaults()
            let configurationUrl = defaults?.string(forKey: "configurationUrl")
            
            if configurationManager.isConfigurationLoaded() || configurationUrl != nil {
                // trigger refresh if needed
                configurationManager.refreshConfigurationIfNeeded() {
                    (result) -> Void in
                    
                    if configurationManager.isConfigurationLoaded() {
                        DispatchQueue.main.async {
                            AppearanceChanger.applyAppearanceChanges()
                            self.reload()
                        }
                    } else {
                        if self.loaded {
                            NotificationCenter.default.post(name: ConfigurationFetcher.ConfigurationFetcherErrorNotification, object: nil)
                        }
                    }
                }
            } else {
                OperationQueue.main.addOperation(OpenModuleConfigurationSelectionOperation())
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: UIViewController.SlidingViewTopResetNotification, object: nil)
    }
    
    // MARK: - Observers
    
    @objc func registerObservers() {
        self.loaded = true
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuViewController.outdated(_:)), name: VersionChecker.VersionCheckerOutdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuViewController.updateAvailable(_:)), name: VersionChecker.VersionCheckerUpdateAvailableNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuViewController.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuViewController.respondToSignOut(_:)), name: CurrentUser.SignOutNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MenuViewController.notificationsUpdated(_:)), name: NotificationsFetcher.NotificationsUpdatedNotification, object: nil)
    }
    
    @objc func outdated(_ notification: Notification) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: NSLocalizedString("Outdated", comment: "Outdated alert title"), message: NSLocalizedString("The application must be upgraded to the latest version.", comment: "Force update alert message"), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Upgrade", comment: "Upgrade software button label"), style: .default, handler: { action in
                 self.openITunes()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func updateAvailable(_ notification: Notification) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: NSLocalizedString("Outdated", comment: "Outdated alert title"), message: NSLocalizedString("A new version is available.", comment: "Outdated alert message"), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Upgrade", comment: "Upgrade software button label"), style: .default, handler: { action in
                self.openITunes()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil))

            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        reload()
        NotificationsFetcher.fetchNotifications(managedObjectContext: CoreDataManager.sharedInstance.managedObjectContext)
    }
    
    @objc func respondToSignOut(_ notification: Notification) {
        if let rows = tableView.indexPathsForVisibleRows {
            self.tableView.reloadRows(at: rows, with: .none)
        }
    }
    
    @objc func notificationsUpdated(_ notifcation: Notification) {
        reload()
    }

    @objc func reload() {
        let buildMenuOperation = OpenModuleFindModulesOperation()
        buildMenuOperation.completionBlock = {
            let modules = buildMenuOperation.modules
            self.drawMenu(modules)
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                
            })
        }
        OperationQueue.main.addOperation(buildMenuOperation)
    }
    
    // MARK: - iTunes
    
    func openITunes () {
        let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        delegate.reset()
        
        let iTunesLink = "http://appstore.com/elluciango"
        if let url = URL(string: iTunesLink) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // MARK: protocol UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isActionSection(section) {
            return useSwitchSchool ? 5 : 4
        }
        let menuSectionInfo = self.menuSectionInfo![section]
        if menuSectionInfo.collapsed { return 0 }
        return menuSectionInfo.modules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = (indexPath as NSIndexPath).section
        if isActionSection(section) {
            return cellForActionsRow(indexPath)
        } else {
            return cellForModulesRow(indexPath)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        guard let _ = self.menuSectionInfo else { return 0 }
        return self.menuSectionInfo!.count
    }

    // MARK: UITableViewDelegate
    
    // Section header & footer information. Views are preferred over title should you decide to provide both
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let menuSectionInfo = self.menuSectionInfo![section]
        
        let sectionHeaderView : MenuTableViewHeaderFooterView
        if menuSectionInfo.collapseable {
            sectionHeaderView =
                 tableView.dequeueReusableHeaderFooterView(withIdentifier: "CollapseableHeader") as! MenuTableViewHeaderFooterView
            
            var collapsedHeaders : [String]? = AppGroupUtilities.userDefaults()?.stringArray(forKey: "menu-collapsed")
            if collapsedHeaders == nil {
                collapsedHeaders = []
            }
            let collapsed = (collapsedHeaders?.contains(menuSectionInfo.headerTitle!))!
            sectionHeaderView.collapsibleButton!.isSelected = collapsed;

        } else {
            sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as!MenuTableViewHeaderFooterView
        }

        if let headerLabel = sectionHeaderView.headerLabel {
            headerLabel.text = menuSectionInfo.headerTitle
        }
        sectionHeaderView.section = section
        sectionHeaderView.delegate = self

        return sectionHeaderView;
    }
    
    // Called after the user changes the selection.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch ((indexPath as NSIndexPath).section, (indexPath as NSIndexPath).row, isActionSection((indexPath as NSIndexPath).section), self.useSwitchSchool) {
        case (_, 0, true, _) :
            OperationQueue.main.addOperation(OpenModuleHomeOperation())
        case (_, 1, true, _) :
            OperationQueue.main.addOperation(OpenModuleSettingsOperation())
        case (_, 2, true, _) :
            OperationQueue.main.addOperation(OpenModuleAboutOperation())
        case (_, 3, true, true):
            OperationQueue.main.addOperation(OpenModuleConfigurationSelectionOperation())
        case (_, 3, true, false), (_, 4, true, _):
            //sign out
            if CurrentUser.sharedInstance.isLoggedIn {
                sendEvent(category: .ui_Action, action: .menu_selection, label: "Menu-Click Sign Out")
                OperationQueue.main.addOperation(LoginSignOutOperation())
                let cell = tableView.cellForRow(at: indexPath)
                if let cell = cell, let nameLabel = cell.viewWithTag(101) as? UILabel {
                    nameLabel.text = NSLocalizedString("Sign In", comment: "label to sign in")
                }
                tableView.deselectRow(at: indexPath, animated: true)
                reload()
            } else {
                sendEvent(category: .ui_Action, action: .menu_selection, label: "Menu-Click Sign In")
                let operation = LoginSignInOperation(controller: self)
                if let slidingViewController = self.view.window?.rootViewController as? ECSlidingViewController {
                    if slidingViewController.topViewController is UINavigationController && slidingViewController.topViewController.childViewControllers[0] is HomeViewController {
                        operation.successCompletionHandler = {
                            OperationQueue.main.addOperation(OpenModuleHomeOperation())
                        }
                    }
                }
                OperationQueue.main.addOperation(operation)
            }
        case (_, _, _, _) :
            //anything else
            let menuSectionInfo = self.menuSectionInfo![(indexPath as NSIndexPath).section]
            let modules = menuSectionInfo.modules
            let module = modules[(indexPath as NSIndexPath).row]
            OperationQueue.main.addOperation(OpenModuleOperation(module: module))
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: utility
    func isActionSection(_ sectionIndex: Int) -> Bool {
        guard let _ = self.menuSectionInfo else { return true }
        return menuSectionInfo!.count == 1 + sectionIndex
    }
    
    func cellForActionsRow(_ indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "Menu Cell", for: indexPath) as UITableViewCell
        
        cell.accessibilityTraits = UIAccessibilityTraitButton
        
        if let nameLabel = cell.viewWithTag(101) as? UILabel, let imageView = cell.viewWithTag(102) as? UIImageView {
            switch ((indexPath as NSIndexPath).row, self.useSwitchSchool) {
            case (0, _):
                nameLabel.text = NSLocalizedString("Home", comment: "Home menu item")
                imageView.image = UIImage(named: "icon-home")
            case (1, _):
                nameLabel.text = NSLocalizedString("Settings", comment: "Settings menu item")
                imageView.image = UIImage(named: "icon-settings")
            case (2, _):
                nameLabel.text = NSLocalizedString("About", comment: "About menu item")
                let iconUrl = AppGroupUtilities.userDefaults()?.string(forKey: "about-icon")
                if let iconUrl = iconUrl {
                    imageView.image = ImageCache.sharedCache.getCachedImage(iconUrl)
                } else {
                    imageView.image = UIImage(named: "icon-about")
                }
            case (3, true):
                nameLabel.text = NSLocalizedString("Switch School", comment: "Switch school menu item")
                imageView.image = UIImage(named: "icon-switch-schools")
            case (3, false), (4, _):
                if CurrentUser.sharedInstance.isLoggedIn {
                    nameLabel.text = NSLocalizedString("Sign Out", comment: "Sign Out menu item");
                } else {
                    nameLabel.text = NSLocalizedString("Sign In", comment: "Sign In menu item");
                }
                imageView.image = UIImage(named: "icon-sign-in")
            default:
                ()
            }
        }
        if let countLabel = cell.viewWithTag(103) as? UILabel, let lockImageView = cell.viewWithTag(104) as? UIImageView  {
            countLabel.text = nil
            countLabel.isHidden = true
            lockImageView.isHidden = true
        }
        return cell
        
    }
    
    func cellForModulesRow(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Menu Cell", for: indexPath) as UITableViewCell
        
        cell.accessibilityTraits = UIAccessibilityTraitButton
        
        let menuSectionInfo = self.menuSectionInfo![(indexPath as NSIndexPath).section]
        let module = menuSectionInfo.modules[(indexPath as NSIndexPath).row]

        if let nameLabel = cell.viewWithTag(101) as? UILabel {
            nameLabel.text = module.name
        }
        if let imageView = cell.viewWithTag(102) as? UIImageView {
            if let iconUrl = module.iconUrl {
                imageView.image = ImageCache.sharedCache.getCachedImage(iconUrl)
            } else {
                imageView.image = nil
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
                        drawLabel(countLabel)
                        countLabel.isHidden = (count == 0)
                    } catch {
                    }
                }
                
                lockImageView.isHidden = true
            } else {
                if module.requiresAuthentication() {
                    lockImageView.isHidden = false
                }
            }
            
        }
        return cell
    }
    
    func drawLabel(_ label: UILabel) {
        let layer = label.layer
        layer.cornerRadius = label.bounds.size.height / 2
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor(red: 102/255, green: 102/255, blue: 102/255, alpha: 1)
    }
    
    // MARK: SectionHeaderViewDelegate
    
    func sectionHeaderView(_ sectionHeaderView: MenuTableViewHeaderFooterView, sectionOpened section: Int) {
        let menuSectionInfo = self.menuSectionInfo![section]
        menuSectionInfo.collapsed = false
        
        let defaults = AppGroupUtilities.userDefaults()!
        var collapsedHeaders : [String]? = defaults.stringArray(forKey: "menu-collapsed")
        if collapsedHeaders == nil {
            collapsedHeaders = []
        }
        collapsedHeaders = collapsedHeaders!.filter({ $0 != menuSectionInfo.headerTitle})
        defaults.set(collapsedHeaders, forKey: "menu-collapsed")
        
        let modules = menuSectionInfo.modules
        let countOfRowsToInsert = modules.count
        var indexPathsToInsert = [IndexPath]()
        for index in 0 ..< countOfRowsToInsert {
            indexPathsToInsert.append( IndexPath(row: index, section: section) )
        }
        
        sectionHeaderView.collapsibleButton?.accessibilityLabel = NSLocalizedString("Toggle menu section", comment:"Accessibility label for toggle menu section button")
        
        tableView.beginUpdates()
        tableView.insertRows(at: indexPathsToInsert, with: .none)
        tableView.endUpdates()
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, sectionHeaderView);
        
    }
    
    func sectionHeaderView(_ sectionHeaderView: MenuTableViewHeaderFooterView, sectionClosed section: Int) {
        let menuSectionInfo = self.menuSectionInfo![section]
        menuSectionInfo.collapsed = true
        
        let defaults = AppGroupUtilities.userDefaults()!
        var collapsedHeaders : [String]? = defaults.stringArray(forKey: "menu-collapsed")
        if collapsedHeaders == nil {
            collapsedHeaders = []
        }
        collapsedHeaders!.append(menuSectionInfo.headerTitle!)
        defaults.set(collapsedHeaders, forKey: "menu-collapsed")
        
        let modules = menuSectionInfo.modules
        let countOfRowsToInsert = modules.count
        var indexPathsToInsert = [IndexPath]()
        for index in 0 ..< countOfRowsToInsert {
            indexPathsToInsert.append( IndexPath(row: index, section: section) )
        }
        
        sectionHeaderView.collapsibleButton?.accessibilityLabel = NSLocalizedString("Toggle menu section", comment:"Accessibility label for toggle menu section button")
        
        tableView.beginUpdates()
        tableView.deleteRows(at: indexPathsToInsert, with: .none)
        tableView.endUpdates()
        
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, sectionHeaderView);

    }
    
    // MARK: draw
    
    func drawMenu(_ modules: [Module]) {
        
        var collapsedHeaders : [String]? = AppGroupUtilities.userDefaults()?.stringArray(forKey: "menu-collapsed")
        if collapsedHeaders == nil {
            collapsedHeaders = []
        }
        
        var infoArray = [MenuSectionInfo]()
        
        var tempInfo = MenuSectionInfo()
        
        if modules.count > 0 {
            for module in modules {
                if module.type == "header" {
                    tempInfo = MenuSectionInfo()
                    tempInfo.collapsed = (collapsedHeaders?.contains(module.name))!
                    tempInfo.headerTitle = module.name
                    tempInfo.collapseable = true
                    tempInfo.modules = [Module]()
                    infoArray.append(tempInfo)
                } else {
                    if infoArray.count == 0 {
                        let localizedApplications = NSLocalizedString("Applications", comment:"Applications menu heading")
                        tempInfo = MenuSectionInfo()
                        tempInfo.collapsed = (collapsedHeaders?.contains(localizedApplications))!
                        tempInfo.headerTitle = localizedApplications
                        tempInfo.collapseable = true
                        tempInfo.modules = [Module]()
                        infoArray.append(tempInfo)
                        tempInfo.modules.append(module)
                    } else {
                        tempInfo.modules.append(module)
                    }
                }
            }
        } else {
            let localizedApplications = NSLocalizedString("Applications", comment:"Applications menu heading")
            tempInfo = MenuSectionInfo()
            tempInfo.collapsed = (collapsedHeaders?.contains(localizedApplications))!
            tempInfo.headerTitle = localizedApplications
            tempInfo.collapseable = true
            tempInfo.modules = [Module]()
            infoArray.append(tempInfo)
            
        }
        
        
        let localizedActions = NSLocalizedString("Actions", comment:"Actions menu heading")
        tempInfo = MenuSectionInfo()
        tempInfo.collapsed = false
        tempInfo.headerTitle = localizedActions
        tempInfo.collapseable = false
        tempInfo.modules = [Module]()
        infoArray.append(tempInfo)
        
        self.menuSectionInfo = infoArray
    }
    
    private func readCustomizationsPropertyList() {
        if let customizationsPath = Bundle.main.path(forResource: "Customizations", ofType: "plist") , let customizationsDictionary = NSDictionary(contentsOfFile: customizationsPath) as? Dictionary<String, AnyObject> {
            if let useSwitchSchool = customizationsDictionary["Allow Switch School"] {
                self.useSwitchSchool = useSwitchSchool as! Bool
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor(white: 0.163037, alpha: 1.0)
    }
}


class MenuSectionInfo {
    
    var collapsed : Bool = false
    var collapseable : Bool = false
    var modules = [Module]()
    var headerTitle : String?
}



