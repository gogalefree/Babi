//
//  FireBaseObserver.swift
//  Babi
//
//  Created by Guy Freedman on 26/03/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import UIKit
import Firebase

class FireBaseObserver: NSObject {

    static let shared = FireBaseObserver()
    
    func observeValueChangedAsOwner(_ gateShare: GateShare) {
    
        let ownerId = gateShare.ownerUID ?? ""
        let shareId = gateShare.shareId
        let dbRef = FIRDatabase.database().reference(withPath: "users")

        dbRef.child(ownerId).child(shareId).observe(.childChanged, with: { (snap) in
            
            print("shareId: " + gateShare.shareId)
            print(snap)
            print("snap: \(String(describing: snap.value ))")
            guard let dict = snap.value as? [String : Any] else {return}
            let paired = dict[kisPairedKey] as? Bool ?? false
            let isCancelled = dict[isCancelledKey] as? Bool ?? true
            let token = dict[kShareTokenKey] as? String ?? ""
            let ownerShouldFire = (dict[kOwnerShouldFireKey] as? Bool) ?? false
            
            if paired && !isCancelled && token == gateShare.shareToken && ownerShouldFire {
                
                //open the gate for a guest
                print("opening gate")
            }
        })
    }
}
