//
//  PhoneDialer.swift
//  Babi
//
//  Created by Guy Freedman on 4/9/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

class PhoneDialer: NSObject {
    
    class func callGate(phoneNumber: String?) {
     
        if let phoneNumber = phoneNumber {
            
            if phoneNumber != "phoneNumber" { //the default value
            
                let url:NSURL = NSURL(string: "tel://\(phoneNumber)")!
                UIApplication.sharedApplication().openURL(url)
            }
        }
    }   
}
