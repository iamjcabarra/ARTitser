//
//  ARFCoreDataStack.swift
//  ARFollow
//
//  Created by Julius Abarra on 12/10/2017.
//  Copyright © 2017 exZeptional. All rights reserved.
//

import Foundation
import CoreData

class ARFCoreDataStack  {
    
    fileprivate var store: NSPersistentStore?
    fileprivate var masterContext: NSManagedObjectContext!
    fileprivate var mainContext: NSManagedObjectContext!
    fileprivate var workerContext: NSManagedObjectContext!
    
    init(name: String) {
        let modelName = "\(name)"
        let sqlFilename = "\(name).sqlite"
        
        // STEP 1
        // Managed object model
        guard let model = self.retrieveCoreDataModel(withName: modelName) else {
            print("ERROR: Can't retrieve data model from application bundle!")
            return
        }
        
        // STEP 2
        // Persistent store coordinator
        let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // STEP 3
        // Managed object model compatibility test
        guard let url = self.persistenceStoreFileURL(forSQLFileWithName: sqlFilename) else {
            print("ERROR: Can't create persistence store file url...")
            return
        }
        
        let compatible = self.isCompatible(storefile: url, atCoordinator: psc)
        if (compatible == false) { self.store = nil }
        
        // DATA FLUSHER
        // Core data stack for the master thread
        // [MASTER] -> [PERSISTENTSTORE]
        self.masterContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.masterContext.persistentStoreCoordinator = psc
        self.masterContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        self.masterContext.name = "MasterContext"
        
        // UI-RELATED CONTEXT
        // Core data stack for the main thread
        // [MAIN] -> [MASTER]
        self.mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        self.mainContext.parent = self.masterContext
        self.mainContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        self.mainContext.name = "MainContext"
        
        // BACKGROUND CONTEXT
        // Core data stack for the worker thread
        // [WORKER] -> [MAIN]
        self.workerContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.workerContext.parent = self.mainContext
        self.workerContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        self.workerContext.name = "WorkerContext"
        
        let sqliteConfig = ["journal_mode": "DELETE"]
        let options: [AnyHashable: Any] = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: sqliteConfig
        ]
        
