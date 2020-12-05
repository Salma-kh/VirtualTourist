//
//  Pin.swift
//  VirtualTourist
//
//  Created by salma apple on 1/21/19.
//  Copyright © 2019 Salma alenazi. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    static let name = "Pin"
    
    convenience init(lat: String, long : String, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: Pin.name, in: context) {
            self.init(entity: ent, insertInto: context)
            self.lat = lat
            self.long = long
        } else {
            fatalError("can not find Entity name!")
        }
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }
    
    @NSManaged public var lat: String?
    @NSManaged public var long : String?
    @NSManaged public var photos: NSSet?
    
    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: Photo)
    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: Photo)
    
    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)
    
    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)
    
}

