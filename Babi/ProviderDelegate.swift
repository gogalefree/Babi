//
//  ProviderDelegate.swift
//  Babi
//
//  Created by Guy Freedman on 17/08/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import AVFoundation
import CallKit

@available(iOS 10.0, *)
class ProviderDelegate: NSObject {
  
  fileprivate let callManager: CallManager
  fileprivate let provider: CXProvider
  
  init(callManager: CallManager) {
    self.callManager = callManager
    // 2.
    provider = CXProvider(configuration: type(of: self).providerConfiguration)
    
    super.init()
    // 3.
    provider.setDelegate(self, queue: nil)
  }
  
  func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)?) {
    // 1.
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
    update.hasVideo = hasVideo
    
    // 2.
    provider.reportNewIncomingCall(with: uuid, update: update) { error in
      if error == nil {
        // 3.
        let call = Call(uuid: uuid, handle: handle)
        self.callManager.add(call: call)
      }
      
      // 4.
      completion?(error as NSError?)
    }
  }
  
  static var providerConfiguration: CXProviderConfiguration {
    let providerConfiguration = CXProviderConfiguration(localizedName: "BabiHotline")
    providerConfiguration.supportsVideo = false
    providerConfiguration.maximumCallsPerCallGroup = 1
    providerConfiguration.supportedHandleTypes = [.phoneNumber]
    return providerConfiguration
  }
}

@available(iOS 10.0, *)
extension ProviderDelegate: CXProviderDelegate {
  
  func providerDidReset(_ provider: CXProvider) {
    stopAudio()
    
    for call in callManager.calls {
      call.end()
    }
    
    callManager.removeAllCalls()
  }
  
  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    // 1.
    guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
      action.fail()
      return
    }
    
    // 2.
    stopAudio()
    // 3.
    call.end()
    // 4.
    action.fulfill()
    // 5.
    callManager.remove(call: call)
  }
  
  //outgoing call
  func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
    let call = Call(uuid: action.callUUID, outgoing: true, handle: action.handle.value)
    // 1.
    configureAudioSession()
    // 2.
    call.connectedStateChanged = { [weak self, weak call] in
      guard let strongSelf = self, let call = call else { return }
      
      if call.connectedState == .pending {
        strongSelf.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
      } else if call.connectedState == .complete {
        strongSelf.provider.reportOutgoingCall(with: call.uuid, connectedAt: nil)
      }
    }
    // 3.
    call.start { [weak self, weak call] success in
      guard let strongSelf = self, let call = call else { return }
      
      if success {
        action.fulfill()
        strongSelf.callManager.add(call: call)
      } else {
        action.fail()
      }
    }
  }
}
