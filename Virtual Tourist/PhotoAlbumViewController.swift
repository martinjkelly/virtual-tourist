//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Martin Kelly on 26/03/2016.
//  Copyright © 2016 Martin Kelly. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController {
    
    // MARK: Properties
    var pin:Pin!
    private let reuseIdentifier = "albumCell"
    private let sectionInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    // MARK: Convenience Properties
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: self.sharedContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
        
        mapView.addAnnotation(pin)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            print("ERROR in PhotoAlbumViewController:viewDidLoad: failed to fetch photos: \(error)")
        }
        
        print(pin.photos?.count)
        
        if (pin.photos?.count == 0) {
            FlickrClient.sharedInstance().fetchImagesForLocation(pin.latitude, longitude: pin.longitude) { (success:Bool, photos: [[String: AnyObject]]?, errorString:String?) in
                
                if let photos = photos {
                    let _ = photos.map() { (dictionary: [String : AnyObject]) -> Photo in
                        let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                        
                        photo.pin = self.pin
                        
                        return photo
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        do {
                            try self.sharedContext.save()
                        } catch let error {
                            print("An error occurred saving photos in core data. Error: \(error)")
                        }
                    }
                }
            }
        }
    }

}

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! AlbumCell
        
        cell.backgroundColor = UIColor.grayColor()
        
        if let image = photo.image {
            cell.imageView.image = image
        } else {
            
            VTClient.sharedInstance().getImage(photo.url) { (success:Bool, data:NSData?, errorDescription:String?) in
                if success {
                    let image = UIImage(data: data!)
                    cell.imageView.image = image
                    FlickrClient.Caches.imageCache.storeImage(image, withIdentifier: photo.id)
                }
            }
        }
        
        return cell
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let size = (collectionView.frame.size.width / 3) - 2
        return CGSize(width: size, height: size)
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
}
