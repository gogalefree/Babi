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
        
        if gate.automatic {
            
            if registeredGates.containsObject(gate) {return}
            
            let localNotification = generateLocalNotification(gate)
            
            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            
            registeredGates.addObject(gate)
        }
    }
    
    func didRecieveLocalNotification(notification: UILocalNotification) {
      
        let userInfo = notification.userInfo as [NSObject: AnyObject]?
        
        if let userInfo = userInfo{
        
            let phoneNumber = userInfo["phoneNumber"] as String
            var url:NSURL = NSURL(string: "tel://\(phoneNumber)")!
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    func generateLocalNotification(gate: Gate) -> UILocalNotification{
        
        let localNotification = UILocalNotification()
        localNotification.userInfo = gate.gateDictionary(gate)
        localNotification.alertBody = gate.name
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.regionTriggersOnce = false
        localNotification.region = CLCircularRegion(
            center: CLLocationCoordinate2DMake(gate.latitude, gate.longitude),
            radius: CLLocationDistance(gate.fireDistanceFromGate),
            identifier: "\(gate.name)\(gate.phoneNumber)")
        localNotification.region.notifyOnEntry = true
        localNotification.region.notifyOnExit = false
        return localNotification
    }
}
