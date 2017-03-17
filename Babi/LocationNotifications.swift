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
    
    func registerGateForLocationNotification(_ gate: Gate) {
        
        let localNotification = generateLocalNotification(gate)

        if gate.automatic {
            
            if registeredGates.contains(gate) {return}
            
            UIApplication.shared.scheduleLocalNotification(localNotification)
            registeredGates.add(gate)
        }
    }
    
    func cancelLocalNotification(_ gate: Gate) {
        let notification = generateLocalNotification(gate)
        UIApplication.shared.cancelLocalNotification(notification)
        if registeredGates.contains(gate){registeredGates.remove(gate)}
    }
    
    func didRecieveLocalNotification(_ notification: UILocalNotification) {
      
        let userInfo = notification.userInfo as [AnyHashable: Any]?
        
        if let userInfo = userInfo{
        
            let phoneNumber = userInfo["phoneNumber"] as? String
            PhoneDialer.callGate(phoneNumber)
            
        }
    }
    
    func generateLocalNotification(_ gate: Gate) -> UILocalNotification{
        
        let localNotification = UILocalNotification()
        localNotification.userInfo = Gate.gateDictionary(gate)
        localNotification.alertBody = "You're getting close to \(gate.name). Luanch Babi?"
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.regionTriggersOnce = false
        localNotification.category = "ARRIVED_CATEGORY"
        localNotification.region = CLCircularRegion(
            center: CLLocationCoordinate2DMake(gate.latitude, gate.longitude),
            radius: CLLocationDistance(500),
            identifier: "\(gate.longitude)\(gate.latitude)")
        localNotification.region!.notifyOnEntry = true
        localNotification.region!.notifyOnExit = false
        return localNotification
    }
}
