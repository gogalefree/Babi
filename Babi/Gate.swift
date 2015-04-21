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
//    
//    var distanceFromUserLocation: CLLocationDistance {
//     
//        var gateCords = CLLocation(latitude: latitude, longitude: longitude)
//        var distance = gateCords.distanceFromLocation(Model.shared.userLocation)
//       // println("gate \(name) distance \(distance)")
//        return distance
//    }
    
//    func didUpdateLocation() {
//      
//        if self.distanceFromUserLocation < Double(self.fireDistanceFromGate) {
//            userInRegion = true
//        }
//        else {
//            userInRegion = false
//        }
//    }
    
    func distanceFromUserLocation() -> Double {
        
        var gateCords = CLLocation(latitude: latitude, longitude: longitude)
        var distance = gateCords.distanceFromLocation(Model.shared.userLocation)
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
            let results = context?.executeFetchRequest(request, error: &error)
            
            if results?.count > 1 || error != nil {
                println("error creating Gate: \(error)")
            }
            else if results?.count == 1 {
                //we have this gate
                gate = results?.last as? Gate
            }
            else {
                //create new gate
                var newGate = NSEntityDescription.insertNewObjectForEntityForName("Gate", inManagedObjectContext: context!) as! Gate
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
        
        var newGate = Gate(entity: entity!, insertIntoManagedObjectContext: context!) as Gate!
        
        return newGate

    }
    
    class func gateDictionary(gate: Gate) -> [NSObject : AnyObject] {
        
        let keys = gate.entity.attributesByName.keys.array
        let dict = gate.dictionaryWithValuesForKeys(keys)
        print("keys are: \(dict)")
        return dict
    }
    
    func toString() {
        println("Gate: ***************")
        println("name: \(self.name)")
        println("latitude: \(self.latitude)")
        println("longitude: \(self.longitude)")
        println("mode: \(self.automatic)")
        println("phone Number: \(phoneNumber)")
        println("distance: \(fireDistanceFromGate)")
        println("***************")
    }

    override func awakeFromFetch() {
        super.awakeFromFetch()
        shouldCall = true
    }
}
