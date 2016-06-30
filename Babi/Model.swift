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

let kCallActionIdentifier = "CALL_IDENTIFIER"
let kDissmissActionIdentifier = "DISSMISS_IDENTIFIER"
let kLocationUpdateNotification = "kLocationUpdateNotification"

class Model: NSObject, CLLocationManagerDelegate {

    let kDistanceFilter = 3.0
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let locationManager = CLLocationManager()
    var userLocation = CLLocation()
    lazy var locationNotifications: LocationNotifications = {
        return LocationNotifications()
    }()
    
    let callCenter = BabiCallCenter()
    let usageUpdater = BabiUsageUpdater()
    var userRegion = CLCircularRegion()
    
    var gateInRegion: Gate?
    
    func setUp() {
    
        if CLLocationManager.locationServicesEnabled() {
            self.setupLocationManager()
        }
        
        
        let callAction = UIMutableUserNotificationAction()
        callAction.identifier = kCallActionIdentifier
        callAction.title = "Open Gate"
        callAction.activationMode = UIUserNotificationActivationMode.Foreground
        callAction.destructive = false
        callAction.authenticationRequired = true
        
        let cancelAction = UIMutableUserNotificationAction()
        cancelAction.identifier = kDissmissActionIdentifier
        cancelAction.title = "Cancel"
        cancelAction.activationMode = UIUserNotificationActivationMode.Background
        cancelAction.destructive = false
        cancelAction.authenticationRequired = false
        
        
        let arrivedToGateCategory = UIMutableUserNotificationCategory()
        
        // Identifier to include in your push payload and local notification
        arrivedToGateCategory.identifier = "ARRIVED_CATEGORY"
        arrivedToGateCategory.setActions([callAction, cancelAction], forContext: UIUserNotificationActionContext.Default)
        
        let categoriesSet = Set(arrayLiteral: arrivedToGateCategory)
        let types: UIUserNotificationType = [UIUserNotificationType.Badge, UIUserNotificationType.Alert, UIUserNotificationType.Sound]
        let settings = UIUserNotificationSettings(forTypes: types, categories: categoriesSet)
      
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
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
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        if let location = locations.last {
            userLocation = location
            NSNotificationCenter.defaultCenter().postNotificationName(kLocationUpdateNotification, object: nil)
            isInRegion()
        }
    }
    
    private func isInRegion() {
      
        let gates = self.gates()
        
        if let gates = gates {
            
            for gate in gates{
                
                print("gate distance from user: \(gate.distanceFromUserLocation())")
                print("gate fire Distance: \(gate.fireDistanceFromGate)")
                
                
                if gate.distanceFromUserLocation() < Double(gate.fireDistanceFromGate) {
            
                    gate.userInRegion = true
                }
                else {
                    
                    gate.userInRegion = false
                }
            }
        }
    }
    
    func gates() -> [Gate]? {
        
        let request = NSFetchRequest(entityName: "Gate")
        request.returnsObjectsAsFaults = false

        var error: NSError? = nil
        let results: [AnyObject]?
        do {
            results = try context?.executeFetchRequest(request)
        } catch let error1 as NSError {
            error = error1
            results = nil
        }
        
        if error != nil  || results?.count == 0 {
            print("error fetching or no results")
            return nil
        }
        print("model fetched with count \(results?.count)")
       
        if let results = results {
            return sortGatesByDistanceFromUser(results as! [Gate])
        }
        
        return results as? [Gate]
    }
    
    func deleteGate(gate: Gate) {
        self.locationNotifications.cancelLocalNotification(gate)
        context?.deleteObject(gate)
        do {
            try context?.save()
        } catch _ {
        }
    }
    
    func sortGatesByDistanceFromUser(gates: [Gate]) -> [Gate] {
        
        var sortedGates = gates
        
        sortedGates.sortInPlace({ $0.distanceFromUserLocation() < $1.distanceFromUserLocation() })
        
        return sortedGates
    }
    
    func startLocationUpdates() {
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func stopLocationUpdates() {
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    func setUserRegion() {
        userRegion = CLCircularRegion(center: self.userLocation.coordinate, radius: 50, identifier: "userRegionForLocationUpdates")
    }
    
    func isInRegion(location: CLLocation) -> Bool {
        return userRegion.containsCoordinate(location.coordinate)
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
