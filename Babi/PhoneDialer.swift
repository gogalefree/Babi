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
        
     
            if let pn = phoneNumber {
                
                if pn != "phoneNumber" { //the default value
                
                    let url:URL = URL(string: "tel://\(pn)")!
                    if UIApplication.shared.canOpenURL(url) {
                    
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            // Fallback on earlier versions
                            UIApplication.shared.openURL(url)
                        }

                    }
                }
            }
    }
}
