//
//  CoreData.swift
//  VirtualTourist
//
//  Created by salma apple on 1/21/19.
//  Copyright © 2019 Salma alenazi. All rights reserved.
//

import CoreData

struct  CoreData{
    
    // Properties
    private let model: NSManagedObjectModel
    internal let coordinators: NSPersistentStoreCoordinator
    private let modelUrl: URL
    internal let dropUrl: URL
    internal let persistingContext: NSManagedObjectContext
    internal let backgroundContext: NSManagedObjectContext
    let context: NSManagedObjectContext
    // Shared Instance
    static func shared() -> CoreData {
        struct Singleton {
            static var shared = CoreData(modelName: "VirtualTouristModel")!
        }
        return Singleton.shared
    }
    //Initializers
    init?(modelName: String) {
        guard let modelUrl = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("can not find \(modelName)in the main bundle")
            return nil
        }
        self.modelUrl = modelUrl
        // Try to create the model from the URL
        guard let model = NSManagedObjectModel(contentsOf: modelUrl) else {
            print("can not create a model from \(modelUrl)")
            return nil
        }
        self.model = model
        coordinators = NSPersistentStoreCoordinator(managedObjectModel: model)
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinators
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        let FileManager1 = FileManager.default
        guard let Url = FileManager1.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("can not reach the documents folder")
            return nil
        }
        
        self.dropUrl =  Url.appendingPathComponent("modelSQLite")
        
        let options = [
            NSInferMappingModelAutomaticallyOption: true,
            NSMigratePersistentStoresAutomaticallyOption: true
        ]
        
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dropUrl, options: options as [NSObject : AnyObject]?)
        } catch {
            print("can not add store at \(dropUrl)")
        }
    }
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        try coordinators.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dropUrl, options: nil)
    }
    
    func fetchPin(_ predicate: NSPredicate, entityName: String, sorting: NSSortDescriptor? = nil) throws -> Pin? {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetch.predicate = predicate
        if let sort = sorting {
            fetch.sortDescriptors = [sort]
        }
        guard let pin = (try context.fetch(fetch) as! [Pin]).first else {
            return nil
        }
        return pin
    }
    
    func fetchPins(_ predicate: NSPredicate? = nil, entityName: String, sorting: NSSortDescriptor? = nil) throws -> [Pin]? {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetch.predicate = predicate
        if let sort = sorting {
            fetch.sortDescriptors = [sort]
        }
        guard let pin = try context.fetch(fetch) as? [Pin] else {
            return nil
        }
        return pin
    }
    
    func fetchPhotos(_ predicate: NSPredicate? = nil, entityName: String, sorting: NSSortDescriptor? = nil) throws -> [Photo]? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fr.predicate = predicate
        if let sort = sorting {
            fr.sortDescriptors = [sort]
        }
        guard let photos = try context.fetch(fr) as? [Photo] else {
            return nil
        }
        return photos
    }
}

// Removing Data

internal extension CoreData  {
    
    func dropData() throws {
        try coordinators.destroyPersistentStore(at: dropUrl, ofType:NSSQLiteStoreType , options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dropUrl, options: nil)
    }
    
    func saveContext() throws {
        context.performAndWait() {
            
            if self.context.hasChanges {
                do {
                    try self.context.save()
                } catch {
                    print("Error in saving main context: \(error)")
                }
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        print("Error in saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    func autoSave(_ save : Int) {
        if save > 0 {
            do {
                try saveContext()
                print("Autosaving")
            } catch {
                print("Error while autosaving")
            }
            let save = UInt64(save) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(save)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(Int(save))
            }
        }
    }
}


