//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Martin Kelly on 26/03/2016.
//  Copyright © 2016 Martin Kelly. All rights reserved.
//
import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject, MKAnnotation {
    
    @NSManaged var longitude:Double
    @NSManaged var latitude:Double
    @NSManaged var photos:[Photo]?
    
    dynamic var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(self.latitude), longitude: CLLocationDegrees(self.longitude))
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        longitude = dictionary[VTClient.Keys.Longitude] as! Double
        latitude = dictionary[VTClient.Keys.Latitude] as! Double
        
        do {
            try context.save()
        } catch let error {
            print("An error occurred saving a pin in core data. Dictionary: \(dictionary), Error: \(error)")
        }
    }
}
