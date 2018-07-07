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
import UserNotifications
import Firebase

class LocationNotifications: NSObject {
    
    static let shared = LocationNotifications()
    var registeredGates  = NSMutableSet()
    
    func registerUserNotifications(application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        //data message (sent via FCM)
        Messaging.messaging().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (granted, error) in
            if (error != nil) {
                let callAction = UNNotificationAction(identifier: kCallActionIdentifier, title: "Open Gate", options: [.foreground, .authenticationRequired]) //unnotification Action
                let launchAction = UNNotificationAction(identifier: kLaunchBabiActionIdentifier, title: "Launch BaBi", options: [.foreground])
                let cancelAction = UNNotificationAction(identifier: kDissmissActionIdentifier, title: "Cancel", options: [])
                let arrivedToGateCategory = UNNotificationCategory(identifier: "ARRIVED_CATEGORY", actions: [callAction, launchAction,  cancelAction], intentIdentifiers: [], options: []) //UNNotificationCategory
                UNUserNotificationCenter.current().setNotificationCategories([arrivedToGateCategory])
                application.registerForRemoteNotifications()
            }
        }
    }
    
    func registerGateForLocationNotification(_ gate: Gate) {
        if !gate.automatic { return }
        generateLocalNotification(gate)
        if registeredGates.contains(gate) {return}
        registeredGates.add(gate)
    }
    
    func cancelLocalNotification(_ gate: Gate) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["gate\(gate.latitude)"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["gate\(gate.latitude)"])
    }
    
    func didRecieveLocalNotification(_ request: UNNotificationRequest) { //unnotification request
        
        let userInfo = request.content.userInfo as [AnyHashable: Any]?
        if let userInfo = userInfo{
            let phoneNumber = userInfo["phoneNumber"] as? String
            PhoneDialer.callGate(phoneNumber)
        }
    }
    
    func generateLocalNotification(_ gate: Gate) {
        
        let region = CLCircularRegion(
            center: CLLocationCoordinate2DMake(gate.latitude, gate.longitude),
            radius: CLLocationDistance(250),
            identifier: "\(gate.longitude)\(gate.latitude)")
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        
        let content = UNMutableNotificationContent()
        content.title = "You're getting close to \(gate.name)."
        content.body = "Launch BaBi?"
        content.badge = (UIApplication.shared.applicationIconBadgeNumber + 1) as NSNumber
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "ARRIVED_CATEGORY"
        content.userInfo = [kPhoneNumberKey : gate.phoneNumber]
        let trigger = UNLocationNotificationTrigger(region: region, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "gate\(gate.latitude)",
            content: content,
            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

extension LocationNotifications: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Swift.Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let id = response.actionIdentifier
        if id == kCallActionIdentifier {
            let phoneNumber = userInfo[kPhoneNumberKey] as? String
            if let pn = phoneNumber{
                PhoneDialer.callGate(pn)
            }
        }
    }
}

extension LocationNotifications: MessagingDelegate {
    public func applicationReceivedRemoteMessage(_ remoteMessage: MessagingRemoteMessage) {
        print("application recieve remote: " + String(describing:remoteMessage))
    }
}
//MARK: Debug Helpers
extension LocationNotifications {
    
    func sendPush() {
        let pushToken = "dKV2Ob5JzNY:APA91bGp9q5eTehW-YqVYyzQu6YdHZnjEBZ8-D5RIXcfscaDQGh--1dh2kgpASUeBTHgKt28Zt2PJmeFhQzPNNjkiLhSTVduoH_kReGGCBRcsNPzoeu0QiOkmRyawbz-IVIcdsEQOePa"
        let badge = UIApplication.shared.applicationIconBadgeNumber + 1
        var request = URLRequest(url: URL(string: "https://fcm.googleapis.com/fcm/send")!)
        request.httpMethod = "POST"
        let payload: [String: Any] = [
            "notification": [
                "title": "First iOS inapp Push",
                "body": "messageBody",
                "badge" : badge,
                "click_action": "Launch",
                "sound" : "default"
            ],
            "to" : pushToken
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        request.setValue("key=AAAAF0fIu3w:APA91bHI7Jue-5BpTzYZ-90FF-nE5NZTsCP0IXvm6E52T_fqWgDM7dDe6mnTl1aAqq38fUWoBlr_lUJLHIU_pG__TcXxEbEx66xjfqYhv3AyQt2OU0HVw1TURLluhMb9gOhOWJCtqmJB", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
}
