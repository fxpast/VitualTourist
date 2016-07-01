//
//  Photo.swift
//  VirtualTourist
//
//  Created by MacbookPRV on 27/06/2016.
//  Copyright © 2016 Pastouret Roger. All rights reserved.
//

import Foundation

import UIKit
import CoreData


class Photo: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    
    struct Keys {
        static let Title = "title"
        static let Image = "image"
        static let UrlString = "urlString"
        static let OnePin = "onePin"
        
    }
    
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        title = dictionary[Keys.Title] as? String
        urlString = dictionary[Keys.UrlString] as? String
        image = dictionary[Keys.Image] as? NSData
        onePin = dictionary[Keys.OnePin] as? Pin
        
    }
    
    
    
}
