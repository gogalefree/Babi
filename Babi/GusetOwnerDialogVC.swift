//
//  GusetOwnerDialogVC.swift
//  Babi
//
//  Created by Guy Freedman on 06/04/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import UIKit
import Material
import Firebase
import AVFoundation

@objc public class GusetOwnerDialogVC: UIViewController {

    private let kSBdentifier = "guestOwnerDialogVC"
    private let kNavVCID = "guestOwnerNav"
    private let guestOpeningMessage = "Openning Gate"
    private let guestWaitingMessage = "Wiating for host to open"
    private let guestStillWaitinggMessage = "Still waiting"
    private let guestCallAgainMessage = "No response. try again?"
    private var guestMessageIndex = 0
    private var guestMessages = [String]()
    
    private let ownerOpenGateMessage = "Open? "
    private let ownerOpenningGateMessage = "Openning"
    private let ownerCGateOpenedMessage = "Gate opened."
    private let ownerHasArrivedMessage = " has arrived."
    private var ownerMessages = [String]()
    private var ownerIndex = 0
    
    
    @IBOutlet weak var toolbar: Toolbar!
    @IBOutlet weak var dot1Label: UILabel!
    @IBOutlet weak var dot2Label: UILabel!
    @IBOutlet weak var dot3Label: UILabel!
    @IBOutlet weak var gateNameLable: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var guestReportOpenButton: FlatButton!
    @IBOutlet weak var guestWantsOpenAgainButton: FlatButton!
    @IBOutlet weak var callButton: IconButton!
    var cancelButton: IconButton!
    var activity: UIActivityIndicatorView!
    
    private var animationIndex = 0
    private var toAlpha:CGFloat = 1
    private var shouldAnimateBlink = true
    var didPlay = false

    var timer: Timer!
    var gate: Gate!
    var gateShare: GateShare?
    var player: AVAudioPlayer?
    
