//
//  Gate.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//
import CoreData
import UIKit
import CoreLocation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


let kGateNameDefaultValue = "Gate"
let kGatePhoneNumberDefaultValue = "phoneNumber"
let kGateLatitudeDefaultValue = 0.0
let kGateLongitudeDefaultValue = 0.0
let kGateModeDefaultValue = true
let kGateDistanceToCallDefaultValue = 50
let kGatePlacemarkNameDefaultValue = "placemarkName"

class Gate: NSManagedObject {
    

    @NSManaged var uid: Int
    @NSManaged var name: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var automatic: Bool
    @NSManaged var phoneNumber: String
    @NSManaged var fireDistanceFromGate: Int
    @NSManaged var placemarkName: String
    @NSManaged var isGuest: Bool
    @NSManaged var ownerUid: String?    //set onlt for gate as guest. default is property name
    @NSManaged var shareId: String?     //set onlt for gate as guest. default is property name
    @NSManaged var shareToken: String?  //set onlt for gate as guest. default is property name

    
    var shares: [GateShare] = []
    var shouldCall = false
    var userInRegion = false {
        didSet {
            if  userInRegion == true {
                
                callGateIfNeeded()
            }
            else {
                shouldCall = true
            }
        }
    }
    
    func distanceFromUserLocation() -> Double {
        
        let gateCords = CLLocation(latitude: latitude, longitude: longitude)
        let distance = gateCords.distance(from: Model.shared.userLocation)
        return distance
    }
    
    func callGateIfNeeded () {
        //if guest, call is initiated from GatesTableViewController locationupdate()
        if self.isGuest {return}
        
        else if self.automatic && self.shouldCall {

            PhoneDialer.callGate(phoneNumber)
            shouldCall = false
        }
    }
    
    class func instansiate(
        _ name: String,
        latitude: Double,
        longitude: Double,
        automatic: Bool?,
        phoneNumber: String,
        fireDistanceFromGate: Int?) -> Gate? {
            
            var gate: Gate?
            
            let context = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Gate")
            request.predicate = NSPredicate(format: "name == %@", name)
            var error: NSError?
            let results: [AnyObject]?
            do {
                results = try context?.fetch(request)
            } catch let error1 as NSError {
                error = error1
                results = nil
            }
            
            if results?.count > 1 || error != nil {
                print("error creating Gate: \(String(describing: error))")
            }
            else if results?.count == 1 {
                //we have this gate
                gate = results?.last as? Gate
            }
            else {
                //create new gate
                let newGate = NSEntityDescription.insertNewObject(forEntityName: "Gate", into: context!) as! Gate
                newGate.uid = IDManager.shared.gataAutoId
                newGate.name = name
                newGate.latitude = latitude
                newGate.longitude = longitude
                newGate.automatic = automatic ?? true
                newGate.phoneNumber = phoneNumber
                newGate.fireDistanceFromGate = fireDistanceFromGate ?? 0
                gate = newGate
            }
        
    
            return gate
    }
    
    class func instansiateWithZero() -> Gate {
        
        let context = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: "Gate", in: context!)
        let newGate = Gate(entity: entity!, insertInto: context!) 
        newGate.uid = IDManager.shared.gataAutoId
        return newGate  
    }
    
    class func gateAsGuest(_ gateShare: GateShare) -> Gate? {
        
        let existstingGate = gateExiststAsGuest(gateShare)
        if existstingGate == nil{
            
            let newGate = Gate.instansiateWithZero()
            newGate.updateFrom(gateShare)
            Model.shared.locationNotifications.registerGateForLocationNotification(newGate)
            return newGate
        }
        
        existstingGate!.updateFrom(gateShare)
        return existstingGate
    }
    
    func updateFrom(_ gateShare: GateShare) {
        
        name = gateShare.gateName
        uid = gateShare.gateUid
        latitude = gateShare.latitude
        longitude = gateShare.longitude
        automatic = true
        fireDistanceFromGate = 50
        placemarkName = gateShare.placemarkName ?? ""
        isGuest = true
        ownerUid = gateShare.ownerUID
        shareId = gateShare.shareId
        shareToken = gateShare.shareToken ?? "shareToken"
        
        do {
            try Model.shared.context?.save()
        } catch  {
            print("cant save gate while creating as Guset: \(error.localizedDescription)")
        }
        
    }
    
    class func gateExiststAsGuest(_ gateShare: GateShare) -> Gate? {
        
        guard let gates = Model.shared.gates() else {return nil}
        for gate in gates {
            
            if gate.ownerUid == gateShare.ownerUID && gate.isGuest == true && gate.latitude == gateShare.latitude {
                return gate
            }
        }
        
        return nil
    }
    
    class func gateDictionary(_ gate: Gate) -> [AnyHashable: Any] {
        
        let keys = Array(gate.entity.attributesByName.keys)
        let dict = gate.dictionaryWithValues(forKeys: keys)
        print("keys are: \(dict)", terminator: "")
        return dict
    }
    
    func hasGateshare(_ gateshare: GateShare) -> Bool {
    
        let gateShareExists = self.shares.filter { aGateshare in
            aGateshare.gateName == gateshare.gateName && aGateshare.shareId == gateshare.shareId }
        if gateShareExists.isEmpty {
            return false
        }
        
      return true
        
    }
    
    func removeGateShare(_ gateShare: GateShare) {
    
        var indexToDelete = -1
        
        for (i, share) in shares.enumerated() {
        
            if share.shareId == gateShare.shareId {
                indexToDelete = i
                break
            }
        }
        
        if indexToDelete > -1 {shares.remove(at: indexToDelete)}
    }
    
    class func gateAsGuestForToken(_ shareToken: String?) -> Gate? {
    
        guard let token = shareToken else {return nil}
        guard let gates = Model.shared.gates() else { return nil }
        let filteredGates = gates.filter {gate in gate.shareToken == token}
        if filteredGates.isEmpty {return nil}
        return filteredGates.first
    }
    
    func toString() {
        print("Gate: ***************")
        print("name: \(self.name)")
        print("latitude: \(self.latitude)")
        print("longitude: \(self.longitude)")
        print("mode: \(self.automatic)")
        print("phone Number: \(phoneNumber)")
        print("distance: \(fireDistanceFromGate)")
        print("***************")
    }

    override func awakeFromFetch() {
        super.awakeFromFetch()
        shouldCall = true
    }
    
    
}
