//
//  ModuleManager.swift
//  Mobile
//
//  Created by Bret Hansen on 7/25/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation

class ModuleManager: NSObject {
    class func findModule(_ key: String) -> Module {
        let request = NSFetchRequest<Module>(entityName: "Module")
        
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        
        let modules = findUserModules(includeDontDisplayInMenu: true)
        
        return modules.filter {
            $0.internalKey == key
            }.first!
    }
    
    class func findModule(name moduleName: String?, type moduleType: String?) -> Module? {
        let request = NSFetchRequest<Module>(entityName: "Module")
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        
        let modules = findUserModules(includeDontDisplayInMenu: true)
    
        var result: Module? = nil
        for module in modules {
            if (module.name == moduleName || moduleName == nil) && module.type == moduleType {
                result = module
                break
            }
        }
        
        return result
    }
    
    class func findUserModules(limitToHomeScreen: Bool = false, includeDontDisplayInMenu: Bool = false) -> [Module] {
        let userRoles : [String]
        let currentUser = CurrentUser.sharedInstance
        if currentUser.isLoggedIn {
            userRoles = currentUser.roles
        } else {
            userRoles = [String]()
        }
        
        var parr = [NSPredicate]()
        
        var results : [Module]
        let request = NSFetchRequest<Module>(entityName: "Module")
        if(limitToHomeScreen) {
            request.sortDescriptors = [NSSortDescriptor(key: "homeScreenOrder" , ascending: true)]
        } else {
            request.sortDescriptors = [NSSortDescriptor(key: "index" , ascending: true)]
        }
        
        if !includeDontDisplayInMenu {
            request.predicate = NSPredicate(format: "displayInMenu == %@", argumentArray: [true])
        }
        
        if userRoles.count > 0 {
            
            parr.append(NSPredicate(format: "roles.@count == 0"))
            parr.append(NSPredicate(format: "ANY roles.role like %@", "Everyone"))
            for role in userRoles {
                parr.append(NSPredicate(format: "ANY roles.role like %@", role))
            }
            
        } else {
            parr.append(NSPredicate(format: "(hideBeforeLogin == %@) || (hideBeforeLogin = nil)", NSNumber(value: false)))
            
        }
        
        let joinOnRolesPredicate = NSCompoundPredicate(type: .or, subpredicates: parr)
        let allModules = CoreDataManager.sharedInstance.executeFetchRequest(request)
        results = allModules!.filter{ joinOnRolesPredicate.evaluate(with: $0) }
        results = results.filter( { isSupported($0) } )
        
        if limitToHomeScreen {
            results = results.filter( { $0.homeScreenOrder != nil && $0.homeScreenOrder > 0 && $0.homeScreenOrder <= 5 } )
        }
        
        return results
    }
    
    class func isSupported(_ module: Module) -> Bool {
        if let type = module.type {
            switch type {
            case "header":
                return true
            case "web":
                return true
            case "custom":
                guard let customModuleType = module.property(forKey: "custom-type") else { return false }
                let moduleDefinition = self.readCustomizationsPropertyList()[customModuleType]
                return moduleDefinition != nil
            default:
                let moduleDefinition = readEllucainPropertyList()[module.type]
                return moduleDefinition != nil
                
                
            }
        } else {
            return false
        }
    }
    
    
    class func readCustomizationsPropertyList() -> Dictionary<String, AnyObject> {
        if let customizationsPath = Bundle.main.path(forResource: "Customizations", ofType: "plist"), let customizationsDictionary = NSDictionary(contentsOfFile: customizationsPath) as? Dictionary<String, AnyObject> {
            
            return customizationsDictionary["Custom Modules"]  as! Dictionary<String, AnyObject>
            
        } else {
            return Dictionary<String, AnyObject> ()
        }
        
    }
    
    class func readEllucainPropertyList() -> Dictionary<String, AnyObject> {
        if let ellucianPath = Bundle.main.path(forResource: "EllucianModules", ofType: "plist"), let ellucianDictionary = NSDictionary(contentsOfFile: ellucianPath) as? Dictionary<String, AnyObject> {
            
            return ellucianDictionary
        } else {
            return Dictionary<String, AnyObject> ()
        }
    }
}
