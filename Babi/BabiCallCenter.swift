//
//  BabiCallCenter.swift
//  Babi
//
//  Created by Guy Freedman on 4/15/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import CoreTelephony

class BabiCallCenter: NSObject {
    
    
    let callCenter = CTCallCenter()
    
    override init () {
        super.init()
        setUp()
    }
    
    func setUp() {
        
        callCenter.callEventHandler = { [weak self] (call:CTCall!) in
            
            print("call state before handler: \(call.callState)")
            
            switch call.callState {
            case CTCallStateConnected:
                self!.callConnected()
            case CTCallStateDisconnected:
                self!.callDisconnected()
            default:
                //Not concerned with CTCallStateDialing or CTCallStateIncoming
                break
            }
        }
    }
    
    func callConnected() {
        print("CTCallStateConnected")
    }
    
    func callDisconnected() {
        print("CTCallStateDisconnected")
        let url = URL(string: "babi://")
        UIApplication.shared.openURL(url!)
    }
   
}
