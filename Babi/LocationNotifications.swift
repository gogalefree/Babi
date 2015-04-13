//
//  LocationNotifications.swift
//  Babi
//
//  Created by Guy Freedman on 4/7/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation

class LocationNotifications: NSObject {
   
    var registeredGates  = NSMutableSet()
    
    func registerGateForLocationNotification(gate: Gate) {
        
        let localNotification = generateLocalNotification(gate)

        if gate.automatic {
            
            if registeredGates.containsObject(gate) {return}
            
            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            registeredGates.addObject(gate)
        }
    }
    
    func cancelLocalNotification(gate: Gate) {
        let notification = generateLocalNotification(gate)
        UIApplication.sharedApplication().cancelLocalNotification(notification)
        if registeredGates.containsObject(gate){registeredGates.removeObject(gate)}
    }
    
    func didRecieveLocalNotification(notification: UILocalNotification) {
      
        let userInfo = notification.userInfo as [NSObject: AnyObject]?
        
        if let userInfo = userInfo{
        
            let phoneNumber = userInfo["phoneNumber"] as! String
            let phoneDialer = PhoneDialer()
            phoneDialer.callGate(phoneNumber)
            
        }
    }
    
    func generateLocalNotification(gate: Gate) -> UILocalNotification{
        
        let localNotification = UILocalNotification()
        localNotification.userInfo = Gate.gateDictionary(gate)
        localNotification.alertBody = gate.name
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.regionTriggersOnce = false
        localNotification.category = "ARRIVED_CATEGORY"
        localNotification.region = CLCircularRegion(
            center: CLLocationCoordinate2DMake(gate.latitude, gate.longitude),
            radius: CLLocationDistance(gate.fireDistanceFromGate),
            identifier: "\(gate.name)\(gate.latitude)")
        localNotification.region.notifyOnEntry = true
        localNotification.region.notifyOnExit = false
        return localNotification
    }
}
