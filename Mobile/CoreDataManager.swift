//
//  CoreDataManager.swift
//  Mobile
//
//  Created by Jason Hocker on 6/22/15.
//  Copyright © 2015 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import Foundation
import CoreData


class CoreDataManager: NSObject {
    
    static let sharedInstance = CoreDataManager()
    
    var _managedObjectContext: NSManagedObjectContext? = nil
    var _managedObjectModel: NSManagedObjectModel? = nil
    var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil

    private override init() {
        
    }
    
//    func initialize(){
//        self.managedObjectContext
//    }
    
    // MARK: Core Data stack
    
    var managedObjectContext: NSManagedObjectContext{

        if Thread.isMainThread {
            if !(_managedObjectContext != nil) {
                let coordinator = self.persistentStoreCoordinator
                
                _managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                _managedObjectContext!.persistentStoreCoordinator = coordinator
                
                
                return _managedObjectContext!
            }
        } else {
            
            var threadContext : NSManagedObjectContext? = Thread.current.threadDictionary["NSManagedObjectContext"] as? NSManagedObjectContext;
            
            print(Thread.current.threadDictionary)
            
            if threadContext == nil {
                print("creating new context")
                threadContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                
                if !(_managedObjectContext != nil) {
                    let coordinator = self.persistentStoreCoordinator
                    
                    _managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                    _managedObjectContext!.persistentStoreCoordinator = coordinator

                }

                threadContext!.parent = _managedObjectContext
                threadContext!.name = Thread.current.description
                
                Thread.current.threadDictionary["NSManagedObjectContext"] = threadContext
                
                NotificationCenter.default.addObserver(self, selector:#selector(CoreDataManager.contextWillSave(_:)) , name: NSNotification.Name.NSManagedObjectContextWillSave, object: threadContext)
                
            }else{
                print("using old context")
            }
            return threadContext!;
        }
        
        return _managedObjectContext!
    }
    
    // Returns the managed object model for the application.
    // If the model doesn't already exist, it is created from the application's model.
    var managedObjectModel: NSManagedObjectModel {
        if !(_managedObjectModel != nil) {
            let modelURL = Bundle.main.url(forResource: "Mobile", withExtension: "momd")
            _managedObjectModel = NSManagedObjectModel(contentsOf: modelURL!)
        }
        return _managedObjectModel!
    }
    
    // Returns the persistent store coordinator for the application.
    // If the coordinator doesn't already exist, it is created and the application's store added to it.
    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        if (_persistentStoreCoordinator != nil) {
            return _persistentStoreCoordinator!
        }
        
        _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let storeURL = AppGroupUtilities.applicationDocumentsDirectory()!.appendingPathComponent("Mobile.sqlite")
        
        let applicationDocumentsDirectoryOld = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        let oldStoreURL = applicationDocumentsDirectoryOld?.appendingPathComponent("Mobile.sqlite")
        
        if FileManager.default.fileExists(atPath: (oldStoreURL?.path)!) {
            //migrate
            do {
                
                try _persistentStoreCoordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: oldStoreURL, options: self.databaseOptions())
                if let sourceStore = _persistentStoreCoordinator?.persistentStore(for: oldStoreURL!)
                {
                    do {
                        
                        let destinationStore = try _persistentStoreCoordinator?.migratePersistentStore(sourceStore, to: storeURL, options: self.databaseOptions(), withType: NSSQLiteStoreType)
                        
                        if let _ = destinationStore {
                            
                            try FileManager.default.removeItem(at: oldStoreURL!)
                        }
                    } catch {
                        
                    }
                }
            }
            catch {
                abort()
            }
        } else {
            // no migrate - store normal
            do {
                
                try _persistentStoreCoordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: self.databaseOptions())
            }
            catch {
                abort()
            }

        }
        
        return _persistentStoreCoordinator!
    }
    
    
    
    // MARK: fetches
    
    func executeFetchRequest<T>(_ request:NSFetchRequest<T>)-> [T]? {
        
        var results:[T]?
        self.managedObjectContext.performAndWait{
            do {
                results = try self.managedObjectContext.fetch(request)
            } catch let error as NSError {
                print("Warning!! \(error.description)")
            } catch {
                fatalError()
            }
        }
        return results
        
    }
    
    
    func executeFetchRequest<T>(_ request:NSFetchRequest<T>, completionHandler:@escaping (_ results: [T]?) -> Void)-> (){
        
        self.managedObjectContext.perform{
            var results:[T]?
            do {
                results = try self.managedObjectContext.fetch(request)
            } catch let error as NSError {
                print("Warning!! \(error.description)")
            } catch {
                fatalError()
            }
            completionHandler(results)
        }
        
    }
    
    
    
    // MARK: save methods
    
    func save() {
        
        let context:NSManagedObjectContext = self.managedObjectContext;
        if context.hasChanges {
            
            context.performAndWait{
                
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Warning!! Saving error \(error.description)")
                } catch {
                    fatalError()
                }
                
                if let parentContext = context.parent {
                    
                    parentContext.performAndWait {
                        do {
                            
                            try parentContext.save()
                            
                        } catch let error as NSError {
                            print("Warning!! Saving parent error \(error.description)")
                        } catch {
                            fatalError()
                        }
                    }
                }
            }
        }
    }
    
    
    
    
    
    @objc func contextWillSave(_ notification:Notification){
        
        let context : NSManagedObjectContext! = notification.object as! NSManagedObjectContext
        let insertedObjects : Set<NSManagedObject> = context.insertedObjects
        
        if insertedObjects.count != 0 {
            
            do {
                try context.obtainPermanentIDs(for: Array(insertedObjects))
            } catch let error as NSError {
                print("Warning!! obtaining ids error \(error.description)")
            }
            
        }
        
    }
    
    
    // MARK: Utilities
    
    
    func deleteEntity(_ object:NSManagedObject)-> () {
        object.managedObjectContext?.delete(object)
    }
    
    
    
    // MARK: Application's Documents directory

    func databaseOptions() -> [String : Any] {
        var options = [String : Any]()
        options[NSMigratePersistentStoresAutomaticallyOption] = true
        options[NSInferMappingModelAutomaticallyOption] = true
        options[NSSQLitePragmasOption] = ["journal_mode":"MEMORY"]
        return options
    }
    
    func reset() {
        
        self.managedObjectContext.reset()
        _managedObjectContext  = nil
        _managedObjectModel = nil
        _persistentStoreCoordinator = nil
    }
}
