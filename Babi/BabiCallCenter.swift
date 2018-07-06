//
//  BabiCallCenter.swift
//  Babi
//
//  Created by Guy Freedman on 4/15/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import CoreTelephony
import Material
import CallKit



class BabiCallCenter: NSObject {
    
 //   var callController: AnyObject?
 //   var callProvider: AnyObject?
 //   var callObserver: AnyObject?
    @objc let callCenter = CXCallObserver()//CTCallCenter()
    
    override init () {
        super.init()
        setUp()
    }
    
    @objc func setUp() {
    
            callCenter.setDelegate(self, queue: nil)
                /*
                = { [weak self] (call:CTCall!) in //CXCallObserver
                
                print("call state before handler: \(call.callState)") //CXCall
                
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

        */
    }
    
    @objc func callConnected() {
        print("CTCallStateConnected")
    }
    
    @objc func callDisconnected() {
        print("CTCallStateDisconnected")
        let url = URL(string: "babi://")
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
}
extension BabiCallCenter: CXCallObserverDelegate{
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        
        if call.hasConnected {
            self.callConnected()
            
        } else if call.hasEnded {
            self.callDisconnected()
        }
    }
}
