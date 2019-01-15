
//
//  MenuController.swift
//  Ellucian GO WatchKit Extension
//
//  Created by Jason Hocker on 4/24/15.
//  Copyright (c) 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import WatchKit
import Foundation
import CoreData


class MenuController: WKInterfaceController {
    
    @IBOutlet var menuTable: WKInterfaceTable!
    var modules = [[String : Any]]()
    
    @IBOutlet var chooseConfigurationLabel: WKInterfaceLabel!
    @IBOutlet var retrievingDataLabel: WKInterfaceLabel!
    @IBOutlet var spinner: WKInterfaceImage!
    
    private let supportedModuleTypes = [ "ilp", "maps" ]
    private var watchAppTitle: String?
    
    private var fetchingConfigurationFlag = false
    
    func getTitle() -> String? {
        if watchAppTitle == nil {
            let plistPath = Bundle.main.path(forResource: "Customizations", ofType: "plist")
            let plistDictioanry = NSDictionary(contentsOfFile: plistPath!)!
            
            if let title = plistDictioanry["Watch Menu Title"] as! String? {
                self.watchAppTitle = title
            } else {
                self.watchAppTitle = "Ellucian GO"
            }
        }
        
        return self.watchAppTitle
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // tell WatchConnectivityManager the menu controller instance
        WatchConnectivityManager.sharedInstance.saveRootController(self)
    }
    
