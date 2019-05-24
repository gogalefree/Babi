//
//  URLController.swift
//  Babi
//
//  Created by Guy Freedman on 19/06/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import UIKit

class URLController: NSObject {

  static let shared = URLController()
  
  func open(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool{
    guard let babi = url.scheme else { return false }
    
    if babi == "babi" {
      
      
      var dict = [String:String]()
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
      if let queryItems = components.queryItems {
        for item in queryItems {
          dict[item.name] = item.value!
        }
      }
      let ownerId     = dict["od"] ?? ""
      let shareToken  = dict["token"] ?? ""
      let shareId     = dict["shareId"] ?? ""
      if !ownerId.isEmpty && !shareToken.isEmpty && !shareId.isEmpty{
        log.info("shrae by guest ownerId: \(ownerId) shareid: \(shareId)")
        FireBaseController.shared.fetchGateShareasGuest(ownerId, shareToken, shareId)
      }
    }
    return true
  }
  
}
