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
import Firebase

let kDeviceUUIDKey = "BabiUUID"
let kDidReportUUID = "DidReportUUID"
let kDidBecomeActiveCounterKey = "DidBecomeActiveCounter"

let kCountryCodeParamsKey = "country_code"
let kDateInstalledParamsKey = "date_installed"
let kDeviceUUIDParamsKey = "device_uuid"
let kBecameActiveParamsKey = "became_active"
let kIsIosKey                = "is_ios"
let kPushTokenKey            = "push_token"
let kPhoneNumberKey          = "phone_number"
let kGatesCountKey           = "gates_count"
let kAppIdKey = "app_id"
let kAppIdValue = "babi1062n7s5"

let initialReportUrlString = "http://54.200.233.10/babi/babi_initial_report.php"
let updateActivityURLString = "http://54.200.233.10/babi/bab_update_activity.php"

let herokuUrlString = "https://babi-server.herokuapp.com/babiUser"
let localhostUrlString = "http://localhost:8080/babiUser"

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
    //let url = URL(string: initialReportUrlString)
    let url = URL(string: herokuUrlString)
    
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.httpBody = jsonData!
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    let session = URLSession.shared
    let task = session.dataTask(with: request, completionHandler: {
      (data, response , error) -> Void in
      
      print(String(describing: response))
      if let response = response {
        
        let serverResponse = response as! HTTPURLResponse
        
        print(serverResponse)
        if error == nil {
          
          UserDefaults.standard.set(true, forKey: kDidReportUUID)
          self.didReportUUID = true
        }
        else {
          print("error: \(String(describing: error))")
        }
      }
    })
    
    task.resume()
  }
  
  func paramsForInitialReport() -> [String: Any] {
    
    let countryCode = getCountryCode()
    let installationDate = dateInstalled()
    let params =
      [kCountryCodeParamsKey : countryCode,
       kDateInstalledParamsKey : installationDate,
       kDeviceUUIDParamsKey: deviceUUID!,
       kIsIosKey : true,
       kAppIdKey : kAppIdValue] as [String : Any]
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
    
    if storedCounter % 3 == 0 {
      self.reportActivityCounter(storedCounter)
    }
  }
  
  func reportActivityCounter(_ storedCounter: Int) {
    
    if let deviceUUID = deviceUUID {
      
      let pushToken = FIRInstanceID.instanceID().token() ?? ""
      let gatesCount = Model.shared.gates()?.count ?? 0
      
      let params = [kAppIdKey:kAppIdValue,
                    kBecameActiveParamsKey:storedCounter,
                    kDeviceUUIDParamsKey:deviceUUID,
                    kGatesCountKey : gatesCount,
                    kPushTokenKey : pushToken] as [String : Any]
      
      let dictToSend = try? JSONSerialization.data(withJSONObject: params, options: [])
      
      print(params)
      
      // let url = URL(string: updateActivityURLString)
      let url = URL(string: herokuUrlString)
      
      var request = URLRequest(url: url!)
      request.httpMethod = "PATCH"
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
                
                print("receieved: \(String(describing: recieved))")
                
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
