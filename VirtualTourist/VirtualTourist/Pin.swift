//
//  Pin.swift
//  VirtualTourist
//
//  Created by MacbookPRV on 27/06/2016.
//  Copyright © 2016 Pastouret Roger. All rights reserved.
//

import Foundation

import UIKit
import CoreData


class Pin: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    
    struct Keys {
        static let Title = "title"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        
    }
    
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        title = dictionary[Keys.Title] as? String
        latitude = dictionary[Keys.Latitude] as? NSNumber
        longitude = dictionary[Keys.Longitude] as? NSNumber
    }
  
    
    
}
