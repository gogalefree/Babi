//
//  IDManager.swift
//  Babi
//
//  Created by Guy Freedman on 25/03/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import UIKit

class IDManager: NSObject {

    static let shared = IDManager()
  
    private let kgateIdKey = "gateIdkey"
    private let defaults = UserDefaults.standard
    
    private let kShareidKey = "shareIdkey"
    
    
    var gataAutoId: Int {
        
        var id = defaults.integer(forKey: kgateIdKey)
        id += 1
        defaults.set(id, forKey: kgateIdKey)
        print("gateId: \(id)")

        return id
    }
    
    var shareAutoId: String {
        
        var id = defaults.integer(forKey: kShareidKey)
        id += 1
        defaults.set(id, forKey: kShareidKey)
        print("shareid: \(id)")
        return String("share\(id)")
    }
    
}
