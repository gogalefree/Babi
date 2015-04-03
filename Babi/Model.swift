//
//  Model.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import CoreLocation

class Model: NSObject, CLLocationManagerDelegate {

    let kDistanceFilter = 5.0
    let context = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    
    func setUp() {
    
        if CLLocationManager.locationServicesEnabled() {
            self.setupLocationManager()
        }
        
//        let gate1 = NSEntityDescription.insertNewObjectForEntityForName("Gate", inManagedObjectContext: context!) as Gate
//        
//        var error: NSError?
//        let request = NSFetchRequest(entityName: "Gate")
//        let results = context!.executeFetchRequest(request, error: &error)
//        
//        if results == nil || error != nil{
//            println("error fetching: \(error)")
//        }
//        else if results?.count > 0 {
//            let gate = results?.last as Gate
//            println("curent gate is: \(gate.name) count is \(results?.count) ")
//        }
//        else {
//            println("results count is 0")
//        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        switch status {
        case  .AuthorizedWhenInUse :
            setupLocationManager()
        default:
            break
        }
    }
    
    func setupLocationManager() {
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kDistanceFilter
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!){
        userLocation = locations.first as CLLocation
    }
    

    func gates() -> [Gate]? {
        
        let request = NSFetchRequest(entityName: "Gate")
        request.returnsObjectsAsFaults = false

        var error: NSError? = NSError()
        let results = context?.executeFetchRequest(request, error: &error)
        
        if error != nil  || results?.count == 0 {
            println("error fetching or no results")
            return nil
        }
        
        return results as? [Gate]
    }
}

extension Model {
    
    //SingleTone Shared Instance
     class var shared : Model {
        
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance : Model? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = Model()
        }
        
        return Static.instance!
    }
}