    //MARK: Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overCurrentContext
        guestMessages = [guestOpeningMessage ,guestWaitingMessage, guestStillWaitinggMessage , guestCallAgainMessage]
        ownerMessages = [ownerOpenGateMessage, ownerOpenningGateMessage, ownerCGateOpenedMessage]
        prepareCancelButton()
        prepareCtivityIndicator()
        prepareToolbar()
        prepareActionButtons()
        setupLabels()
        prepareGuestReportButtons()
        sendPushToOwnerAsGuest()
    }
  
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playSoundOnce()
    }

    func playSoundOnce() {

        if !didPlay {
        
            let aUrl = Bundle.main.url(forResource: "arrived_sound", withExtension:"mp3")
            guard let url = aUrl else {return}
            
        do {
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else {return}
            player.volume = 1
            player.prepareToPlay()
            player.play()
            didPlay = true
        } catch {
            // couldn't load file :(
            print("error playing: "  + error.localizedDescription)
        }
        }
    }
    //MARK: Actions
    
    @IBAction func guestReportOpen(_ sender: Any) {
  
        //dismiss
        self.dismiss(animated: true, completion: nil)
        print("guest reported open")
        //report to firebase as guest
        // set cancelled key to true
        let dbRef =  Database.database().reference()
        let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!).child(isCancelledKey)
        path.setValue(true)
    }
    
    @IBAction func guestWantsCallAgainButton(_ sender: Any) {
        callAction(sender)
    }
  
    public func informOwnerGateOpen() {
        
        let name = gateShare?.guestName ?? ""
        gateNameLable?.text = "Gate is Open."
        messageLabel?.text =  "\(name) is arriving."
        dissableCallButton()
        stopTimer()
        stopBlinkAnimation()
        
        //set is cancelled to false again
        let dbRef = Database.database().reference()
        let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!).child(isCancelledKey)
        path.setValue(false)
    }
    
    func reloadAsOwner() {
        stopBlinkAnimation()
        gateNameLable.text =  (gateShare?.guestName)! + " asks to open again."
        messageLabel.text = ownerMessages[0]
        enableCallButton()
    }
    
    func ownerDailing() {
    
        dissableCallButton()
        stopBlinkAnimation()
        stopTimer()
        messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
        messageLabel.text = "Owner Dailing"
        messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
        startBlinkAnimation()
        let _ = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.ownerCallingTimerAction), userInfo: nil, repeats: false)
    }

    @objc public func ownerCallingTimerAction() {
        enableCallButton()
        callButton.alpha = 0
        messageLabel.text = ""
        gateNameLable.text = "Opened?"
        stopBlinkAnimation()
        guestReportOpenButton.animateToAlphaWithSpring(0.2, alpha: 1)
        guestWantsOpenAgainButton.animateToAlphaWithSpring(0.2, alpha: 1)

    }

    @objc public func timerAction() {
        
        if gate!.isGuest {
            //change the maon label text
            guestMessageIndex += 1
            if guestMessageIndex < guestMessages.count {
             
                messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
                messageLabel.text = guestMessages[guestMessageIndex]
                messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
                if guestMessageIndex == guestMessages.count - 1 {
                    enableCallButton()
                    callButton.animateToAlphaWithSpring(0.1, alpha: 1)
                    guestMessageIndex = 0
                    stopTimer()
                    stopBlinkAnimation()
                    sendPushToOwnerAsGuest()
                }
            }
        }
        
        else {
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
            let guestName = gateShare?.guestName ?? "Someone"
            self.gateNameLable.text = ownerMessages[2]
            self.messageLabel.text = " Waiting for \(guestName)"
            messageLabel.animateToAlphaWithSpring(0.1, alpha:1)
            stopBlinkAnimation()
            enableCallButton()
        }
    }
    
    @IBAction func callAction(_ sender: Any) {
        
        if gate!.isGuest {
            guestReportOpenButton.animateToAlphaWithSpring(0.1, alpha: 0)
            guestWantsOpenAgainButton.animateToAlphaWithSpring(0.1, alpha: 0)
            dissableCallButton()
            let dbRef = Database.database().reference()
            let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!).child(kOwnerShouldFireKey)
            path.setValue(true)

            //gate!.shouldCall = true
            gateNameLable.text = "Calling"
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
            messageLabel.text = guestMessages[0]
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
            startTimer(secconds: 10, shouldRepeat: true)
            startBlinkAnimation()
        } else {
            ownerIndex = 1
            startBlinkAnimation()
            startTimer(secconds: 12, shouldRepeat: false)
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
            messageLabel.text = ownerMessages[1]
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
            PhoneDialer.callGate(gate.phoneNumber)
        }
    }
    
   @objc public func cancelButtonAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: UI Setup
    fileprivate func setupLabels() {
        
        for dot in [dot1Label , dot2Label, dot3Label] {
            dot!.alpha = 0
            dot!.textColor = #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)
        }
        
        if gate.isGuest {
            gateNameLable.text = gate!.name
            messageLabel.text = guestOpeningMessage
            startBlinkAnimation()
            startTimer(secconds: 7, shouldRepeat: true)
        }
        
        else {
            stopBlinkAnimation()
            gateNameLable.text =  (gateShare?.guestName)! + ownerHasArrivedMessage
            messageLabel.text = ownerMessages[0]
        }
    }
    
    fileprivate func prepareCtivityIndicator() {
        activity = UIActivityIndicatorView()
        activity.bounds.size.width = 40
        activity.bounds.size.height = 40
        activity.activityIndicatorViewStyle = .gray
        activity.color = .purple
        activity.hidesWhenStopped = true
    }

    fileprivate func prepareCancelButton() {
        cancelButton = IconButton(image: Icon.cm.close, tintColor: Color.red.base)
        cancelButton.addTarget(self, action: #selector(self.cancelButtonAction), for: .touchUpInside)
    }

    fileprivate func prepareToolbar() {
        toolbar.rightViews = [cancelButton]
        toolbar.leftViews = [activity]
    }
    
    fileprivate func prepareActionButtons(){
//        stopCallButton.image = UIImage(named: "ic_call_end_white_36pt.png")!.withRenderingMode(
//            UIImageRenderingMode.alwaysTemplate)
//        stopCallButton.tintColor = Color.red.base
//        stopCallButton.backgroundColor = .white
        callButton.image = UIImage(named:"ic_call_36pt.png")!.withRenderingMode(
            UIImageRenderingMode.alwaysTemplate)
        callButton.backgroundColor = .white
        
        if gate.isGuest {
            dissableCallButton()
        } else {
            enableCallButton()
        }
    }

    func prepareGuestReportButtons() {
        guestReportOpenButton.title = "Gate's Open"
        guestReportOpenButton.alpha = 0
        guestWantsOpenAgainButton.title = "Call again"
        guestWantsOpenAgainButton.alpha = 0
    }
    
    func enableCallButton() {
        self.callButton?.isEnabled = true
        self.callButton?.tintColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
    }
    
    func dissableCallButton() {
        self.callButton?.isEnabled = false
        self.callButton?.tintColor = .gray
    }

    //MARK: Animations

    func startBlinkAnimation() {
        shouldAnimateBlink = true
        animateBlink()
        activity.startAnimating()
    }
    
    func stopBlinkAnimation() {
        shouldAnimateBlink = false
        for dot in [dot1Label , dot2Label, dot3Label] {
            dot?.animateToAlphaWithSpring(0.1 , alpha: 0)
        }
        activity?.stopAnimating()
    }
    
    private func animateBlink() {

        if !shouldAnimateBlink {return}
        
        var animatingViews =  [dot1Label , dot2Label, dot3Label]
        let viewToAnimate = animatingViews[animationIndex]!
        animateView( viewToAnimate, toAlpha: toAlpha) {
            if self.animationIndex == 3 {
                self.animationIndex = 0
                self.toAlpha = self.toAlpha == 1 ? 0 : 1
            }
            
            self.animateBlink()

        }
    }
    
    private func animateView(_ aView: UIView, toAlpha: CGFloat, completion: @escaping () -> ()) {
        
        UIView.animate(withDuration: 0.2, animations: {
            
            aView.alpha = toAlpha
        }) { (finished) in
            if finished {
                self.animationIndex += 1
                completion()
            }
        }
    }
    
    //MARK: Timer
    
    func startTimer(secconds: TimeInterval, shouldRepeat: Bool) {
        timer = Timer.scheduledTimer(timeInterval: secconds, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: shouldRepeat)
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    //MARK: Push Notifications to owner
    private func sendPushToOwnerAsGuest() {
        let pushToken = gate.ownerPushToken
        if pushToken == kOwnerPushToken || pushToken.isEmpty {return}
        let badge =  1
        let gateName = gate.name 
        let title =  "Your guest arrived to \(gateName)"
        let body = "Launch BaBi?"
        print(title)
        var request = URLRequest(url: URL(string: "https://fcm.googleapis.com/fcm/send")!)
        request.httpMethod = "POST"
        let payload: [String: Any] = [
            "notification": [
                "title": title,
                "body": body,
                "badge" : badge,
                "click_action": "Launch",
                "sound" : "default",
                "content-available" : 1
            ],
            
            "to" : pushToken]
        
        request.httpBody = try! JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
        request.setValue("key=AAAAF0fIu3w:APA91bHI7Jue-5BpTzYZ-90FF-nE5NZTsCP0IXvm6E52T_fqWgDM7dDe6mnTl1aAqq38fUWoBlr_lUJLHIU_pG__TcXxEbEx66xjfqYhv3AyQt2OU0HVw1TURLluhMb9gOhOWJCtqmJB", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(String(describing: error))")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
            }
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
        }
        task.resume()
    }
}
