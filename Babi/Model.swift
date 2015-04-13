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
        
        let categoriesSet = NSSet(object: arrivedToGateCategory)
        let types = UIUserNotificationType.Badge | UIUserNotificationType.Alert | UIUserNotificationType.Sound;
        let settings = UIUserNotificationSettings(forTypes: types, categories: categoriesSet as Set<NSObject>);
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
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
        userLocation = locations.last as! CLLocation
        NSNotificationCenter.defaultCenter().postNotificationName(kLocationUpdateNotification, object: nil)
        isInRegion()
        
    }
    
    private func isInRegion() {
        let gates = self.gates()!
        for gate in gates{
            let gateCoords = CLLocationCoordinate2DMake(gate.latitude, gate.longitude)
            let region = CLCircularRegion(center: gateCoords, radius: gate.distanceFromUserLocation, identifier: "\(gate.name)")
            if region.containsCoordinate(self.userLocation.coordinate){
                println("\(gate.name) is in your region********")
            }
        }
    }

    func gates() -> [Gate]? {
        
        let request = NSFetchRequest(entityName: "Gate")
        request.returnsObjectsAsFaults = false

        var error: NSError? = nil
        let results = context?.executeFetchRequest(request, error: &error)
        
        if error != nil  || results?.count == 0 {
            println("error fetching or no results")
            return nil
        }
        println("model fetched with count \(results?.count)")
        return results as? [Gate]
    }
    
    func deleteGate(gate: Gate) {
        self.locationNotifications.cancelLocalNotification(gate)
        context?.deleteObject(gate)
        context?.save(nil)
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
