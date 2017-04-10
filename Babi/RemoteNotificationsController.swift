//
//  RemoteNotificationsController.swift
//  Babi
//
//  Created by Guy Freedman on 24/07/2016.
//  Copyright © 2016 Guy Freeman. All rights reserved.
//

import Foundation

let kRemoteNotificationTokenKey = "remote_notification_key"

class RemoteNotificationsController: NSObject {
    
    static let sharedInstance = RemoteNotificationsController()
    fileprivate override init () {}
    
    var remoteNotificationToken: String? {
        let token = UserDefaults.standard.string(forKey: kRemoteNotificationTokenKey)
        print(String(describing: token))
        return token
    }
    
    func savePushNotificationsTokenInUD(_ newToken:String) {
        
        UserDefaults.standard.set(newToken, forKey: kRemoteNotificationTokenKey)
    }

    
    
}
