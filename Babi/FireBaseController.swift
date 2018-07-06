//
//  FireBaseController.swift
//  Babi
//
//  Created by Guy Freedman on 23/03/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import UIKit
import Firebase

class FireBaseController: NSObject {
    
    static let shared = FireBaseController()
    var currentUserPath: DatabaseReference!
    var userUid: String?
    
    public func setup() {
        FirebaseApp.configure()
    }
    
    func signIn() {
        
        if Auth.auth().currentUser == nil {
            
            Auth.auth().signInAnonymously(completion: { (authResult, error) in
                
                if error != nil {
                    print("error logging in: \(error!.localizedDescription)")
                    return
                }
                
                
                let uid  = authResult?.user.uid
                let some = authResult?.user.displayName
                self.setUserRef()
                print("authenticated!\nuser uid: \(String(describing: uid))\n\nuser display name: \(String(describing: some))")
                
            })
        } else {
            self.setUserRef()
            print("you're already authenticated")
        }
    }
    
    func setUserRef() {
        let dbRef = Database.database().reference()
        let currentUserUID = Auth.auth().currentUser!.uid
        print("user id: " + currentUserUID)
        userUid = currentUserUID
        currentUserPath = dbRef.child("users").child(currentUserUID)
    }

        
    //MARK: Post Gate Share
    
    func postGateShare(_ gateShare: GateShare) {
        
        let gateShare = gateShare
        let snap = gateShare.toSnapshot()
        currentUserPath.child(gateShare.shareId).setValue(snap)
        
        //set observation for the gate share value change
        //FireBaseObserver.shared.observeValueChangedAsOwner(gateShare)
    }
        
    func  fetchGateShareasGuest(_ ownerId: String, _ shareToken: String, _ shareId: String) {
        
        let dbRef = Database.database().reference(withPath: "users")
        dbRef.child(ownerId).child(shareId).observeSingleEvent(of: .value, with: { (snap) in
     
            guard let gateShare = GateShare(snapshot: snap) else {return}
            if Gate.gateExiststAsGuest(gateShare) !=  nil {return}
            
            guard let _ = Gate.gateAsGuest(gateShare) else {return}
            if gateShare.pairDate == 0 {

               
                InstanceID.instanceID().instanceID(handler: { (result, error) in
                
                    if (error != nil) {
                        print("error in \(#function)/n error: \(error.debugDescription)")
                    }
                    
                    gateShare.pairDate = Date().timeIntervalSince1970
                    var snap = gateShare.toSnapshot()
                    snap[kGuestUidKey] = Auth.auth().currentUser!.uid
                    snap[kGuestPushToken] = result?.instanceID ?? kGuestPushToken
                    dbRef.child(ownerId).child(shareId).setValue(snap)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: knewGateAsGuestNotification), object: nil)
                })
            }
        })
    }
    
    func removeObserverAsGuest(_ gateToDelete: Gate) {
        
        let dbRef = Database.database().reference()
        if gateToDelete.isGuest == false || gateToDelete.shareId == "shareId" || gateToDelete.ownerUid == "ownerUid" {return}
        let path = dbRef.child("users").child(gateToDelete.ownerUid!).child(gateToDelete.shareId!)
            path.removeAllObservers()
    }
}
