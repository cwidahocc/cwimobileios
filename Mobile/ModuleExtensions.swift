//
//  ModuleExtensions.swift
//  Mobile
//
//  Created by Jason Hocker on 7/7/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

extension Module {
    
    // MARK - Module properties
    func requiresAuthentication() -> Bool {
        var requiresAuthenticatedUser = false
        if let type = self.type {
            if type == "web" {
                if let property = self.property(forKey: "secure") , property == "true" {
                    requiresAuthenticatedUser = true
                }
            } else if type == "directory" {
                //for legacy supprt of mobile server < 4.5
                if ConfigurationManager.doesMobileServerSupportVersion("4.5") {
                    //if no directories defined
                    if let _ = property(forKey: "directories") {
                        requiresAuthenticatedUser = checkPlist()
                    } else {
                        requiresAuthenticatedUser = true
                    }
                } else {
                    requiresAuthenticatedUser = true
                }
            } else if type == "custom" {
                let customModuleType = self.property(forKey: "custom-type")
                
                if let customizationsPath = Bundle.main.path(forResource: "Customizations", ofType: "plist"), let customizationsDictionary = NSDictionary(contentsOfFile: customizationsPath) as? Dictionary<String, AnyObject> {
                    
                    let customModuleDefinitions = customizationsDictionary["Custom Modules"] as! Dictionary<String, AnyObject>
                    let moduleDefinition = customModuleDefinitions[customModuleType!] as! Dictionary<String, AnyObject>
                    if let needsAuth = moduleDefinition["Needs Authentication"] {
                        requiresAuthenticatedUser = needsAuth.boolValue
                    }
                }
            } else {
                requiresAuthenticatedUser = checkPlist()
            }
        }
        if let roles = self.roles {
            let moduleRoles = Array(roles)
            let filteredRoles = moduleRoles.filter {
                let role = $0 as! ModuleRole
                return role.role != "Everyone"
            }
            
            if filteredRoles.count > 0 {
                requiresAuthenticatedUser = true
            }
        }
        return requiresAuthenticatedUser
    }
    
    private func checkPlist() -> Bool {
        var requiresAuthenticatedUser = false
        if let ellucianPath = Bundle.main.path(forResource: "EllucianModules", ofType: "plist"), let ellucianDictionary = NSDictionary(contentsOfFile: ellucianPath) as? Dictionary<String, AnyObject> {
            
            let moduleDefinitions = ellucianDictionary
            let moduleDefinition = moduleDefinitions[self.type] as! Dictionary<String, AnyObject>
            if let needsAuth = moduleDefinition["Needs Authentication"] {
                requiresAuthenticatedUser = needsAuth.boolValue
            }
        }
        return requiresAuthenticatedUser
    }
    
    
    @objc func property(forKey: String) -> String? {
        
        if let value = self.propertyFromModule(forKey: forKey) {
            return value
        } else {
            let plistPath: String = Bundle.main.path(forResource: "Customizations", ofType: "plist")!
            let plistDictionary = NSDictionary(contentsOfFile: plistPath) as? Dictionary<String, AnyObject>
            var customModulesDictionary = plistDictionary?["Custom Modules"] as? Dictionary<String, AnyObject>
            if let customType = self.propertyFromModule(forKey: "custom-type") {
                if let customModuleDictionary = customModulesDictionary?[customType] as? Dictionary<String, AnyObject> {
                    var properties = customModuleDictionary["Properties"]  as? Dictionary<String, AnyObject>
                    return properties?[forKey] as? String
                    
                }
            } else {
                return nil
            }
        }
        return nil
    }
    
    func propertyFromModule(forKey: String) -> String? {
        
        let filteredProperties = self.properties.filter() {
            let property = $0 as! ModuleProperty //todo clean up
            return property.name == forKey
        }
        if let moduleProperty = Array(filteredProperties).last as? ModuleProperty {
            return moduleProperty.value
        }
        
        return nil
        
    }
    
    // MARK - create
    class func moduleFromJson(_ json: JSON, inManagedObjectContext managedObjectContext: NSManagedObjectContext, withKey internalKey: String, dispatchGroup: DispatchGroup) -> Module {
        var module: Module? = nil
        let request = NSFetchRequest<Module>(entityName: "Module")
        request.predicate = NSPredicate(format: "internalKey = %@", internalKey)
        let sortDescriptor = NSSortDescriptor(key: "internalKey", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        let matches = try? managedObjectContext.fetch(request)
        if let count = matches?.count, count > 1 {
            //handle error
        }
        else if matches?.count == 0 {
            module = NSEntityDescription.insertNewObject(forEntityName: "Module", into: managedObjectContext) as? Module
            module?.internalKey = internalKey
            Module.populateModule(module: module, json: json, inManagedObjectContext: managedObjectContext, dispatchGroup: dispatchGroup)
        }
        else {
            module = matches!.last
            Module.populateModule(module: module, json: json, inManagedObjectContext: managedObjectContext, dispatchGroup: dispatchGroup)
        }
        
        //special logic to handle extensions
        if (module?.type == "ilp") {
            let url = module?.property(forKey: "ilp")
            AppGroupUtilities.userDefaults()?.set(url, forKey: "ilp-url")
        }
        return module!
    }
    
