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


class EditImageViewController: UIViewController {
    
    @IBOutlet weak var IBImageview: UIImageView!
    
    @IBOutlet weak var IBDelete: UIBarButtonItem!
    
    var photo: Photo!
    
    
    var sharedContext: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.managedObjectContext
    }
    
    
    
    //MARK: View Delegate
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = photo.title
        
        IBImageview.image = UIImage(data: photo.image!)
        
        IBImageview.contentMode = UIViewContentMode.ScaleAspectFit
        
        
    }
    
    
    @IBAction func ActionCancel(sender: AnyObject) {
        
        dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBAction func ActionDelete(sender: AnyObject) {
        
        IBDelete.enabled = false
        
        sharedContext.deleteObject(self.photo)
        // Save the context.
        do {
            try sharedContext.save()
        } catch let error as NSError {
            print(error.debugDescription)
            
        }
     
        dismissViewControllerAnimated(true, completion: nil)
        
    }
  
    
    
}
