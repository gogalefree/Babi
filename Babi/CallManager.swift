//
//  CallManager.swift
//  Babi
//
//  Created by Guy Freedman on 17/08/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import Foundation
import CallKit

@available(iOS 10.0, *)
class CallManager {
  
  var callsChangedHandler: (() -> Void)?
  
  private(set) var calls = [Call]()
  private let callController = CXCallController()
  
  
  func callWithUUID(uuid: UUID) -> Call? {
    guard let index = calls.index(where: { $0.uuid == uuid }) else {
      return nil
    }
    return calls[index]
  }
  
  func add(call: Call) {
    calls.append(call)
    call.stateChanged = { [weak self] in
      guard let strongSelf = self else { return }
      strongSelf.callsChangedHandler?()
    }
    callsChangedHandler?()
  }
  
  func remove(call: Call) {
    guard let index = calls.index(where: { $0 === call }) else { return }
    calls.remove(at: index)
    callsChangedHandler?()
  }
  
  func removeAllCalls() {
    calls.removeAll()
    callsChangedHandler?()
  }
  
  func end(call: Call) {
    // 1.
    let endCallAction = CXEndCallAction(call: call.uuid)
    // 2.
    let transaction = CXTransaction(action: endCallAction)
    
    requestTransaction(transaction)
  }
  
  // 3.
  private func requestTransaction(_ transaction: CXTransaction) {
    callController.request(transaction) { error in
      if let error = error {
        print("Error requesting transaction: \(error)")
      } else {
        print("Requested transaction successfully")
      }
    }
  }
}