    class func populateModule(module: Module?, json: JSON, inManagedObjectContext managedObjectContext: NSManagedObjectContext, dispatchGroup: DispatchGroup) {
        if let module = module {
            if let type = json["type"].string {
                module.properties = nil
                module.type = type
                
                if let name = json["name"].string {
                    module.name = name
                }
                if let icon = json["icon"].string {
                    module.iconUrl = icon
                    #if os(watchOS)
                        if type == "maps" || type == "ilp" {
                            ImageCache.sharedCache.cacheImageForLater(module.iconUrl, dispatchGroup: dispatchGroup)
                        }
                    #else
                        ImageCache.sharedCache.cacheImageForLater(module.iconUrl, dispatchGroup: dispatchGroup)
                    #endif
                }

                let displayInMenu = json["displayInMenu"].string ?? "true"
                module.displayInMenu = displayInMenu == "true"
                
                if let hideBeforeLogin = json["hideBeforeLogin"].string {
                    module.hideBeforeLogin = hideBeforeLogin == "true" ? 1 : 0
                }
                if let order = json["order"] .string {
                    module.index = NSNumber.init(value: Int32(order)!)
                }
                let access = json["access"].arrayValue.map{ $0.string } as? [String]
                if let access = access {
                    module.roles = nil
                    for role in access {
                        let managedRole = NSEntityDescription.insertNewObject(forEntityName: "ModuleRole", into: managedObjectContext) as!ModuleRole
                        managedRole.role = role
                        managedRole.module = module
                        module.addRolesObject(managedRole)
                    }
                }
                if let homeScreenOrder = json["homeScreenOrder"].string {
                    module.homeScreenOrder = NSNumber.init(value: Int32(homeScreenOrder)!)
                }
                for key in json.dictionaryValue.keys {
                    let value = json[key].object
                    if (key == "type") {
                        
                    }
                    else if (key == "name") {
                        
                    }
                    else if (key == "icon") {
                        
                    }
                    else if (key == "hideBeforeLogin") {
                        
                    }
                    else if (key == "order") {
                        
                    }
                    else if (key == "access") {
                        
                    }
                    else {

                        if let value = value as? String {
                            self.storeString(value: value, withKey: key, forModule: module, inManagedObjectContext: managedObjectContext)
                        }
                        else if let value = value as? [String : Any] {
                            self.parseDictionary(dictionary: value, forModule: module, inManagedObjectContext: managedObjectContext, key: key)
                        }
                        else if let value = value as? [AnyObject] {
                            self.parseArray(array: value, forModule: module, inManagedObjectContext: managedObjectContext, key: key)
                        }
                    }
                }
            }
        }

    }

