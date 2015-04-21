//
//  BabiUsageUpdater.swift
//  Babi
//
//  Created by Guy Freedman on 4/19/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import Foundation
import AddressBookUI
import CoreTelephony

let kDeviceUUIDKey = "BabiUUID"
let kDidReportUUID = "DidReportUUID"
let kDidBecomeActiveCounterKey = "DidBecomeActiveCounter"

let kCountryCodeParamsKey = "country_code"
let kDateInstalledParamsKey = "date_installed"
let kDeviceUUIDParamsKey = "device_uuid"
let kBecameActiveParamsKey = "became_active"
let kAppIdKey = "app_id"
let kAppIdValue = "babi1062n7s5"

let initialReportUrlString = "http://54.200.233.10/babi/babi_initial_report.php"
let updateActivityURLString = "http://54.200.233.10/babi/bab_update_activity.php"


class BabiUsageUpdater: NSObject {
    
    
    var deviceUUID : String? =  NSUserDefaults.standardUserDefaults().objectForKey(kDeviceUUIDKey) as? String
    var didReportUUID: Bool? = NSUserDefaults.standardUserDefaults().boolForKey(kDidReportUUID)
    var didBecomeActiveCounter: Int? = NSUserDefaults.standardUserDefaults().integerForKey(kDidBecomeActiveCounterKey)
    
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
        
        deviceUUID = deviceUUID ?? {
           
            var uuid = NSUUID().UUIDString
            NSUserDefaults.standardUserDefaults().setObject(uuid, forKey: kDeviceUUIDKey)
            return uuid
        }()
        
        //report uuid to server if needed
        if didReportUUID == nil || didReportUUID == false {
            
            reportUUID()
        }
    }
    
    func reportUUID() {

        let params = paramsForInitialReport()
        let jsonData = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: nil)
        let url = NSURL(string: initialReportUrlString)

        var request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "PUT"
        request.HTTPBody = jsonData!
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: {
            (data:NSData!, response: NSURLResponse!, error:NSError!) -> Void in
            
            if let response = response {
                
                let serverResponse = response as! NSHTTPURLResponse
                
                if error == nil {
                    
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: kDidReportUUID)
                    self.didReportUUID = true
                }
                else {
                    println("error: \(error)")
                }
            }
        })
        
        task.resume()
    }
    
    func paramsForInitialReport() -> [String: String] {
        
        let countryCode = getCountryCode()
        let installationDate = dateInstalled()
        let params =
        [kCountryCodeParamsKey : countryCode,
        kDateInstalledParamsKey : installationDate,
        kDeviceUUIDParamsKey: deviceUUID!,
        kAppIdKey : kAppIdValue]
        return params
    }
    
    func getCountryCode() -> String {
        
        var countryCode: String = "NotPhone"
        let local = NSLocale.currentLocale()
        countryCode = local.objectForKey(NSLocaleCountryCode) as! String
        println("local code: \(countryCode)")
        return countryCode
    }
    
    func dateInstalled() -> String {
        
        var dateInstalled = ""
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        let date = NSDate()
        dateInstalled = dateFormatter.stringFromDate(date)
        println("date: \(dateInstalled)")
        return dateInstalled
    }
    
    func incrementDidBecomeActive() {
        
        var storedCounter = NSUserDefaults.standardUserDefaults().integerForKey(kDidBecomeActiveCounterKey)
        storedCounter++
        NSUserDefaults.standardUserDefaults().setInteger(storedCounter, forKey: kDidBecomeActiveCounterKey)
        
        //reportToServerIfNeede
        
        if storedCounter % 5 == 0 {
            self.reportActivityCounter(storedCounter)
        }
    }
    
    func reportActivityCounter(storedCounter: Int) {
        
        if let deviceUUID = deviceUUID {
            
            let params = [kAppIdKey:kAppIdValue,kBecameActiveParamsKey:storedCounter,kDeviceUUIDParamsKey:deviceUUID]

            let dictToSend = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: nil)
            
            println(params)
            
            let url = NSURL(string: updateActivityURLString)
            var request = NSMutableURLRequest(URL: url!)
            request.HTTPMethod = "PUT"
            request.HTTPBody = dictToSend
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithRequest(request, completionHandler: { (data:NSData!, response: NSURLResponse!, error:NSError!) -> Void in
                
                if var serverResponse = response {
                    
                    print("respons: \(serverResponse.description)")
                    
                    if error == nil {
                        //we currently implement as best effort. nothing is done with an error
                        let recieved = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as! [String:String]
    
                        println("receieved: \(recieved)")
                        
                    }
                }
            })
            
            task.resume()
            
            
        }
        
        
    }
}
