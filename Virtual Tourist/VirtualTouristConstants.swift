//
//  VirtualTouristConstants.swift
//  Virtual Tourist
//
//  Created by Martin Kelly on 26/03/2016.
//  Copyright © 2016 Martin Kelly. All rights reserved.
//

import Foundation

extension VTClient {
    
    struct FlickrAPI {
        static let API_KEY = "88594165b4a167a3d232ba40e1220fb0"
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
    }
    
    struct Constants {
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
    }
    
    struct Keys {
        static let PhotoID = "id"
        static let PhotoURL = "url_m"
        static let Longitude = "longitude"
        static let Latitude = "latitude"
    }
}

