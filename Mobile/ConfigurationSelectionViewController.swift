//
//  ConfigurationSelectionViewController.swift
//  Mobile
//
//  Created by Jason Hocker on 8/5/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class ConfigurationSelectionViewController : UITableViewController, UISearchResultsUpdating, NSFetchedResultsControllerDelegate {
    
    static let ConfigurationListRefreshIfPresentNotification = Notification.Name("RefreshConfigurationListIfPresent")
    
    let itunesLink = "https://itunes.apple.com/us/app/ellucian-go/id607185179?mt=8"
    let searchController = UISearchController(searchResultsController: nil)
    var allItems = [Configuration]()
    var filteredItems = [Configuration]()
    
    var fetchInProgress = false
    
    lazy var liveConfigurationsUrl : String = {
        
        let plistPath = Bundle.main.path(forResource: "Customizations", ofType: "plist")
        let plistDictioanry = NSDictionary(contentsOfFile: plistPath!)!
        
        if let url = plistDictioanry["Live Configurations URL"] {
            return url as! String
        } else {
            return "https://mobile.elluciancloud.com/mobilecloud/api/liveConfigurations"
        }
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        buildSearchBar()
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.defaultHeader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ConfigurationSelectionViewController.outdated(_:)), name: VersionChecker.VersionCheckerOutdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ConfigurationSelectionViewController.updateAvailable(_:)), name: VersionChecker.VersionCheckerUpdateAvailableNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ConfigurationSelectionViewController.fetchConfigurations), name: ConfigurationSelectionViewController.ConfigurationListRefreshIfPresentNotification, object: nil)
        
        self.fetchConfigurations()
    }
    
    func buildSearchBar() {
        self.searchController.searchResultsUpdater = self
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = NSLocalizedString("Search Schools", comment: "Placeholder text in search bar for switch schools")
        self.searchController.definesPresentationContext = true
        self.searchController.searchBar.sizeToFit()
        self.navigationItem.titleView = self.searchController.searchBar;
        tableView.sectionIndexBackgroundColor = UIColor.clear
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.searchController.isActive {
            return 1
        } else {
            return UILocalizedIndexedCollation.current().sectionTitles.count
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.searchController.isActive) {
            return filteredItems.count
        } else {
            if let rows = rowsForSection(section) {
                return rows.count
            } else {
                return 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigurationCell", for: indexPath) as UITableViewCell
        
        cell.accessibilityTraits = UIAccessibilityTraitButton
        cell.accessibilityHint = NSLocalizedString("Selects a school.", comment: "VoiceOver hint for button that selects a school")
        
        let configuration : Configuration
        if (self.searchController.isActive) {
            configuration = self.filteredItems[(indexPath as NSIndexPath).row]
        } else {
            let rows = rowsForSection((indexPath as NSIndexPath).section)!
            configuration = rows[(indexPath as NSIndexPath).row]
        }
        
        let nameLabel = cell.viewWithTag(1) as! UILabel
        nameLabel.text = configuration.configurationName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive {
            return nil
        } else {
            let sectionRows = rowsForSection(section)
            if let sectionRows = sectionRows , sectionRows.count > 0 {
                return self.sectionIndexTitles(for: tableView)![section]
                
            } else {
                return nil
            }
        }
    }
    
    func rowsForSection(_ section: Int) -> [Configuration]? {
        let index = self.sectionIndexTitles(for: self.tableView)![section]
        
        return allItems.filter {
            let name = $0.configurationName as String
            
            let range = name.range(of: index, options: [.caseInsensitive, .anchored] )
            if let range  = range {
                if !range.isEmpty {
                    return true
                }
            }
            return false
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let configuration : Configuration
        if (self.searchController.isActive) {
            configuration = self.filteredItems[(indexPath as NSIndexPath).row]
        } else {
            let rows = rowsForSection((indexPath as NSIndexPath).section)!
            configuration = rows[(indexPath as NSIndexPath).row]
        }
        schoolChosen(configuration)
    }
    
    func schoolChosen(_ configuration: Configuration) {
        self.sendEventToTracker1(category: .ui_Action, action: .list_Select, label: "Choose Institution")
        let defaults = AppGroupUtilities.userDefaults()
        let window = self.view.window
        
        if let window = window {
            let hud = MBProgressHUD.showAdded(to: window, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let configurationUrl = configuration.configurationUrl
            let name = configuration.configurationName
            
            let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            delegate.reset()
            
            defaults?.set(configurationUrl, forKey: "configurationUrl")
            defaults?.set(name, forKey: "configurationName")
            
            NotificationCenter.default.removeObserver(self, name: VersionChecker.VersionCheckerUpdateAvailableNotification, object: nil)
            ConfigurationManager.shared.loadConfiguration(configurationUrl: configurationUrl) {
                (result: Bool) in
                
                ConfigurationManager.shared.loadMobileServerConfiguration() {
                    (result2) in
                    
                    DispatchQueue.main.async {
                        
                        if let window = window {
                            MBProgressHUD.hide(for: window, animated: true)
                        }
                        if result {
                            NotificationCenter.default.removeObserver(self)
                            
                            AppearanceChanger.applyAppearanceChanges()
                            
                            let storyboard = UIStoryboard(name: "HomeStoryboard", bundle: nil)
                            let slidingVC = storyboard.instantiateViewController(withIdentifier: "SlidingViewController") as! ECSlidingViewController
                            slidingVC.anchorRightRevealAmount = 276
                            slidingVC.anchorLeftRevealAmount = 276
                            slidingVC.topViewAnchoredGesture = [ECSlidingViewControllerAnchoredGesture.tapping, ECSlidingViewControllerAnchoredGesture.panning]
                            let menu = storyboard.instantiateViewController(withIdentifier: "Menu")

                            let direction = UIView.userInterfaceLayoutDirection(for: slidingVC.view.semanticContentAttribute)
                            if direction == .rightToLeft {
                                slidingVC.underRightViewController = menu
                            } else {
                                slidingVC.underLeftViewController = menu
                            }
                            
                            self.view.window?.rootViewController = slidingVC
                            delegate.slidingViewController = slidingVC
                            
                            OperationQueue.main.addOperation(OpenModuleHomeOperation())
                        } else {
                            if let row = self.tableView.indexPathForSelectedRow {
                                self.tableView.deselectRow(at: row, animated: true)
                            }
                            self.fetchConfigurations()
                            DispatchQueue.main.async {
                                ConfigurationFetcher.showErrorAlertView(controller: self)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func fetchConfigurations() {
        if fetchInProgress {
            return
        }
        
        if self.allItems.count == 0 {
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            let loadingString = NSLocalizedString("Loading", comment: "loading message while waiting for data to load")
            hud.label.text = loadingString
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, loadingString)
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        DispatchQueue.global(qos: .userInteractive).async {
            self.fetchInProgress = true
            let defaults = AppGroupUtilities.userDefaults()
            var urlString = defaults?.string(forKey: "mobilecloud-url")
            if urlString == nil || urlString?.count == 0 {
                urlString = self.liveConfigurationsUrl
                defaults?.set(urlString, forKey: "mobilecloud-url")
                
            }
            let url = URL(string:urlString!)
            URLSession.shared.dataTask(with: url!,
                completionHandler: {
                    (data, response, error) -> Void in
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                    
                    if let _ = error {
                        self.showErrorAlert()
                    } else {
                        let json = JSON(data: data!)
                        let supportedVersions = json["versions"]["ios"].arrayValue.map { $0.string!}
                        if VersionChecker.sharedInstance.checkVersion(supportedVersions) {
                            if let analytics = json["analytics"]["ellucian"].string {
                                defaults?.set(analytics, forKey: "gaTracker1")
                            }
                            
                            var configurations = [Configuration]()
                            let jsonInstitutions = json["institutions"].array
                            if let jsonInstitutions = jsonInstitutions {
                                for jsonInstitution in jsonInstitutions {
                                    let jsonConfigurations = jsonInstitution["configurations"].array
                                    for jsonConfiguration in jsonConfigurations! {
                                        let institutionId = jsonInstitution["id"].int!
                                        let institutionName = jsonInstitution["name"].string!
                                        let configurationId = jsonConfiguration["id"].int!
                                        let configurationName = jsonConfiguration["name"].string!
                                        let configurationUrl = jsonConfiguration["configurationUrl"].string!
                                        let keywords =  jsonConfiguration["keywords"].arrayValue.map { $0.string!}
                                        let configuration = Configuration(configurationId : configurationId,
                                            configurationUrl : configurationUrl,
                                            institutionId : institutionId,
                                            institutionName : institutionName,
                                            configurationName : configurationName,
                                            keywords : keywords)
                                        configurations.append(configuration)
                                    }
                                    
                                }
                            }
                            self.allItems = configurations.sorted { $0.configurationName.localizedCaseInsensitiveCompare($1.configurationName) == ComparisonResult.orderedAscending }
                        }
                    }
                    DispatchQueue.main.async(execute: {
                        MBProgressHUD.hide(for: self.view, animated: true)
                        self.fetchInProgress = false
                        self.tableView.reloadData()
                    })
                    
                }
                ).resume()
            
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchBarText = self.searchController.searchBar.text , !searchBarText.isEmpty {

            self.filteredItems = self.allItems.filter( {

                return $0.configurationName.localizedStandardContains(searchBarText) ||
                    $0.institutionName.localizedStandardContains(searchBarText) ||
                    $0.keywords.filter{ $0.localizedStandardContains(searchBarText)
                        }.count > 0
                }
            )
        } else {
            self.filteredItems = self.allItems
        }
        tableView.reloadData()
    }
    
    @objc func updateAvailable(_ sender: AnyObject) {
        DispatchQueue.main.async(execute: {
            let alertController = UIAlertController(title: NSLocalizedString("Outdated", comment: "Outdated alert title"), message: NSLocalizedString("A new version is available.", comment: "Outdated alert message"), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
            alertController.addAction(okAction)
            let upgradeAction = UIAlertAction(title: NSLocalizedString("Upgrade", comment: "Upgrade software button label"), style: .default) { (action) in
                self.openITunes()
            }
            alertController.addAction(upgradeAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    @objc func outdated(_ sender: AnyObject) {
        DispatchQueue.main.async(execute: {
            let alertController = UIAlertController(title: NSLocalizedString("Outdated", comment: "Outdated alert title"), message: NSLocalizedString("The application must be upgraded to the latest version.", comment: "Force update alert message"), preferredStyle: .alert)
            let upgradeAction = UIAlertAction(title: NSLocalizedString("Upgrade", comment: "Upgrade software button label"), style: .cancel) { (action) in
                self.openITunes()
            }
            alertController.addAction(upgradeAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    func openITunes() {
        UIApplication.shared.open(URL(string:itunesLink)!, options: [:], completionHandler: nil)
    }
    
    func showErrorAlert() {
        DispatchQueue.main.async(execute: {
            if self.allItems.count == 0 {
                let alertController = UIAlertController(title: nil, message: NSLocalizedString("There are no institutions to display at this time.", comment: "configurations cannot be downloaded"), preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            } 
        })
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive {
            return nil
        }
        return UILocalizedIndexedCollation.current().sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return UILocalizedIndexedCollation.current().section(forSectionIndexTitle: index)
        
    }
    
}
