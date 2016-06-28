//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by MacbookPRV on 28/06/2016.
//  Copyright © 2016 Pastouret Roger. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var title: String?
    @NSManaged var urlString: String?
    @NSManaged var image: NSData?
    @NSManaged var onePin: Pin?

}
