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
    
    @objc let callCenter = CXCallObserver()
    
    override init () {
        super.init()
        setUp()
    }
    
    @objc func setUp() {
        callCenter.setDelegate(self, queue: nil)
    }
    
    @objc func callConnected() {
        print("CTCallStateConnected")
    }
    
    @objc func callDisconnected() {
        print("CTCallStateDisconnected")
        let url = URL(string: "babi://")
        UIApplication.shared.open(url!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
    }
}
extension BabiCallCenter: CXCallObserverDelegate{
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        
        if call.hasConnected {
            self.callConnected()
            print("call connected")
        }
        if !call.hasConnected {
            print("call has not connected")
            self.callDisconnected()
        }
        if call.hasEnded {
            self.callDisconnected()
            print("call has ended")
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
