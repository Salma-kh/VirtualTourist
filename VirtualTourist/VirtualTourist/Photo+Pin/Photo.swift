//
//  Photo.swift
//  VirtualTourist
//
//  Created by salma apple on 1/21/19.
//  Copyright © 2019 Salma alenazi. All rights reserved.
//
import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject{
    static let name = "Photo"
    
    convenience init(title: String, imageurl: String, forPin: Pin, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: Photo.name, in: context) {
            self.init(entity: ent, insertInto: context)
            self.title = title
            self.image = nil
            self.imageurl = imageurl
            self.pin = forPin
        } else {
            fatalError("can not find Entity name!")
        }
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }
    
    @NSManaged public var image: NSData?
    @NSManaged public var title: String?
    @NSManaged public var imageurl: String?
    @NSManaged public var pin: Pin?
    
}

