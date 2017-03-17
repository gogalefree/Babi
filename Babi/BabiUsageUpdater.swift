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
    
    
    var deviceUUID : String? =  UserDefaults.standard.object(forKey: kDeviceUUIDKey) as? String
    var didReportUUID: Bool? = UserDefaults.standard.bool(forKey: kDidReportUUID)
    var didBecomeActiveCounter: Int? = UserDefaults.standard.integer(forKey: kDidBecomeActiveCounterKey)
    
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
        
        deviceUUID = deviceUUID ?? {
           
            let uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: kDeviceUUIDKey)
            return uuid
        }()
        
        //report uuid to server if needed
        if didReportUUID == nil || didReportUUID == false {
            
            reportUUID()
        }
    }
    
    func reportUUID() {

        let params = paramsForInitialReport()
        let jsonData = try? JSONSerialization.data(withJSONObject: params, options: [])
        let url = URL(string: initialReportUrlString)

        var request = URLRequest(url: url!)
        request.httpMethod = "PUT"
        request.httpBody = jsonData!
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: {
            (data, response , error) -> Void in
            
            if let response = response {
                
                let serverResponse = response as! HTTPURLResponse
                
                print(serverResponse)
                if error == nil {
                    
                    UserDefaults.standard.set(true, forKey: kDidReportUUID)
                    self.didReportUUID = true
                }
                else {
                    print("error: \(error)")
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
        let local = Locale.current
        countryCode = (local as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String
        print("local code: \(countryCode)")
        return countryCode
    }
    
    func dateInstalled() -> String {
        
        var dateInstalled = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        let date = Date()
        dateInstalled = dateFormatter.string(from: date)
        print("date: \(dateInstalled)")
        return dateInstalled
    }
    
    func incrementDidBecomeActive() {
        
        var storedCounter = UserDefaults.standard.integer(forKey: kDidBecomeActiveCounterKey)
        storedCounter += 1
        UserDefaults.standard.set(storedCounter, forKey: kDidBecomeActiveCounterKey)
        
        //reportToServerIfNeede
        
        if storedCounter % 5 == 0 {
            self.reportActivityCounter(storedCounter)
        }
    }
    
    func reportActivityCounter(_ storedCounter: Int) {
        
        if let deviceUUID = deviceUUID {
            
            let params = [kAppIdKey:kAppIdValue,kBecameActiveParamsKey:storedCounter,kDeviceUUIDParamsKey:deviceUUID] as [String : Any]

            let dictToSend = try? JSONSerialization.data(withJSONObject: params, options: [])
            
            print(params)
            
            let url = URL(string: updateActivityURLString)
            var request = URLRequest(url: url!)
            request.httpMethod = "PUT"
            request.httpBody = dictToSend
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let session = URLSession.shared
            let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                
                if let serverResponse = response {
                    
                    print("respons: \(serverResponse.description)", terminator: "")
                    
                    if error == nil {
                        //we currently implement as best effort. nothing is done with an error
                        if let data = data {
                            
                            do {
                        
                                let recieved = try JSONSerialization.jsonObject(with: data, options: []) as? [String:String]
                                
                                print("receieved: \(recieved)")
                                
                            }catch let error as NSError {
                                print("error: \(error)" + " " + #function)
                            }
                        }
                        
                    }
                }
            })
            
            task.resume()
            
            
        }
        
        
    }
}
