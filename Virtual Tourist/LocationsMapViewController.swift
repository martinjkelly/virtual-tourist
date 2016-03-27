//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Martin Kelly on 26/03/2016.
//  Copyright © 2016 Martin Kelly. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationsMapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    let regionRadius: CLLocationDistance = 1000
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Convenience Properties
    lazy var sharedContext: NSManagedObjectContext = {
       return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: self.sharedContext,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
    }()
    
    lazy var defaults: NSUserDefaults = {
       return NSUserDefaults.standardUserDefaults()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        fetchedResultsController.delegate = self
        
        if let region = getMapPosition() {
            print("fetched matched map position from nsuserdefaults")
            mapView.region = region
        }
        
        getPins()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(LocationsMapViewController.dropPin))
        longPressRecognizer.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPressRecognizer)
    }
    
    func getPins() {
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            print("ERROR: thrown in getPins, details: \(error)")
        }
        
        if let pins = fetchedResultsController.fetchedObjects as? [Pin] {
            mapView.addAnnotations(pins)
        }
    }
    
    func dropPin(gestureRecogniser:UILongPressGestureRecognizer) {
        
        if gestureRecogniser.state == UIGestureRecognizerState.Began {
            
            let touchLocation = gestureRecogniser.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            let coordDict: [String: AnyObject] = [
                "longitude": NSNumber(double: coordinate.longitude),
                "latitude": NSNumber(double: coordinate.latitude)
            ]
            
            let pin = Pin(dictionary: coordDict, context: self.sharedContext)
            mapView.addAnnotation(pin)
            
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // intercept the segue and set the pin on the destination vc
        if (segue.identifier == "showAlbum") {
            let destinationVC = segue.destinationViewController as! PhotoAlbumViewController
            destinationVC.pin = sender as! Pin
        }
    }
    
    // MARK: Store and retrieve current map position
    
    struct MapViewPostiionKeys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let lonDelta = "lonDelta"
        static let latDelta = "latDelta"
    }
    
    func getMapPosition() -> MKCoordinateRegion? {
        
        let longitude = defaults.doubleForKey(MapViewPostiionKeys.longitude)
        if longitude > 0 {
            let latitude = defaults.doubleForKey(MapViewPostiionKeys.latitude)
            let lonDelta = defaults.doubleForKey(MapViewPostiionKeys.lonDelta)
            let latDelta = defaults.doubleForKey(MapViewPostiionKeys.latDelta)
            
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        } else {
            return nil
        }
    }
    
    func setMapPostition() {
        
        self.defaults.setDouble(mapView.region.center.latitude, forKey: MapViewPostiionKeys.latitude)
        self.defaults.setDouble(mapView.region.center.longitude, forKey: MapViewPostiionKeys.longitude)
        self.defaults.setDouble(mapView.region.span.latitudeDelta, forKey: MapViewPostiionKeys.latDelta)
        self.defaults.setDouble(mapView.region.span.longitudeDelta, forKey: MapViewPostiionKeys.lonDelta)
    }

}

extension LocationsMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.setMapPostition()
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
    
        mapView.deselectAnnotation(view.annotation, animated: true)
        self.performSegueWithIdentifier("showAlbum", sender: view.annotation as! Pin)
    }
}

