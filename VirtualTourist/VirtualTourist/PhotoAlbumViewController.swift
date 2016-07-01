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

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var IBMap: MKMapView!
    @IBOutlet weak var IBNewCollection: UIButton!
    @IBOutlet weak var IBAlbum: UICollectionView!
    @IBOutlet weak var IBEdit: UIBarButtonItem!
    
    var deleteFlag = false
    var pin: Pin!
    var photo:Photo!
    
    var running:Bool!
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
    
    
    //MARK: View Delegate
    
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
            loadPhotos()
        }
        else {
            
            
            self.navigationItem.title = "Max photos : \(pin.photos!.count)"
            
            IBAlbum.reloadData()
            
            self.IBNewCollection.enabled = true
            self.running = false
        }
        
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "editimage"  {
            
            let controller = segue.destinationViewController as! EditImageViewController
            
            controller.photo = photo
        }
        
    }

    
    
    @IBAction func ActionEdit(sender: AnyObject) {
        
        deleteFlag = !deleteFlag
        IBEdit.title = (deleteFlag) ? "Done" : "Delete"
        
    }
    
    
    
    //MARK: flickr
    
    private func loadPhotos() {

      
        
        TheImageDB.sharedInstance().displayImageFromFlickrBySearch(longitude, Lat: latitude, completionHandlerFlickrBySearch: { (success, photosArray, errorString) in
            
            
            if success {
                
                
                var dictionary = [String : AnyObject]()
                
                
                if photosArray!.count == 0 {
                    
                    dictionary[Photo.Keys.Title] = "noimage"
                    dictionary[Photo.Keys.UrlString] = ""
                    dictionary[Photo.Keys.OnePin] = self.pin
                    
                    performUIUpdatesOnMain {
                        
                        self.photo = Photo(dictionary: dictionary, context: self.sharedContext)
                        
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
                    
                    
                    performUIUpdatesOnMain({
                        
                        self.navigationItem.title = "Max photos : \(photosArray!.count)"
                        
                    })
                    
                    
                    //creating placeholders
                    dictionary[Photo.Keys.Title] = "noimage"
                    dictionary[Photo.Keys.UrlString] = ""
                    dictionary[Photo.Keys.OnePin] = self.pin
                    dictionary[Photo.Keys.Image] = nil
                    
                    for _ in 0...photosArray!.count-1 {
                        
                        performUIUpdatesOnMain {
                            
                            self.photo = Photo(dictionary: dictionary, context: self.sharedContext)
                            
                            // Save the context.
                            do {
                                try self.sharedContext.save()
                            } catch _ {}
                            
                            self.IBAlbum.reloadData()
                            
                        }

                    }
                    
                    
                    for photoIndex in 0...photosArray!.count-1 {
                        
                        let photoDictionary = photosArray![photoIndex] as [String:AnyObject]
                        let photoTitle = photoDictionary[TheImageDB.Constants.FlickrResponseKeys.Title] as? String
                        
                        guard let imageUrlString = photoDictionary[TheImageDB.Constants.FlickrResponseKeys.MediumURL] as? String else {
                            continue
                        }
                        
                        
                        let imageURL = NSURL(string: imageUrlString)
                        if NSData(contentsOfURL: imageURL!) != nil {
                            
                            
                            dictionary[Photo.Keys.Title] = photoTitle
                            dictionary[Photo.Keys.UrlString] = imageURL?.absoluteString
                            dictionary[Photo.Keys.Image] = NSData(contentsOfURL: imageURL!)
                            dictionary[Photo.Keys.OnePin] = self.pin
                            
                            
                            performUIUpdatesOnMain {
                            
                                self.photo = Photo(dictionary: dictionary, context: self.sharedContext)
                                
                                // Save the context.
                                do {
                                    try self.sharedContext.save()
                                } catch _ {}
                                
                                self.IBAlbum.reloadData()
                                
                            }
                            
                            
                        }
                        else {
                            continue
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
                    self.IBNewCollection.enabled = true
                    
                }
            }
            
        })
        
        
        
    }
    
    
    
    @IBAction func ActionNewCollection(sender: AnyObject) {
        
        running = true
        IBNewCollection.enabled = false
        
        
        for value in pin.photos! {
            
        
            photo = value as! Photo
            sharedContext.deleteObject(photo)
            
            // Save the context.
            do {
                try sharedContext.save()
            } catch let error as NSError {
                print(error.debugDescription)
                
            }
            IBAlbum.reloadData()
    
        }
       
        
        loadPhotos()
        
        
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
        
        
        
        for (index, value) in self.pin.photos!.enumerate() {
            
            if index == indexPath.row {
                photo = value as! Photo
                break
            }
            
        }
        
        
        if deleteFlag==false {
            
            if running == false {
               
                if photo.urlString == "" {
                    
                    for value in pin.photos! {
                        
                        photo = value as! Photo
                        
                        if photo.urlString == "" {
                            
                            sharedContext.deleteObject(photo)
                            
                            // Save the context.
                            do {
                                try sharedContext.save()
                            } catch let error as NSError {
                                print(error.debugDescription)
                                
                            }
                            IBAlbum.reloadData()
                            
                        }
                        
                    }
       
                    
                }
                else {
                    performSegueWithIdentifier("editimage", sender: self)
                    
                }
                
                
            }
        }
        else {
            
            
            sharedContext.deleteObject(self.photo)
            // Save the context.
            do {
                try sharedContext.save()
            } catch let error as NSError {
                print(error.debugDescription)
                
            }
            
            IBAlbum.reloadData()
        
        }
        
        
        
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
    
    
    
    
}