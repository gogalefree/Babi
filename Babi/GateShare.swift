//
//  GateShare.swift
//  Babi
//
//  Created by Guy Freedman on 24/03/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

let kGateNamekey        = "gateName"
let kPlacemarkNameKey   = "placeMark"
let kGateUidKey         = "gateUid"
let kOwnerUIDKey        = "ownerUid"
let kLatitudeKey        = "latitude"
let kLongitudeKey       = "longitude"
let kShareDateKey       = "shareDate"
let kShareTokenKey      = "shareToken"
let isCancelledKey      = "isCancelled"
let kOwnerShouldFireKey = "ownerShouldFire"
let kGuestUidKey        = "guestUid"
let kisPairedKey        = "isPaired"
let kPairDateKey        = "pairDate"
let kShareUidKry        = "shareUid"
let kGuestNameKey       = "guestName"
let kOwnerPushToken     = "ownerPushToken"
let kGuestPushToken     = "guestPushToken"

import UIKit
import Firebase

class GateShare: NSObject {
    
    var gateName: String!
    var placemarkName: String?
    var ownerUID: String!
    var latitude: Double!
    var longitude: Double!
    var shareDate: Double!
    var pairDate: Double?
    var shareToken: String!
    var gateUid : Int!
    var isCancelled = false
    var ownerShouldFireCall = false
    var shareId = ""
    var guestName = ""
    var ownerPushToken = kOwnerPushToken
    var guestPushToken = kGuestPushToken
    
    init(gate: Gate, ownerUid: String, guestname: String?) {
        gateName        = gate.name
        placemarkName   = gate.placemarkName
        gateUid         = gate.uid
        ownerUID        = ownerUid
        latitude        = gate.latitude
        longitude       = gate.longitude
        shareDate       = Date().timeIntervalSince1970
        shareToken      = String.generateToken()
        shareId         = IDManager.shared.shareAutoId
        guestName       = guestname ?? ""
        pairDate        = 0
        ownerPushToken  = FIRInstanceID.instanceID().token() ?? kOwnerPushToken

        super.init()
    }
    
    init?(snapshot: FIRDataSnapshot) {
        
        print(snapshot.key)
        print(snapshot.value as Any)
        
        guard let dict = snapshot.value as? [String: Any] else {
            print(#function + "cant peocess gate share data as guest")
            return nil
        }
        
        let gateName            = ((dict[kGateNamekey] as? String)?.removingPercentEncoding ?? "")
        let gateUID             = (dict[kGateUidKey] as? Int) ?? 0
        let isCancelled         = (dict[isCancelledKey] as? Bool) ?? false
      //  let isPaired            = (dict[kisPairedKey] as? Bool) ?? false
        let latitude            = (dict[kLatitudeKey] as? Double) ?? 0.0
        let longitude           = (dict[kLongitudeKey] as? Double) ?? 0.0
        let ownerShouldFire     = (dict[kOwnerShouldFireKey] as? Bool) ?? false
        let ownerUid            = (dict[kOwnerUIDKey] as? String) ?? ""
        let pairDateInterval    = (dict[kPairDateKey] as? Double) ?? 0.0
        let placeMark           = (dict[kPlacemarkNameKey] as? String) ?? ""
        let shareDate           = (dict[kShareDateKey] as? Double) ?? 0.0
        let shareToken          = (dict[kShareTokenKey] as? String) ?? ""
        let shareUid            = (dict[kShareUidKry] as? String) ?? ""
        let guestName           = (dict[kGuestNameKey] as? String) ?? ""
        let aOwnerPushToken      = (dict[kOwnerPushToken] as? String) ?? kOwnerPushToken
        let aGuestPushToken      = (dict[kGuestPushToken] as? String) ?? kGuestPushToken
        
        self.gateName = gateName.removingPercentEncoding
        self.gateUid = gateUID
        self.isCancelled = isCancelled
        self.latitude = latitude
        self.longitude = longitude
        self.ownerShouldFireCall = ownerShouldFire
        self.ownerUID = ownerUid
        self.pairDate = pairDateInterval
        self.placemarkName = placeMark
        self.shareDate = shareDate
        self.shareToken = shareToken
        self.shareId = shareUid
        self.guestName = guestName
        self.ownerPushToken = aOwnerPushToken
        self.guestPushToken = aGuestPushToken
        super.init()
    }
    
    func toSnapshot() -> [String : Any] {
        
        let snapshot = [
            kGateNamekey        : gateName!,
            kPlacemarkNameKey   : placemarkName ?? "",
            kGateUidKey         : gateUid!,
            kOwnerUIDKey        : ownerUID!,
            kLatitudeKey        : latitude!,
            kLongitudeKey       : longitude!,
            kShareDateKey       : shareDate!,
            kShareTokenKey      : shareToken!,
            isCancelledKey      : isCancelled,
            kOwnerShouldFireKey : ownerShouldFireCall,
            kGuestUidKey        : "",
            kisPairedKey        : pairDate == 0 ? false : true,
            kPairDateKey        : pairDate ?? 0.0,
            kGuestNameKey       : guestName,
            kShareUidKry        : shareId,
            kOwnerPushToken     : ownerPushToken,
            kGuestPushToken     : guestPushToken 
            
        ] as [String : Any]
        
        return snapshot
    }
    

    func invitationMessage() -> String {
        
        let partA = String.localizedStringWithFormat("Hey,\nI invite you as a guest to this gate.\n")
        let partB = String.localizedStringWithFormat("If you don't have BaBi Gate app, first install it from the app store:\n")
        let partC = String.localizedStringWithFormat("link to app store\n")
        let partD = String.localizedStringWithFormat("To accept please click the link:\n")
        let partE = "babi://?od=\(ownerUID!)&token=\(shareToken!)&shareId=\(shareId)"
        return partA + partB + partC + partD + partE
    }
}