        do {
            try self.store = psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at:url, options:options)
            print("Successful loading store!");
        }
        catch let error {
            print("ERROR: Can't load store! \(error)");
        }
    }
    
    // MARK: - Core Data Model
    
    fileprivate func retrieveCoreDataModel(withName name: String) -> NSManagedObjectModel? {
        let bundle = Bundle.main
        guard let modelURL = bundle.url(forResource: name, withExtension: "momd") else { return nil }
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else { return nil }
        return model
    }
    
    // MARK: - Store File Path
    
    fileprivate func applicationStoresDirectory() -> URL? {
        let documentsDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let storesDirectoryPath = (documentsDirectoryPath as NSString).appendingPathComponent("Stores")
        let fileManager = FileManager.default
        
        if (!fileManager.fileExists(atPath: storesDirectoryPath)) {
            do {
                try fileManager.createDirectory(atPath: storesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
                print("Successful creating application stores directory!");
            }
            catch let error {
                print("ERROR: Can't create application stores directory because: \(error)");
                return nil
            }
        }
        
        return URL(fileURLWithPath: storesDirectoryPath)
    }
    
    fileprivate func persistenceStoreFileURL(forSQLFileWithName name: String) -> URL? {
        if let fileURL = self.applicationStoresDirectory() {
            return fileURL.appendingPathComponent(name)
        }
        
        return nil
    }
    
    fileprivate func isCompatible(storefile storeURL: URL, atCoordinator coordinator: NSPersistentStoreCoordinator) -> Bool {
        let path = storeURL.path
        let fileManager = FileManager.default
        
        if (fileManager.fileExists(atPath: path)) {
            print("Checking model for compatibility...")
            
            do {
                let meta = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
                let coordinatorModel = coordinator.managedObjectModel
                
                if (coordinatorModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: meta)) {
                    print("Model is compatible!")
                    return true
                }
                else {
                    do {
                        try fileManager.removeItem(atPath: path)
                        print("ERROR: Model is not compatible. Removed file at path \(path)")
                    }
                    catch let error {
                        print("ERROR: Can't remove file at path \(path) because: \(error)")
                    }
                }
            }
            catch let error {
                print("ERROR: Checking for model compatibility because: \(error)")
            }
        }
        
        print("File does not exist!")
        
        return false
    }
    
    // MARK: - Saving Context
    
    fileprivate func saveContext() -> Bool {
        let ctx = self.workerContext
        return self.saveObjectContext(ctx!)
    }
    
    func saveObjectContext(_ ctx: NSManagedObjectContext) -> Bool {
        var success = false
        
        ctx.performAndWait {
            do {
                try ctx.save()
                print("Success saving tree context!");
                success = true
            }
            catch let error {
                print("ERROR: Saving tree context because: \(error)");
            }
            
            if let parentContext = ctx.parent {
                success = self.saveObjectContext(parentContext)
            }
        }
        
        return success
    }
    
    // MARK: - Core Data Utilities
    
    func retrieveEntity(_ entity: String, fromContext ctx: NSManagedObjectContext, filteredBy filter: NSPredicate?) -> NSManagedObject {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: entity)
        if let predicate = filter { fetchRequest.predicate = predicate }
        
        do {
            let items = try ctx.fetch(fetchRequest)
            
            if (items.count > 0) {
                return items.last!
            }
        }
        catch let error {
            print("ERROR: Retrieving data for entity \(entity) because: \(error)")
        }
        
        return NSEntityDescription.insertNewObject(forEntityName: entity, into: ctx)
    }
    
    func retrieveObjects(forEntity entity: String, filteredBy filter: NSPredicate? = nil) -> [NSManagedObject]? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: entity)
        
        if let predicate = filter {
            fetchRequest.predicate = predicate
        }
        
        do {
            let items = try self.workerContext.fetch(fetchRequest)
            
            if (items.count > 0) {
                return items
            }
        }
        catch let error {
            print("ERROR: Retrieving data for entity \(entity) because: \(error)")
        }
        
        return nil
    }
    
    func retrieveObjects(forEntity entity: String, filteredBy filter: NSPredicate? = nil, sortedBy sortDescriptor: NSSortDescriptor? = nil) -> [NSManagedObject]? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: entity)
        
        if let predicate = filter {
            fetchRequest.predicate = predicate
        }
        
        if let descriptor = sortDescriptor {
            fetchRequest.sortDescriptors = [descriptor]
        }
        
        do {
            let items = try self.workerContext.fetch(fetchRequest)
            
            if (items.count > 0) {
                return items
            }
        }
        catch let error {
            print("ERROR: Retrieving data for entity \(entity) because: \(error)")
        }
        
        return nil
    }
    
    func updateObjects(forEntity entity: String, filteredBy filter: NSPredicate, withData data: [String: Any]) -> Bool {
        guard let objects = self.retrieveObjects(forEntity: entity, filteredBy: filter) else {
            print("ERROR: Can't retrieve objects for entity \(entity)!")
            return false
        }
        
        var success = false
        let keys = Array(data.keys)
        
        for mo in objects {
            for k in keys {
                mo.setValue(data[k], forKey: k)
            }
            
            success = self.saveObjectContext(mo.managedObjectContext!)
        }
        
        return success
    }
    
    func clearEntities(_ entities: [String]) -> Bool {
        let ctx = self.retrieveObjectWorkerContext()
        
        for entity in entities {
            let success = self.clearEntity(entity, fromContext: ctx!, filteredBy: nil)
            if !success { return false }
        }
        
        return true
    }
    
    func clearEntity(_ entity: String, fromContext ctx: NSManagedObjectContext, filteredBy filter: NSPredicate?) -> Bool {
        var success = false
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: entity)
        
        if let predicate = filter {
            fetchRequest.predicate = predicate
        }
        
        ctx.performAndWait {
            do {
                let items = try ctx.fetch(fetchRequest)
                
                for mo in items {
                    ctx.delete(mo)
                }
            }
            catch let error {
                print("ERROR: Clearing data for entity \(entity) because: \(error)")
            }
            
            success = self.saveObjectContext(ctx)
        }
        
        return success
    }
    
    func retrieveObject(forEntity entity: String, filteredBy filter: NSPredicate? = nil) -> NSManagedObject? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest<NSManagedObject>(entityName: entity)
        
        if let predicate = filter {
            fetchRequest.predicate = predicate
        }
        
        do {
            let items = try self.workerContext.fetch(fetchRequest)
            
            if (items.count > 0) {
                return items.last!
            }
        }
        catch let error {
            print("ERROR: Retrieving data for entity \(entity) because: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Object Contexts
    
    func retrieveObjectWorkerContext() -> NSManagedObjectContext! {
        return self.workerContext
    }
    
    func retrieveObjectMainContext() -> NSManagedObjectContext! {
        return self.mainContext
    }
    
}