    class func populateModule(module: Module?, withDictionary dictionary: [String : AnyObject], inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        if let module = module {
            if let type = dictionary["type"] as? String {
                module.properties = nil
                module.type = type
                
                if let name = dictionary["name"] as? String {
                    module.name = name
                }
                if let icon = dictionary["icon"] as? String {
                    module.iconUrl = icon
                    ImageCache.sharedCache.cacheImageForLater(module.iconUrl)
                }
                
                let displayInMenu = dictionary["displayInMenu"] as? String ?? "true"
                module.displayInMenu = displayInMenu == "true"
                
                if let hideBeforeLogin = dictionary["hideBeforeLogin"] as? String {
                    module.hideBeforeLogin = hideBeforeLogin == "true" ? 1 : 0
                }
                if let order = dictionary["order"] as? String {
                    module.index = NSNumber.init(value: Int32(order)!)
                }
                if let access = dictionary["access"] as? [String] {
                    module.roles = nil
                    for role in access {
                        let managedRole = NSEntityDescription.insertNewObject(forEntityName: "ModuleRole", into: managedObjectContext) as!ModuleRole
                        managedRole.role = role
                        managedRole.module = module
                        module.addRolesObject(managedRole)
                    }
                }
                if let homeScreenOrder = dictionary["homeScreenOrder"] as? String {
                    module.homeScreenOrder = NSNumber.init(value: Int32(homeScreenOrder)!)
                }
                for key in dictionary.keys {
                    let value = dictionary[key]
                    if (key == "type") {
                        
                    }
                    else if (key == "name") {
                        
                    }
                    else if (key == "icon") {
                        
                    }
                    else if (key == "hideBeforeLogin") {
                        
                    }
                    else if (key == "order") {
                        
                    }
                    else if (key == "access") {
                        
                    }
                    else {
                        if let value = value as? String {
                            self.storeString(value: value, withKey: key, forModule: module, inManagedObjectContext: managedObjectContext)
                        }
                        else if let value = value as? [String : Any] {
                            self.parseDictionary(dictionary: value, forModule: module, inManagedObjectContext: managedObjectContext, key: key)
                        }
                        else if let value = value as? [AnyObject] {
                            self.parseArray(array: value, forModule: module, inManagedObjectContext: managedObjectContext, key: key)
                        }
                    }
                }
            }
        }
    }
    
    
    class func parseDictionary(dictionary: [String : Any], forModule module: Module, inManagedObjectContext managedObjectContext: NSManagedObjectContext, key: String) {
        if (module.type == "directory") {
            if (key == "directories45") {
                var directoriesToUse = [String]()
                for key in dictionary.keys {
                    let value = dictionary[key] as! String
                    if value == "true" {
                        directoriesToUse.append(key)
                    }
                }
                self.storeString(value: directoriesToUse.joined(separator: ","), withKey: "directories", forModule: module, inManagedObjectContext: managedObjectContext)
            }
            else {
                self.parseDictionary(dictionary: dictionary, forModule: module, inManagedObjectContext: managedObjectContext)
            }
        }
        else if (module.type == "appLauncher") {
            if (key == "ios") {
                if let appDictionary = dictionary["app"] as? [String: Any], let app = appDictionary["url"] as? String {
                    self.storeString(value: app, withKey: "appUrl", forModule: module, inManagedObjectContext: managedObjectContext)
                }
                if let storeDictionary = dictionary["store"] as? [String: Any], let store = storeDictionary["url"] as? String {
                    self.storeString(value: store, withKey: "storeUrl", forModule: module, inManagedObjectContext: managedObjectContext)
                }
            }
        }
        else {
            self.parseDictionary(dictionary: dictionary, forModule: module, inManagedObjectContext: managedObjectContext)
        }
        
    }
    
    
    class func parseDictionary(dictionary: [String : Any], forModule module: Module, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        for key in dictionary.keys {
            let value = dictionary[key]
            if let value = value as? String {
                self.storeString(value: value, withKey: key, forModule: module, inManagedObjectContext: managedObjectContext)
            }
            else if let value = value as? [String : Any] {
                self.parseDictionary(dictionary: value, forModule: module, inManagedObjectContext: managedObjectContext, key: key)
            }
            else if let value = value as? [Any] {
                self.parseArray(array: value, forModule: module, inManagedObjectContext: managedObjectContext, key: key)
            }
        }
    }
    
    class func storeString(value: String, withKey key: String, forModule module: Module, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        let managedProperty = NSEntityDescription.insertNewObject(forEntityName: "ModuleProperty", into: managedObjectContext) as! ModuleProperty
        managedProperty.name = key
        managedProperty.value = value
        managedProperty.module = module
        module.addPropertiesObject(managedProperty)
    }
    
    class func parseArray(array: [Any], forModule module: Module, inManagedObjectContext managedObjectContext: NSManagedObjectContext, key: String) {
        if (module.type == "registration") {
            do {
                if (key == "locations") {
                    
                    let fetchRequest = NSFetchRequest<RegistrationLocation>(entityName: "RegistrationLocation")
                    fetchRequest.predicate = NSPredicate(format: "moduleId == %@", module.internalKey)
                    fetchRequest.includesPropertyValues = false
                    
                    let fetchedObjects = (try managedObjectContext.fetch(fetchRequest))
                    for object in fetchedObjects {
                        managedObjectContext.delete(object)
                    }
                    for dictionary in array  {
                        if let dictionary = dictionary as? [String : Any] {
                            let location = NSEntityDescription.insertNewObject(forEntityName: "RegistrationLocation", into: managedObjectContext) as! RegistrationLocation
                            location.name = (dictionary["name"] as! String)
                            location.code = (dictionary["code"] as! String)
                            location.moduleId = module.internalKey
                        }
                    }
                    try managedObjectContext.save()
                }
                else if (key == "academic levels") {
                    let fetchRequest: NSFetchRequest = NSFetchRequest<RegistrationAcademicLevel>(entityName: "RegistrationAcademicLevel")
                    fetchRequest.predicate = NSPredicate(format: "moduleId == %@", module.internalKey)
                    fetchRequest.includesPropertyValues = false
                    
                    let fetchedObjects = (try managedObjectContext.fetch(fetchRequest))
                    for object: NSManagedObject in fetchedObjects {
                        managedObjectContext.delete(object)
                    }
                    for dictionary in array {
                        if let dictionary = dictionary as? [String : Any] {
                            let academicLevel: RegistrationAcademicLevel = NSEntityDescription.insertNewObject(forEntityName: "RegistrationAcademicLevel", into: managedObjectContext) as! RegistrationAcademicLevel
                            academicLevel.name = (dictionary["name"] as! String)
                            academicLevel.code = (dictionary["code"] as! String)
                            academicLevel.moduleId = module.internalKey
                        }
                    }
                    try managedObjectContext.save()
                }
                
            }
            catch {
            }
        }
    }

}
