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



class TravelLocationsMap: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var IBMap: MKMapView!
    @IBOutlet weak var IBtextfield: UITextField!
    
    
    var pins = [Pin]()
    
    
    var sharedContext: NSManagedObjectContext {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.managedObjectContext
    }
    
    
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        IBMap.delegate = self
        IBtextfield.delegate = self
        
        pins = fetchAllPins()
        
        restoreMapRegion(false)
        let longPressGestureRecognizer = UILongPressGestureRecognizer.init(target: self, action:#selector(TravelLocationsMap.handleLongPressRecognizer(_:)))
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
        
        for pin in pins {
            
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude as! CLLocationDegrees, longitude: pin.longitude as! CLLocationDegrees)
            var annotations = IBMap.annotations as! [MKPointAnnotation]
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = pin.title
            annotations.append(annotation)
            IBMap.addAnnotations(annotations)
            
        }
    }
    
    
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func handleLongPressRecognizer(gesture:UILongPressGestureRecognizer)  {
        
        if gesture.state != UIGestureRecognizerState.Ended {
            return
        }
        
        
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
        
        var dictionary = [String : AnyObject]()
        dictionary[Pin.Keys.Title] = annotation.title
        dictionary[Pin.Keys.Latitude] = annotation.coordinate.latitude
        dictionary[Pin.Keys.Longitude] = annotation.coordinate.longitude
        dictionary[Pin.Keys.Photos] = NSSet()
        
        
        performUIUpdatesOnMain {
            
            let pinToBeAdded = Pin(dictionary: dictionary, context: self.sharedContext)        
            //pinToBeAdded.photos = NSSet()
            // Append the pin to the array
            
            self.pins.append(pinToBeAdded)
            
            // Save the context.
            do {
                try self.sharedContext.save()
            } catch _ {}
            
        }
        
    }
    
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
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
        if segue.identifier == "photoalbum"  {
            
            let controller = segue.destinationViewController as! PhotoAlbum            
            for p in pins {
                if p.latitude as! CLLocationDegrees  == curCoordinate.latitude  && p.longitude as! CLLocationDegrees  == curCoordinate.longitude {
                    controller.pin = p
                    break
                }
            }
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
    
    
    
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        
        if let coord = view.annotation?.coordinate {
            
            
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
    
    
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    
}
