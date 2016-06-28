//
//  BlackBox.swift
//  On the Map
//
//  Created by MacbookPRV on 03/05/2016.
//  Copyright © 2016 Pastouret Roger. All rights reserved.
//


import Foundation
import UIKit


func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}


extension UIViewController {
    
    
    func displayAlert(title:String, mess : String) {
        
        let alertController = UIAlertController(title: title, message: mess, preferredStyle: .Alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
}


extension NSDate {
    func dateFromString(date: String, format: String) -> NSDate {
        let formatter = NSDateFormatter()
        let locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        formatter.locale = locale
        formatter.dateFormat = format
        
        return formatter.dateFromString(date)!
    }
}



func StatusCode (code:Int) -> String {
    
    var text:String
    
    
    switch (code) {
    case 100: text = "Continue" 
    case 101: text = "Switching Protocols" 
    case 200: text = "OK" 
    case 201: text = "Created" 
    case 202: text = "Accepted" 
    case 203: text = "Non-Authoritative Information" 
    case 204: text = "No Content" 
    case 205: text = "Reset Content" 
    case 206: text = "Partial Content" 
    case 300: text = "Multiple Choices" 
    case 301: text = "Moved Permanently" 
    case 302: text = "Moved Temporarily" 
    case 303: text = "See Other" 
    case 304: text = "Not Modified" 
    case 305: text = "Use Proxy" 
    case 400: text = "Bad Request" 
    case 401: text = "Unauthorized" 
    case 402: text = "Payment Required" 
    case 403: text = "Forbidden" 
    case 404: text = "Not Found" 
    case 405: text = "Method Not Allowed" 
    case 406: text = "Not Acceptable" 
    case 407: text = "Proxy Authentication Required" 
    case 408: text = "Request Time-out" 
    case 409: text = "Conflict" 
    case 410: text = "Gone" 
    case 411: text = "Length Required" 
    case 412: text = "Precondition Failed" 
    case 413: text = "Request Entity Too Large" 
    case 414: text = "Request-URI Too Large" 
    case 415: text = "Unsupported Media Type" 
    case 500: text = "Internal Server Error" 
    case 501: text = "Not Implemented" 
    case 502: text = "Bad Gateway" 
    case 503: text = "Service Unavailable" 
    case 504: text = "Gateway Time-out" 
    case 505: text = "HTTP Version not supported" 
    default:
        text = "Unknown http status code "
        
    }
    
    return "\(code) : \(text)"
    
}


