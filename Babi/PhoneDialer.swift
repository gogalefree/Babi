//
//  PhoneDialer.swift
//  Babi
//
//  Created by Guy Freedman on 4/9/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import CallKit

class PhoneDialer: NSObject {
    
    class func callGate(_ phoneNumber: String?) {
        
      if #available(iOS 10.0, *) {
        self.startCall(number: phoneNumber)
      } else {
        // Fallback on earlier versions
      }
//            if let pn = phoneNumber {
//
//                if pn != "phoneNumber" { //the default value
//
//                    let url:URL = URL(string: "tel://\(pn)")!
//                    if UIApplication.shared.canOpenURL(url) {
//
//                        if #available(iOS 10.0, *) {
//                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                        } else {
//                            // Fallback on earlier versions
//                            UIApplication.shared.openURL(url)
//                        }
//
//                    }
//                }
//            }
    }
  
  @available(iOS 10.0, *)
  class func startCall(number: String?) {
    // 1
    guard let pn = number else {
      print("phone number not valid " + #function)
      return
    }
    
    print("calling" + #function)
//    _ = AppDelegate.shared.providerDelegate
    
    let handle = CXHandle(type: .phoneNumber, value: pn)
    // 2
    let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
    // 3
    startCallAction.isVideo = false
    let transaction = CXTransaction(action: startCallAction)
    
    requestTransaction(transaction)
  }
  
  @available(iOS 10.0, *)
  private class func requestTransaction(_ transaction: CXTransaction) {
    
    let callController = CXCallController()
    callController.request(transaction) { error in
      if let error = error {
        print("Error requesting transaction: \(error.localizedDescription)")
      } else {
        print("Requested transaction successfully")
      }
    }
  }
}
