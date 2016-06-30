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

let kGateNameDefaultValue = "Gate"
let kGatePhoneNumberDefaultValue = "phoneNumber"
let kGateLatitudeDefaultValue = 0.0
let kGateLongitudeDefaultValue = 0.0
let kGateModeDefaultValue = true
let kGateDistanceToCallDefaultValue = 50
let kGatePlacemarkNameDefaultValue = "placemarkName"

class Gate: NSManagedObject {
    

    @NSManaged var name: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var automatic: Bool
    @NSManaged var phoneNumber: String
    @NSManaged var fireDistanceFromGate: Int
    @NSManaged var placemarkName: String
    
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
        let distance = gateCords.distanceFromLocation(Model.shared.userLocation)
        return distance
    }
    
    func callGateIfNeeded () {
        
        if self.automatic && self.shouldCall {

            PhoneDialer.callGate(phoneNumber)
            shouldCall = false
        }
    }
    
    class func instansiate(
        name: String,
        latitude: Double,
        longitude: Double,
        automatic: Bool?,
        phoneNumber: String,
        fireDistanceFromGate: Int?) -> Gate? {
            
            var gate: Gate?
            
            let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
            
            let request = NSFetchRequest(entityName: "Gate")
            request.predicate = NSPredicate(format: "name == %@", name)
            var error: NSError?
            let results: [AnyObject]?
            do {
                results = try context?.executeFetchRequest(request)
            } catch let error1 as NSError {
                error = error1
                results = nil
            }
            
            if results?.count > 1 || error != nil {
                print("error creating Gate: \(error)")
            }
            else if results?.count == 1 {
                //we have this gate
                gate = results?.last as? Gate
            }
            else {
                //create new gate
                let newGate = NSEntityDescription.insertNewObjectForEntityForName("Gate", inManagedObjectContext: context!) as! Gate
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
        
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let entity = NSEntityDescription.entityForName("Gate", inManagedObjectContext: context!)
        
        let newGate = Gate(entity: entity!, insertIntoManagedObjectContext: context!) as Gate!
        
        return newGate

    }
    
    class func gateDictionary(gate: Gate) -> [NSObject : AnyObject] {
        
        let keys = gate.entity.attributesByName.keys.array
        let dict = gate.dictionaryWithValuesForKeys(keys)
        print("keys are: \(dict)", terminator: "")
        return dict
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
