//
//  Gate.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//
import CoreData
import UIKit

@objc(Gate)
class Gate: NSManagedObject {
    

    @NSManaged var name: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var automatic: Bool
    @NSManaged var phoneNumber: String
    @NSManaged var fireDistanceFromGate: Int
    
    class func instansiate(
        name: String,
        latitude: Double,
        longitude: Double,
        automatic: Bool?,
        phoneNumber: String,
        fireDistanceFromGate: Int?) -> Gate? {
            
            var gate: Gate?
            
            let context = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext
            
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
                var newGate = NSEntityDescription.insertNewObjectForEntityForName("Gate", inManagedObjectContext: context!) as Gate
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
        
        let context = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext
        
        var newGate = NSEntityDescription.insertNewObjectForEntityForName("Gate", inManagedObjectContext: context!) as Gate
        
        return newGate

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

   
}
