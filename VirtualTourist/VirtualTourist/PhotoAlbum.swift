//
//  PhotoAlbum.swift
//  VirtualTourist
//
//  Created by MacbookPRV on 27/06/2016.
//  Copyright © 2016 Pastouret Roger. All rights reserved.
//

import Foundation

import CoreData
import UIKit
import MapKit

class PhotoAlbum: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var IBMap: MKMapView!
    @IBOutlet weak var IBNewCollection: UIButton!
    @IBOutlet weak var IBAlbum: UICollectionView!
    
    var pin: Pin!
    var photo:Photo!
    
    var running:Bool!
    let qtePhotos = 30
    
    var latitude:CLLocationDegrees!
    var longitude:CLLocationDegrees!
    
    
    var sharedContext: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.managedObjectContext
    }
    
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    
    //MARK: UIView Delegate
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        IBMap.delegate = self
        IBAlbum.delegate = self
        IBAlbum.dataSource = self
        IBMap.pitchEnabled = false
        IBMap.rotateEnabled = false
        IBMap.scrollEnabled = false
        IBNewCollection.enabled = false
        
        running=true
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            longitude = regionDictionary["longitude"] as! CLLocationDegrees
            latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            IBMap.setRegion(savedRegion, animated: false)
            
            var annotations = [MKPointAnnotation]()
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
            IBMap.addAnnotations(annotations)
            
        }
        
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        
        if pin.photos!.count == 0  {
            
            TheImageDB.sharedInstance().displayImageFromFlickrBySearch(longitude, Lat: latitude, completionHandlerFlickrBySearch: { (success, photosArray, errorString) in
                
                
                if success {
                    
                    
                    var dictionary = [String : AnyObject]()
                    
                    if photosArray!.count == 0 {
                        
                        
                        dictionary[Photo.Keys.Title] = "noimage"
                        dictionary[Photo.Keys.UrlString] = ""
                        
                        performUIUpdatesOnMain {
                            
                            dictionary[Photo.Keys.OnePin] = self.pin
                            
                            self.photo = Photo(dictionary: dictionary, context: self.sharedContext)
                            // Append the photo to the array
                            self.photo.onePin = self.pin
                            
                            // Save the context.
                            do {
                                try self.sharedContext.save()
                            } catch _ {}
                            
                            self.IBAlbum.reloadData()
                            
                            self.IBNewCollection.enabled = true
                            self.running = false
                            
                        }
                        
                        
                    }
                    else{
                        
                        for photoIndex in 0...photosArray!.count-1 {
                            
                            let photoDictionary = photosArray![photoIndex] as [String:AnyObject]
                            let photoTitle = photoDictionary[TheImageDB.Constants.FlickrResponseKeys.Title] as? String
                            
                            guard let imageUrlString = photoDictionary[TheImageDB.Constants.FlickrResponseKeys.MediumURL] as? String else {
                                
                                performUIUpdatesOnMain {
                                    self.displayAlert("Error", mess: "Impossible de trouver cle : \(TheImageDB.Constants.FlickrResponseKeys.MediumURL) dans \(photoDictionary)")
                                    self.running = false
                                }
                                
                                return
                            }
                            
                            
                            let imageURL = NSURL(string: imageUrlString)
                            if NSData(contentsOfURL: imageURL!) != nil {
                                
                                performUIUpdatesOnMain {
                                    
                                    dictionary[Photo.Keys.Title] = photoTitle
                                    dictionary[Photo.Keys.UrlString] = imageURL?.absoluteString
                                    dictionary[Photo.Keys.Image] = NSData(contentsOfURL: imageURL!)
                                    dictionary[Photo.Keys.OnePin] = self.pin
                                    
                                    self.photo = Photo(dictionary: dictionary, context: self.sharedContext)
                                    // Append the photo to the array
                                    self.photo.onePin = self.pin
                                    
                                    // Save the context.
                                    do {
                                        try self.sharedContext.save()
                                    } catch _ {}
                                    
                                    self.IBAlbum.reloadData()
                                    
                                }
                                
                                
                            }
                            else {
                                
                                
                                performUIUpdatesOnMain {
                                    self.displayAlert("Error", mess: "l'image n'existe pas :\(imageURL)")
                                    self.running = false
                                }
                                return
                            }
                            
                            
                            if photoIndex == self.qtePhotos {
                                break
                            }
                        }
                        
                        performUIUpdatesOnMain({
                            
                            
                            self.IBNewCollection.enabled = true
                            self.running = false
                            
                            
                        })
                        
                        
                    }
                    
                    
                }
                else {
                    performUIUpdatesOnMain {
                        self.displayAlert("Error", mess: errorString!)
                        self.running = false
                        
                    }
                }
                
            })
            
        }
        else {
            
            IBAlbum.reloadData()
            
            self.IBNewCollection.enabled = true
            self.running = false
        }
        
    }
    
    @IBAction func ActionClear(sender: AnyObject) {
        
        running = true
        IBNewCollection.enabled = false
        
        
        performUIUpdatesOnMain({
            
            for unPhoto in self.pin.photos! {
                
                self.photo = unPhoto as! Photo

                self.photo.title = "noimage"
                self.photo.urlString = "";
                self.photo.image = UIImagePNGRepresentation(UIImage(named: "noimage")!)
                
                // Save the context.
                do {
                    try self.sharedContext.save()
                } catch let error as NSError {
                    print(error.debugDescription)
                    
                }
                
                self.IBAlbum.reloadData()
                
            }
            
            self.running = false
            self.IBNewCollection.enabled = true
            
            
        })

        
        
    }
    
    @IBAction func ActionNewCollection(sender: AnyObject) {
        
        running = true
        IBNewCollection.enabled = false
        
        TheImageDB.sharedInstance().displayImageFromFlickrBySearch(longitude, Lat: latitude, completionHandlerFlickrBySearch: { (success, photosArray, errorString) in
            
            
            if success {
                
                
                var dictionary = [String : AnyObject]()
                
                if photosArray!.count == 0 {
                    
                    
                    dictionary[Photo.Keys.Title] = "noimage"
                    dictionary[Photo.Keys.UrlString] = ""
                    
                    performUIUpdatesOnMain {
                        
                        dictionary[Photo.Keys.OnePin] = self.pin
                        
                        self.photo = Photo(dictionary: dictionary, context: self.sharedContext)
                        // Append the photo to the array
                        self.photo.onePin = self.pin
                        
                        // Save the context.
                        do {
                            try self.sharedContext.save()
                        } catch _ {}
                        
                        self.IBAlbum.reloadData()
                        
                        self.IBNewCollection.enabled = true
                        self.running = false
                        
                    }
                    
                    
                }
                else{
                    
                    
                    var totalEditPhotos = 0
                    for unPhoto in self.pin.photos! {
                        
                        self.photo = unPhoto as! Photo
                        if self.photo.urlString == "" {
                            totalEditPhotos+=1
                        }
                        
                    }
                    
                    
                    for photoIndex in 0...photosArray!.count-1 {
                        
 
                        let photoDictionary = photosArray![photoIndex] as [String:AnyObject]
                        let photoTitle = photoDictionary[TheImageDB.Constants.FlickrResponseKeys.Title] as? String
                        
                        guard let imageUrlString = photoDictionary[TheImageDB.Constants.FlickrResponseKeys.MediumURL] as? String else {
                            
                            performUIUpdatesOnMain {
                                self.displayAlert("Error", mess: "Impossible de trouver cle : \(TheImageDB.Constants.FlickrResponseKeys.MediumURL) dans \(photoDictionary)")
                                self.running = false
                            }
                            
                            return
                        }
                        
                        
                        let imageURL = NSURL(string: imageUrlString)
                        if NSData(contentsOfURL: imageURL!) != nil {
                            
                            performUIUpdatesOnMain {
                                
                                if totalEditPhotos > 0 {
                                
                                    totalEditPhotos-=1
                                    for unPhoto in self.pin.photos! {
                                        
                                        self.photo = unPhoto as! Photo
                                        if self.photo.urlString == "" {
                                            self.photo.urlString = imageURL?.absoluteString
                                            self.photo.title = photoTitle
                                            self.photo.image = NSData(contentsOfURL: imageURL!)
                                            
                                            break
                                        }
                                        
                                    }
                                    
                                }
                                else {
                                    self.IBNewCollection.enabled = true
                                    self.running = false
                                    
                                    return
                                }
                                
                            
                                // Save the context.
                                do {
                                    try self.sharedContext.save()
                                } catch _ {}
                                
                                self.IBAlbum.reloadData()
                                
                                
                            }
                            
                            
                        }
                        else {
                            
                            
                            performUIUpdatesOnMain {
                                self.displayAlert("Error", mess: "l'image n'existe pas :\(imageURL)")
                                self.running = false
                            }
                            return
                        }
                        
                        
                        if photoIndex == self.qtePhotos {
                            break
                        }
                    }
                    
                    performUIUpdatesOnMain({
                        
                        
                        self.IBNewCollection.enabled = true
                        self.running = false
                        
                        
                    })
                    
                    
                }
                
                
            }
            else {
                performUIUpdatesOnMain {
                    self.displayAlert("Error", mess: errorString!)
                    self.running = false
                    
                }
            }
            
        })
        
        
        
        
        
    }
    
    //MARK: Map View Delegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView?.pinTintColor = UIColor.redColor()
            
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    //MARK: Collection View Delegate
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return pin.photos!.count
        
    }
    
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        
        let item = collectionView.dequeueReusableCellWithReuseIdentifier("item", forIndexPath: indexPath)
        
        for (index, value) in self.pin.photos!.enumerate() {
            
            if index == indexPath.row {
                photo = value as! Photo
                break
            }
            
        }
        
        let aView = UIImageView()
        
        if photo.urlString=="" {
            aView.image = UIImage(named: photo.title!)
        }
        else {
            
            aView.image = UIImage(data: photo.image!)
        }
        
        item.backgroundView = aView
        
        return item
        
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if running==false {
            
            for (index, value) in self.pin.photos!.enumerate() {
                
                if index == indexPath.row {
                    photo = value as! Photo
                    break
                }
                
            }
            
            var controller = EditImage()
            controller = self.storyboard?.instantiateViewControllerWithIdentifier("editimage") as! EditImage
            controller.photo = photo
            presentViewController(controller, animated: true, completion: nil)
            
        }
        
        
    }
    
    
    
}