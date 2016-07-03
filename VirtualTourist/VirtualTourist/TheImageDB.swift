//
//  TheImageDB.swift
//  VirtualTourist
//
//  Created by MacbookPRV on 27/06/2016.
//  Copyright © 2016 Pastouret Roger. All rights reserved.
//

import Foundation


class TheImageDB : NSObject {
    
    
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> TheImageDB {
        
        struct Singleton {
            static var sharedInstance = TheImageDB()
        }
        
        return Singleton.sharedInstance
    }
    
    
    func displayImageFromFlickrBySearch(Lon:Double, Lat:Double, completionHandlerFlickrBySearch: (success: Bool, photosArray: [[String:AnyObject]]?, errorString: String?) -> Void) {
        
        let cord1 = (String)(Lon-Constants.Flickr.SearchBBoxHalfWidth)
        let cord2 = (String)(Lat-Constants.Flickr.SearchBBoxHalfHeight)
        let cord3 = (String)(Lon+Constants.Flickr.SearchBBoxHalfWidth)
        let cord4 = (String)(Lat+Constants.Flickr.SearchBBoxHalfHeight)
        let result =  "\(cord1),\(cord2),\(cord3),\(cord4)"
        
        
        let methodParam = [
            
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: result,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.NbrePerPage,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        var methodParameters = [String:AnyObject]()
        methodParameters = methodParam
        
        
        // TODO: Make request to Flickr!
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            
            
            guard (error == nil) else {
                completionHandlerFlickrBySearch(success: false, photosArray: nil, errorString: "Erreur : \(error)")
                return
            }
            
            guard let status = ((response as? NSHTTPURLResponse)?.statusCode) where status >= 200 && status <= 299 else {
                completionHandlerFlickrBySearch(success: false, photosArray: nil, errorString:"status code hors valeurs 2xx")
                return
            }
            
            guard let _ = data else {
                completionHandlerFlickrBySearch(success: false, photosArray: nil, errorString:"aucune données retournées")
                return
            }
            
            //parseur de données
            
            let parsedResult: AnyObject
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
            }
            catch {
                
                completionHandlerFlickrBySearch(success: false, photosArray: nil, errorString:"impossible de parse les données '\(data)'")
                return
            }
            
            guard let stat = (parsedResult[Constants.FlickrResponseKeys.Status] as? String) where stat == Constants.FlickrResponseValues.OKStatus else {
                completionHandlerFlickrBySearch(success: false, photosArray: nil, errorString:"erreur api, voir : '\(parsedResult)'")
                return
            }
            
            guard let photosDictionary = (parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject]) else {
                completionHandlerFlickrBySearch(success: false, photosArray: nil, errorString:"cle \(Constants.FlickrResponseKeys.Photos) non trouvée dans '\(parsedResult)'")
                return
            }
            
            
            guard let pages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                
                completionHandlerFlickrBySearch(success: false, photosArray: nil, errorString:"cle \(Constants.FlickrResponseKeys.Photos) non trouvée dans '\(photosDictionary)'")
                return
            }
            
            print("pages : \(pages)")
            let randomPagesIndex = Int(arc4random_uniform(UInt32((Constants.pages))))

            var tabParam = methodParameters
            tabParam[Constants.FlickrParameterKeys.Page] = randomPagesIndex
            let tabPar = tabParam
            
            self.displayImagePageFromFlickrBySearch(tabPar, completionHandlerPageFlickrBySearch: { (success, resultArray, errorString) in
                if success {
                    completionHandlerFlickrBySearch(success: true, photosArray: resultArray, errorString: "")
                }
            })
            
            
            
        })
        
        task.resume()
        
    }
    
    
    
    
    // MARK: Flickr API
    
    private func displayImagePageFromFlickrBySearch(methodParameters: [String:AnyObject], completionHandlerPageFlickrBySearch: (success: Bool, resultArray: [[String:AnyObject]]?, errorString: String?) -> Void) {
        
        
        // TODO: Make request to Flickr!
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
        let task = session.dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            
            
            guard (error == nil) else {
                completionHandlerPageFlickrBySearch(success: false, resultArray: nil, errorString: "Erreur : \(error)")
                return
            }
            
            guard let status = ((response as? NSHTTPURLResponse)?.statusCode) where status >= 200 && status <= 299 else {
                completionHandlerPageFlickrBySearch(success: false, resultArray: nil, errorString: "status code hors valeurs 2xx")
                return
            }
            
            guard let _ = data else {
                completionHandlerPageFlickrBySearch(success: false, resultArray: nil, errorString: "aucune données retournées")
                return
            }
            
            //parseur de données
            
            let parsedResult: AnyObject
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
            }
            catch {
                completionHandlerPageFlickrBySearch(success: false, resultArray: nil, errorString: "impossible de parse les données '\(data)'")
                return
            }
            
            guard let stat = (parsedResult[Constants.FlickrResponseKeys.Status] as? String) where stat == Constants.FlickrResponseValues.OKStatus else {
                completionHandlerPageFlickrBySearch(success: false, resultArray: nil, errorString: "erreur api, voir : '\(parsedResult)'")
                return
            }
            
            guard let photosDictionary = (parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject]) else {
                completionHandlerPageFlickrBySearch(success: false, resultArray: nil, errorString: "cle \(Constants.FlickrResponseKeys.Photos) non trouvée dans '\(parsedResult)'")
                return
            }
            
            
            guard let photosArray = (photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]]) else {
                completionHandlerPageFlickrBySearch(success: false, resultArray: nil, errorString:"cle photo \(Constants.FlickrResponseKeys.Photo) non trouvée dans '\(photosDictionary)'")
                return
            }
            
            completionHandlerPageFlickrBySearch(success: true, resultArray: photosArray, errorString: "")
            
            
        })
        
        task.resume()
        
    }
    
    
    
    // MARK: Helper for Creating a URL from Parameters
    
    func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    
    
}
