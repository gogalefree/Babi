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
import Firebase

let kCallActionIdentifier = "CALL_IDENTIFIER"
let kDissmissActionIdentifier = "DISSMISS_IDENTIFIER"
let kLaunchBabiActionIdentifier = "LAUNCH_Babi_IDENTIFIER"

let kLocationUpdateNotification = "kLocationUpdateNotification"
let knewGateAsGuestNotification = "knewGateAsGuestNotification"

class Model: NSObject, CLLocationManagerDelegate {

    static let shared = Model()
    
    let kDistanceFilter = 3.0
    let context = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
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
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case  .authorizedWhenInUse :
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        if let location = locations.last {
            userLocation = location
            NotificationCenter.default.post(name: Notification.Name(rawValue: kLocationUpdateNotification), object: nil)
            isInRegion()
        }
    }
    
    fileprivate func isInRegion() {
      
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
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Gate")
        request.returnsObjectsAsFaults = false

        var error: NSError? = nil
        let results: [AnyObject]?
        do {
            results = try context?.fetch(request)
        } catch let error1 as NSError {
            error = error1
            results = nil
        }
        
        if error != nil  || results?.count == 0 {
            print("error fetching or no results")
            return nil
        }
        print("model fetched with count \(String(describing: results?.count))")
       
        if let results = results {
            return sortGatesByDistanceFromUser(results as! [Gate])
        }
        
        return results as? [Gate]
    }
    
    func deleteGate(_ gate: Gate) {
        self.locationNotifications.cancelLocalNotification(gate)
        context?.delete(gate)
        do {
            try context?.save()
        } catch _ {
        }
    }
    
    func sortGatesByDistanceFromUser(_ gates: [Gate]) -> [Gate] {
        
        var sortedGates = gates
        
        sortedGates.sort(by: { $0.distanceFromUserLocation() < $1.distanceFromUserLocation() })
        
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
    
    func isInRegion(_ location: CLLocation) -> Bool {
        return userRegion.contains(location.coordinate)
    }
}

