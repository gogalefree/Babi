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
    
    if #available(iOS 10.0, *) {
      let center = UNUserNotificationCenter.current()
      center.delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: {_, _ in })
      
      // For iOS 10 data message (sent via FCM)
      FIRMessaging.messaging().remoteMessageDelegate = self
    }
    
    let callAction = UIMutableUserNotificationAction()
    callAction.identifier = kCallActionIdentifier
    callAction.title = "Open Gate"
    callAction.activationMode = UIUserNotificationActivationMode.foreground
    callAction.isDestructive = false
    callAction.isAuthenticationRequired = true
    
    let launchAction = UIMutableUserNotificationAction()
    launchAction.identifier = kLaunchBabiActionIdentifier
    launchAction.title = "Launch BaBi"
    launchAction.activationMode = UIUserNotificationActivationMode.foreground
    launchAction.isDestructive = false
    launchAction.isAuthenticationRequired = false
    
    let cancelAction = UIMutableUserNotificationAction()
    cancelAction.identifier = kDissmissActionIdentifier
    cancelAction.title = "Cancel"
    cancelAction.activationMode = UIUserNotificationActivationMode.background
    cancelAction.isDestructive = false
    cancelAction.isAuthenticationRequired = false
    
    
    let arrivedToGateCategory = UIMutableUserNotificationCategory()
    arrivedToGateCategory.identifier = "ARRIVED_CATEGORY"
    arrivedToGateCategory.setActions([callAction, launchAction,  cancelAction], for: UIUserNotificationActionContext.default)
    
    let categoriesSet = Set(arrayLiteral: arrivedToGateCategory)
    let types: UIUserNotificationType = [.badge, .alert, .sound]
    let settings = UIUserNotificationSettings(types: types, categories: categoriesSet)
    UIApplication.shared.registerUserNotificationSettings(settings)

    application.registerForRemoteNotifications()
  }
  
  
  func registerGateForLocationNotification(_ gate: Gate) {
    if !gate.automatic { return }
    guard let localNotification = generateLocalNotification(gate) else {return}
    if registeredGates.contains(gate) {return}
    UIApplication.shared.scheduleLocalNotification(localNotification)
    registeredGates.add(gate)
  }
  
  func cancelLocalNotification(_ gate: Gate) {
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["gate\(gate.latitude)"])
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["gate\(gate.latitude)"])
    }
    else {
      guard let notification = generateLocalNotification(gate) else {return}
      UIApplication.shared.cancelLocalNotification(notification)
      if registeredGates.contains(gate){registeredGates.remove(gate)}
    }
  }
  
  func didRecieveLocalNotification(_ notification: UILocalNotification) {
    
    let userInfo = notification.userInfo as [AnyHashable: Any]?
    if let userInfo = userInfo{
      let phoneNumber = userInfo["phoneNumber"] as? String
      PhoneDialer.callGate(phoneNumber)
    }
  }
  
  func generateLocalNotification(_ gate: Gate) -> UILocalNotification?{
    
    let region = CLCircularRegion(
      center: CLLocationCoordinate2DMake(gate.latitude, gate.longitude),
      radius: CLLocationDistance(250),
      identifier: "\(gate.longitude)\(gate.latitude)")
    region.notifyOnEntry = true
    region.notifyOnExit = false
    
    if #available(iOS 10.0, *) {
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
        trigger: trigger
      )
      
      UNUserNotificationCenter.current().add(
        request, withCompletionHandler: nil)
      return nil
      
    } else {
      // Fallback on earlier versions
      let localNotification = UILocalNotification()
      localNotification.userInfo = Gate.gateDictionary(gate)
      localNotification.alertBody = "You're getting close to \(gate.name). Luanch Babi?"
      localNotification.soundName = UILocalNotificationDefaultSoundName
      localNotification.regionTriggersOnce = false
      localNotification.category = "ARRIVED_CATEGORY"
      localNotification.region = region
      localNotification.region!.notifyOnEntry = true
      localNotification.region!.notifyOnExit = false
      return localNotification
    }
  }
}

@available(iOS 10.0, *)
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

extension LocationNotifications: FIRMessagingDelegate {
  public func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
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