    override func willActivate() {
        super.willActivate()

        print("MenuController willActivate called")

        let prefs = AppGroupUtilities.userDefaults()!
        let _ = prefs.string(forKey: "configurationUrl")
        let _ = prefs.string(forKey: "watchkit-last-configurationUrl")
        
        let _ = prefs.object(forKey: "menu updated date") as! Date?
        let _ = prefs.object(forKey: "watchkit-last-updatedConfiguration") as! Date?
        
        self.initMenu()
        
        if let title = getTitle() {
            self.setTitle(title)
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if(rowIndex == self.modules.count + 0) {
            self.pushController(withName: "about",  context: nil)
        } else {
            let selectedModule = self.modules[rowIndex]
            
            if let user = WatchConnectivityManager.sharedInstance.currentUser() {
                
                var match = false
                let roles = selectedModule["roles"] as! [String]
                for roleName in roles {
                    if let userRoles = user["roles"] as! [String]? {
                        if (userRoles.contains(roleName)) {
                            match = true
                        }
                    }
                    
                    if roleName == "Everyone" {
                        match = true
                    }
                    
                }
                if(roles.count == 0) {
                    match = true
                }
                
                if !match {
                    self.presentController(withName: "You do not have permission", context: nil)
                }
            }
            pushController(selectedModule)
        }
    }
    
    func initMenu() {
        print("MenuController initMenu called")
        
        if !fetchingConfigurationFlag {
            fetchingConfigurationFlag = true
            DispatchQueue.main.async {
                self.chooseConfigurationLabel.setHidden(true)
                let configurationManager = ConfigurationManager.shared
                if configurationManager.isConfigurationLoaded() {
                    if configurationManager.shouldConfigurationBeRefreshed() {
                        // load in the background but show what we have
                        configurationManager.refreshConfigurationIfNeeded() {
                            (result) in
                            
                            self.fetchingConfigurationFlag = false
                            WatchConnectivityManager.sharedInstance.refreshUser()
                            if (result is Bool && result as! Bool) || configurationManager.isConfigurationLoaded() {
                                DispatchQueue.main.async {
                                    self.initMenuAfterConfigurationLoaded()
                                }
                            } else if result is Bool && !(result as! Bool) {
                                self.chooseConfigurationLabel.setHidden(false)
                            }
                        }
                    } else {
                        // just show it
                        self.fetchingConfigurationFlag = false
                        self.initMenuAfterConfigurationLoaded()
                        WatchConnectivityManager.sharedInstance.refreshUser()
                    }
                } else {
                    // attempt to load configuration
                    self.retrievingDataLabel.setHidden(false)
                    self.spinner.startAnimating()
                    self.spinner.setHidden(false)
                    configurationManager.loadConfiguration() {
                        (result) in
                        
                        self.fetchingConfigurationFlag = false
                        WatchConnectivityManager.sharedInstance.refreshUser()
                        DispatchQueue.main.async {
                            if result || configurationManager.isConfigurationLoaded() {
                                self.initMenuAfterConfigurationLoaded()
                            } else if result {
                                self.retrievingDataLabel.setHidden(true)
                                self.spinner.stopAnimating()
                                self.spinner.setHidden(true)
                                self.chooseConfigurationLabel.setHidden(false)
                            } else {
                                self.retrievingDataLabel.setHidden(true)
                                self.spinner.stopAnimating()
                                self.spinner.setHidden(true)
                                self.chooseConfigurationLabel.setHidden(false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func initMenuAfterConfigurationLoaded() {
        self.retrievingDataLabel.setHidden(true)
        self.spinner.stopAnimating()
        self.spinner.setHidden(true)

        // configuration is loaded - build menu
        let context = CoreDataManager.sharedInstance.managedObjectContext
        
        let modulesRequest = NSFetchRequest<Module>(entityName: "Module")
        modulesRequest.sortDescriptors = [NSSortDescriptor(key: "index" , ascending: true)]
        
        var rolePredicates = [NSPredicate]()
        rolePredicates.append(NSPredicate(format: "roles.@count == 0"))
        rolePredicates.append(NSPredicate(format: "ANY roles.role like %@", "Everyone"))
        
        if let user = WatchConnectivityManager.sharedInstance.currentUser() {
            if let roles = user["roles"] as! [String]? {
                for role in roles {
                    rolePredicates.append(NSPredicate(format: "ANY roles.role like %@", role))
                }
            }
        }
        
        let joinOnRolesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: rolePredicates)
        
        var typePredicates = [NSPredicate]()
        for supportedType in supportedModuleTypes {
            typePredicates.append(NSPredicate(format: "type == %@", supportedType))
        }
        let joinOnTypesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: typePredicates)

        var andPredicates = [NSPredicate]()
        andPredicates.append(joinOnRolesPredicate)
        andPredicates.append(joinOnTypesPredicate)
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
        
        do {
            let allModules = try context.fetch(modulesRequest)
            
            // filter after Core Data fetch to avoid bug when there are >= about 10 predicates
            let modules = allModules.filter{ compoundPredicate.evaluate(with: $0) }
            
            var modulesAsDictionaries = [[String : Any]]()
            
            for module in modules {
                if (module.type) != nil && supportedModuleTypes.contains(module.type) {
                    var properties = [String : String] ()
                    for property in module.properties {
                        if let property = property as? ModuleProperty {
                            if let name = property.name {
                                properties[name] = property.value
                            }
                        }
                    }
                    
                    var roles = [String]()
                    for role in module.roles {
                        if let role = role as? ModuleRole {
                            roles.append(role.role)
                        }
                    }
                    
                    var moduleAsDictionary = [String : Any]()
                    if let iconUrl = module.iconUrl {
                        moduleAsDictionary["iconUrl"] = iconUrl
                    }
                    if let index = module.index {
                        moduleAsDictionary["index"] = index
                    }
                    if let internalKey = module.internalKey {
                        moduleAsDictionary["internalKey"] = internalKey
                    }
                    if let name = module.name {
                        moduleAsDictionary["name"] = name
                    }
                    if let hideBeforeLogin = module.hideBeforeLogin {
                        moduleAsDictionary["hideBeforeLogin"] = hideBeforeLogin
                    }
                    if ((module.type) != nil) { moduleAsDictionary["type"] = module.type }
                    moduleAsDictionary["properties"] = properties
                    moduleAsDictionary["roles"] = roles
                    
                    modulesAsDictionaries.append(moduleAsDictionary)
                }
            }
            self.setUpTable(modulesAsDictionaries)
            
        } catch {
            print("Unable to query modules for menu")
        }
    }
    
    func setUpTable(_ modules: [[String : Any]]) {
        self.chooseConfigurationLabel.setHidden(true)
        
        let modulesCount = modules.count
        if(self.modules.count != modulesCount || modules.count == 0) {
            self.clearTableRows()
            
            self.createTableFromModules(modules)
            
            self.menuTable.insertRows(at: IndexSet(integer: modulesCount), withRowType: "MenuTableRowController")
            let row = self.menuTable.rowController(at: modules.count) as! MenuTableRowController
            row.nameLabel.setText(NSLocalizedString("About", comment: "About menu item"))
            let defaults = AppGroupUtilities .userDefaults()
            // default to named icon-about. Configuration will overwrite if specified
            row.image.setImageNamed("icon-about")
            //row.image.setImage(UIImage(named: "icon-about"))
            
            if let aboutIcon = defaults?.string(forKey: "about-icon"), !aboutIcon.isEmpty {
                
                DispatchQueue.main.async(execute: {
                    ImageCache.sharedCache.getImage(aboutIcon) {
                        (image: UIImage?) in
                        
                        if image != nil {
                            row.image.setImage(image)
                        }
                    }
                })
            }
            
        } else {
            self.updateTableFromModules(modules)
        }
        self.modules = modules
    }
    
    // MARK: setUpTable helper methods
    
    private func clearTableRows() {
        self.menuTable.removeRows(at: IndexSet(integersIn: 0..<self.menuTable.numberOfRows))
        
    }
    
    private func updateTableFromModules(_ modules:[ [String : Any] ] ) {
        var i = 0
        for module in modules {
            if let rowInterfaceController = self.menuTable.rowController(at: i) as? MenuTableRowController {
                
                rowInterfaceController.nameLabel.setText(module["name"] as? String)
                
                DispatchQueue.main.async {
                    switch module["type"] as! String  {
                    case "maps":
                        rowInterfaceController.image.setImageNamed("icon-maps-location")
                    case "ilp":
                        rowInterfaceController.image.setImageNamed("ilp-assignments")
                    default:
                        break
                    }
                    
                    if let iconUrl = module["iconUrl"] as? String {
                        
                        ImageCache.sharedCache.getImage(iconUrl) {
                            (image: UIImage?) in
                            
                            if image != nil {
                                rowInterfaceController.image.setImage(image)
                            }
                        }
                    }
                }
            }
            i += 1
        }
        if modules.count > 0 {
            let row = self.menuTable.rowController(at: modules.count) as! MenuTableRowController
            row.nameLabel.setText(NSLocalizedString("About", comment: "About menu item"))
            let defaults = AppGroupUtilities .userDefaults()
            if let aboutIcon : String = defaults?.string(forKey: "about-icon"), !aboutIcon.isEmpty {
                
                DispatchQueue.main.async(execute: {
                    ImageCache.sharedCache.getImage(aboutIcon) {
                        (image: UIImage?) in
                        
                        if image != nil {
                            row.image.setImage(image)
                        }
                    }
                })
            } else {
                row.image.setImageNamed("icon-about")
            }
        }
    }
    
    private func createTableFromModules(_ modules:[[String : Any]]) {
        self.menuTable.insertRows(at: IndexSet(integersIn: 0..<modules.count), withRowType: "MenuTableRowController")
        
        var i = 0
        for module in modules {
            
            if let rowInterfaceController = self.menuTable.rowController(at: i) as? MenuTableRowController{
                
                rowInterfaceController.nameLabel.setText(module["name"] as? String)
                
                if let iconUrl = module["iconUrl"] as? String  {
                    
                    DispatchQueue.main.async {
                        ImageCache.sharedCache.getImage(iconUrl) {
                            (image: UIImage?) in
                            
                            if image != nil {
                                rowInterfaceController.image.setImage(image)
                            }
                        }
                    }
                }
            }
            i += 1
        }
    }
    
    // MARK - customized functions
    
    func pushController(_ selectedModule: [String : Any] ) {
        switch selectedModule["type"] as! String  {
        case "maps":
            let properties = selectedModule["properties"] as! Dictionary<String, String>
            let url = properties["campuses"]
            self.pushController(withName: "maps",  context: ["internalKey": (selectedModule["internalKey"] as! String), "title": (selectedModule["name"] as! String), "campuses": url])
        case "ilp":
            let properties = selectedModule["properties"] as! Dictionary<String, String>
            let url = properties["ilp"]
            self.pushController(withName: "ilp",  context: ["internalKey": (selectedModule["internalKey"] as! String), "title": (selectedModule["name"] as! String), "ilp": url])
        default:
            self.pushController(withName: selectedModule["type"] as! String,  context: nil)
        }
    }
}
