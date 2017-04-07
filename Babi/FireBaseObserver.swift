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
  /*
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
 */
}

/*
 func prepareActionSheet(_ messageToSend: String, _ phoneNumber: String) -> UIAlertController{
 
 let urlString = messageToSend
 let urlStringEncoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
 let whatsAppurl  = NSURL(string: "whatsapp://send?text=\(urlStringEncoded!)")!
 
 
 let actionSheet = UIAlertController(title: "Share With: ", message: "send a link to your guest", preferredStyle: .actionSheet)
 
 if UIApplication.shared.canOpenURL(URL(string: "whatsapp://")!) {
 
 let whatssappButton = UIAlertAction(title: "WhatsApp", style: .default, handler: { (action) -> Void in
 UIApplication.shared.openURL(whatsAppurl as URL)
 })
 
 actionSheet.addAction(whatssappButton)
 }
 
 if (MFMessageComposeViewController.canSendText()) {
 
 let  messagesButton = UIAlertAction(title: "Messages", style: .default, handler: { (action) -> Void in
 
 let controller = MFMessageComposeViewController()
 controller.body = messageToSend
 controller.recipients = [phoneNumber]
 controller.messageComposeDelegate = self
 self.present(controller, animated: true, completion: nil)
 })
 
 actionSheet.addAction(messagesButton)
 }
 
 let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
 print("Cancel button tapped")
 })
 
 actionSheet.addAction(cancelButton)
 
 return actionSheet
 }
 
 */
