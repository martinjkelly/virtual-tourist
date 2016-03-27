//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Martin Kelly on 26/03/2016.
//  Copyright © 2016 Martin Kelly. All rights reserved.
//

import Foundation

class FlickrClient: VTClient {
    
    override class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    func fetchImagesForLocation(latitude:Double, longitude:Double, completionHandler:(success:Bool, photos:[[String: AnyObject]]?, errorDescription:String?) -> Void) {
        
        let methodArguments = [
            "method": VTClient.FlickrAPI.METHOD_NAME,
            "api_key": VTClient.FlickrAPI.API_KEY,
            "bbox": createBoundingBoxString(latitude, longitude: longitude),
            "safe_search": VTClient.Constants.SAFE_SEARCH,
            "extras": VTClient.Constants.EXTRAS,
            "format": VTClient.Constants.DATA_FORMAT,
            "nojsoncallback": VTClient.Constants.NO_JSON_CALLBACK
        ]
        
        self.fetch(methodArguments) { (result:VTClient.Result) in
            
            switch result {
            case .Failure(let error):
                print("login failed with error: \(error)")
                completionHandler(success: false, photos: nil, errorDescription: (error.userInfo[NSLocalizedDescriptionKey] as! String))
                break
            case .Success(let res):
        
                /* GUARD: Did Flickr return an error? */
                guard let stat = res!["stat"] as? String where stat == "ok" else {
                    print("Flickr API returned an error. See error code and message in \(res)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = res!["photos"] as? NSDictionary else {
                    print("Cannot find keys 'photos' in \(res!)")
                    return
                }
                
                /* GUARD: Is "pages" key in the photosDictionary? */
                guard let totalPages = photosDictionary["pages"] as? Int else {
                    print("Cannot find key 'pages' in \(photosDictionary)")
                    return
                }
                
                /* Pick a random page! */
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                self.getImagesFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage, completionHandler: completionHandler)
                
                break
            }
            
        }
    }
    
    func getImagesFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler:(success:Bool, photos:[[String: AnyObject]]?, errorDescription:String?) -> Void) {
        
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        self.fetch(withPageDictionary) { (result:VTClient.Result) in
            
            switch result {
            case .Failure(let error):
                print("login failed with error: \(error)")
                completionHandler(success: false, photos: nil, errorDescription: (error.userInfo[NSLocalizedDescriptionKey] as! String))
                break
            case .Success(let res):
                
                /* GUARD: Did Flickr return an error? */
                guard let stat = res!["stat"] as? String where stat == "ok" else {
                    print("Flickr API returned an error. See error code and message in \(res)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = res!["photos"] as? NSDictionary else {
                    print("Cannot find keys 'photos' in \(res!)")
                    return
                }
                
                /* GUARD: Is the "total" key in photosDictionary? */
                guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                    print("Cannot find key 'total' in \(photosDictionary)")
                    return
                }
                
                if totalPhotosVal > 0 {
                    
                    /* GUARD: Is the "photo" key in photosDictionary? */
                    guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                        print("Cannot find key 'photo' in \(photosDictionary)")
                        return
                    }
                    
                    completionHandler(success: true, photos: photosArray, errorDescription: nil)
                } else {
                    completionHandler(success: false, photos: nil, errorDescription: "No images found")
                }
                
                break
            }
            
        }
    }

    
    // MARK: Lat/Lon Manipulation
    
    func createBoundingBoxString(latitude:Double, longitude:Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - VTClient.Constants.BOUNDING_BOX_HALF_WIDTH, VTClient.Constants.LON_MIN)
        let bottom_left_lat = max(latitude - VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT, VTClient.Constants.LAT_MIN)
        let top_right_lon = min(longitude + VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT, VTClient.Constants.LON_MAX)
        let top_right_lat = min(latitude + VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT, VTClient.Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
}