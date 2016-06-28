//
//  EditImage.swift
//  VirtualTourist
//
//  Created by MacbookPRV on 27/06/2016.
//  Copyright © 2016 Pastouret Roger. All rights reserved.
//

import Foundation

import CoreData
import UIKit


class EditImage: UIViewController {
    
    @IBOutlet weak var IBImageview: UIImageView!
    
    @IBOutlet weak var IBTitre: UILabel!
    
    var photo: Photo!
    
    
    var sharedContext: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.managedObjectContext
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        IBTitre.text = photo.title
        
        IBImageview.image = UIImage(data: photo.image!)
        
        IBImageview.contentMode = UIViewContentMode.ScaleAspectFit
        
        
    }
    
    
    
    @IBAction func ActionDelete(sender: AnyObject) {
        
        
        performUIUpdatesOnMain({
            
            
            self.photo.title = "noimage"
            self.photo.urlString = "";
            self.photo.image = UIImagePNGRepresentation(UIImage(named: "noimage")!)
            
            // Save the context.
            do {
                try self.sharedContext.save()
            } catch let error as NSError {
                print(error.debugDescription)
                
            }
            
        })
        
        dismissViewControllerAnimated(true, completion: nil)

        
    }
    @IBAction func ActionCancel(sender: AnyObject) {
        
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
}
