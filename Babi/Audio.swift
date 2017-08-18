//
//  Audio.swift
//  Babi
//
//  Created by Guy Freedman on 17/08/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import AVFoundation

func configureAudioSession() {
  print("Configuring audio session")
  let session = AVAudioSession.sharedInstance()
  do {
    try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
    if #available(iOS 9.0, *) {
      try session.setMode(AVAudioSessionModeSpokenAudio)
    } else {
      // Fallback on earlier versions
    }
    //AVAudioSessionModeSpokenAudio
    //AVAudioSessionModeVoiceChat
  } catch (let error) {
    print("Error while configuring audio session: \(error)")
  }
}

func startAudio() {
  print("Starting audio")
}

func stopAudio() {
  print("Stopping audio")
}

