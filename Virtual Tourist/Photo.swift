//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Martin Kelly on 26/03/2016.
//  Copyright © 2016 Martin Kelly. All rights reserved.
//

import CoreData
import UIKit

class Photo: NSManagedObject {
    
    @NSManaged var url: String
    @NSManaged var id: String
    @NSManaged var pin: Pin
    var image: UIImage? {
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(self.id)
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary:[String:AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = dictionary[VTClient.Keys.PhotoID] as! String
        url = dictionary[VTClient.Keys.PhotoURL] as! String
        self.pin = dictionary["pin"] as! Pin
    }
    
    override func prepareForDeletion() {
        // delete the image from cache before we remove from coredata
        FlickrClient.Caches.imageCache.storeImage(nil, withIdentifier: self.id)
    }
}