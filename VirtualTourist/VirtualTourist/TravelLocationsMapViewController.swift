//
//  ViewController.swift
//  VirtualTourist
//
//  Created by MacbookPRV on 25/06/2016.
//  Copyright © 2016 Pastouret Roger. All rights reserved.
//

import UIKit
import MapKit
import CoreData


struct curCoordinate {
    static var latitude:CLLocationDegrees!
    static var longitude:CLLocationDegrees!
}



class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var IBMap: MKMapView!
    @IBOutlet weak var IBtextfield: UITextField!
    @IBOutlet weak var IBDelete: UIBarButtonItem!
    
    
    var pins = [Pin]()
    var deleteFlag = false
    
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
        
        // Do any additional setup after loading the view, typically from a nib.
        IBMap.delegate = self
        IBtextfield.delegate = self
        
        pins = fetchAllPins()
        
        restoreMapRegion(false)
        let longPressGestureRecognizer = UILongPressGestureRecognizer.init(target: self, action:#selector(TravelLocationsMapViewController.handleLongPressRecognizer(_:)))
        longPressGestureRecognizer.numberOfTouchesRequired = 1
        longPressGestureRecognizer.minimumPressDuration = 0.5
        longPressGestureRecognizer.delaysTouchesBegan = true
        longPressGestureRecognizer.delegate = self
        view.addGestureRecognizer(longPressGestureRecognizer)
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadPins()
    }
    
    
    @IBAction func ActionDelete(sender: AnyObject) {
        
        deleteFlag = !deleteFlag
        IBDelete.title = (deleteFlag) ? "Done" : "Delete"
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "photoalbum"  {
            
            let controller = segue.destinationViewController as! PhotoAlbumViewController
            for p in pins {
                if p.latitude  == curCoordinate.latitude   && p.longitude  == curCoordinate.longitude {
                    controller.pin = p
                    break
                }
            }
        }
        
    }
    
    
    //MARK: coreData function
    
    
    func fetchAllPins() -> [Pin] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch _ {
            return [Pin]()
        }
    }
    
    
    func loadPins() {
        
        
        
        var annotations = [MKPointAnnotation]()
        for pin in pins {
            
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude as! CLLocationDegrees, longitude: pin.longitude as! CLLocationDegrees)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = pin.title
            annotations.append(annotation)
            IBMap.addAnnotations(annotations)
        }
        
    }
    
    
    //MARK: textfield Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        
        let geoCode  = CLGeocoder()
        
        
        geoCode.geocodeAddressString(textField.text!, completionHandler: {(marks,error) in
            
            guard error == nil else {
                performUIUpdatesOnMain {
                    
                    self.displayAlert("error geocodeadresse", mess: error.debugDescription)
                }
                return
            }
            
            performUIUpdatesOnMain {
                
                let placemark = marks![0] as CLPlacemark
                
                let dictionary = [
                    "latitude" : Float((placemark.location?.coordinate.latitude)!),
                    "longitude" : Float((placemark.location?.coordinate.longitude)!),
                    "latitudeDelta" : self.IBMap.region.span.latitudeDelta,
                    "longitudeDelta" : self.IBMap.region.span.longitudeDelta
                ]
                
                // Archive the dictionary into the filePath
                NSKeyedArchiver.archiveRootObject(dictionary, toFile: self.filePath)
                
                self.restoreMapRegion(true)
                
            }
            
        })
        
        textField.endEditing(true)
        return true
        
    }
    
    
    func handleLongPressRecognizer(gesture:UILongPressGestureRecognizer)  {
        
        if gesture.state == UIGestureRecognizerState.Began {
            
            var annotations = IBMap.annotations as! [MKPointAnnotation]
            let point = gesture.locationInView(IBMap)
            let coordinate = IBMap.convertPoint(point, toCoordinateFromView: IBMap) as CLLocationCoordinate2D
            
            for p in pins {
                if p.latitude as! CLLocationDegrees  == coordinate.latitude  && p.longitude as! CLLocationDegrees  == coordinate.longitude {
                    return
                }
            }
            
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Album photo : \(IBtextfield.text!)"
            annotations.append(annotation)
            IBMap.addAnnotations(annotations)
            
            curCoordinate.latitude = coordinate.latitude
            curCoordinate.longitude = coordinate.longitude
            
        }
        
        if gesture.state == UIGestureRecognizerState.Changed {
            
            var annotations = IBMap.annotations as! [MKPointAnnotation]
            let point = gesture.locationInView(IBMap)
            let coordinate = IBMap.convertPoint(point, toCoordinateFromView: IBMap) as CLLocationCoordinate2D
            
            for index in 0...annotations.count-1 {
                
                let annotation = annotations[index]
                if annotation.coordinate.latitude   == curCoordinate.latitude  && annotation.coordinate.longitude  == curCoordinate.longitude {
                    annotation.coordinate = coordinate
                    IBMap.addAnnotations(annotations)
                    curCoordinate.latitude = coordinate.latitude
                    curCoordinate.longitude = coordinate.longitude
                    
                    break
                }
                
            }
            
            
        }
        
        
        if gesture.state == UIGestureRecognizerState.Ended {
            
            
            var dictionary = [String : AnyObject]()
            dictionary[Pin.Keys.Title] = "Album photo : \(IBtextfield.text!)"
            dictionary[Pin.Keys.Latitude] = NSNumber(double: curCoordinate.latitude)
            dictionary[Pin.Keys.Longitude] = NSNumber(double: curCoordinate.longitude)
            dictionary[Pin.Keys.Photos] = NSSet()
            let pinToBeAdded = Pin(dictionary: dictionary, context: self.sharedContext)
            // Append the pin to the array
            pins.append(pinToBeAdded)
            
            // Save the context.
            do {
                try sharedContext.save()
                
            } catch _ {}
            
            performUIUpdatesOnMain {
                
                
            }
        }
        
    }
    
    
    //MARK: Map function
    
    
    private func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            IBMap.setRegion(savedRegion, animated: animated)
        }
    }
    
    
    private func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : IBMap.region.center.latitude,
            "longitude" : IBMap.region.center.longitude,
            "latitudeDelta" : IBMap.region.span.latitudeDelta,
            "longitudeDelta" : IBMap.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
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
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        
        if let coord = view.annotation?.coordinate {
            
            if deleteFlag {
                
                for (index, p) in pins.enumerate() {
                    
                    
                    if p.latitude as! CLLocationDegrees  == coord.latitude  && p.longitude as! CLLocationDegrees  == coord.longitude {
                        
                        
                        sharedContext.deleteObject(p)
                        
                        // Save the context.
                        do {
                            try sharedContext.save()
                        } catch let error as NSError {
                            print(error.debugDescription)
                            
                        }
                        
                        pins.removeAtIndex(index)
                        view.removeFromSuperview()
                        break
                    }
                }
                
                
            }
            else {
                
                
                curCoordinate.latitude = coord.latitude
                curCoordinate.longitude = coord.longitude
                
                let dictionary = [
                    "latitude" : coord.latitude,
                    "longitude" : coord.longitude,
                    "latitudeDelta" : IBMap.region.span.latitudeDelta,
                    "longitudeDelta" : IBMap.region.span.longitudeDelta
                ]
                
                // Archive the dictionary into the filePath
                NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
                
                
                self.performSegueWithIdentifier("photoalbum", sender: self)
                
            }
            
            
            
        }
        
        
    }
    
    
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    
}
