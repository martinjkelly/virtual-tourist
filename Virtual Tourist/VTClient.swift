//
//  VirtualTourist.swift
//  Virtual Tourist
//
//  Created by Martin Kelly on 26/03/2016.
//  Copyright © 2016 Martin Kelly. All rights reserved.
//

import Foundation

class VTClient : NSObject {
    
    typealias CompletionHandlerType = (Result) -> Void
    
    enum Result {
        case Success(AnyObject?)
        case Failure(NSError)
    }
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    class func sharedInstance() -> VTClient {
        
        struct Singleton {
            static var sharedInstance = VTClient()
        }
        
        return Singleton.sharedInstance
    }
    
    // HTTP GET request
    func fetch(parameters: [String:AnyObject], completionHandler: CompletionHandlerType) -> NSURLSessionDataTask {
        
        let url = NSURL(string: VTClient.FlickrAPI.BASE_URL + VTClient.escapedParameters(parameters))
        let request = NSMutableURLRequest(URL: url!)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            self.handleResponse(request, data: data, response: response, error: error, completionHandler: completionHandler)
        }
        
        task.resume()
        
        return task
    }
    
    // Response handler, parses JSON response, checks status code, and calls the completion handler
    private func handleResponse(request:NSURLRequest, data:NSData?, response:NSURLResponse?, error:NSError?, completionHandler:CompletionHandlerType) -> Void {
        
        guard (error == nil) else {
            completionHandler(Result.Failure(error!))
            return
        }
        
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
            var errorString = ""
            if let response = response as? NSHTTPURLResponse {
                
                switch response.statusCode {
                case 401, 403:
                    errorString = "Your login details are incorrect, Please try again"
                    break;
                default:
                    errorString = "Your request returned an invalid response! Status code: \(response.statusCode)!"
                    break;
                }
                
            } else if let response = response {
                errorString = "Your request returned an invalid response! Response: \(response)!"
            } else {
                errorString = "Your request returned an invalid response!"
            }
            
            completionHandler(Result.Failure(NSError(domain: "VTClient:fetch", code: 0, userInfo: [NSLocalizedDescriptionKey: errorString])))
            return
        }
        
        guard let data = data else {
            completionHandler(Result.Failure(NSError(domain: "VTClient:fetch", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data returned from request"])))
            return
        }
        
        VTClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
        
    }
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandlerType) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            completionHandler(Result.Failure(NSError(domain: "VTClient:parseJson", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to parse JSON: \(String(data))"])))
        }
        
        completionHandler(Result.Success(parsedResult))
    }
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}