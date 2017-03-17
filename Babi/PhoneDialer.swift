//
//  PhoneDialer.swift
//  Babi
//
//  Created by Guy Freedman on 4/9/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

class PhoneDialer: NSObject {
    
    class func callGate(_ phoneNumber: String?) {
     
        if let phoneNumber = phoneNumber {
            
            if phoneNumber != "phoneNumber" { //the default value
            
                let url:URL = URL(string: "tel://\(phoneNumber)")!
                UIApplication.shared.openURL(url)
            }
        }
    }   
}
