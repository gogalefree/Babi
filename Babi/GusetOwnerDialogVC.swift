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

class GusetOwnerDialogVC: UIViewController {

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
    private let ownerCallAgainGateMessage = "Gate opened. Call Again? "
    private let ownerHasArrivedMessage = " has arrived."
    private var ownerMessages = [String]()
    private var ownerIndex = 0
    
    
    @IBOutlet weak var toolbar: Toolbar!
    @IBOutlet weak var dot1Label: UILabel!
    @IBOutlet weak var dot2Label: UILabel!
    @IBOutlet weak var dot3Label: UILabel!
    @IBOutlet weak var gateNameLable: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var stopCallButton: IconButton!
    @IBOutlet weak var guestReportOpenButton: FlatButton!
    @IBOutlet weak var callButton: IconButton!
    var cancelButton: IconButton!
    var activity: UIActivityIndicatorView!
    
    private var animationIndex = 0
    private var toAlpha:CGFloat = 1
    private var shouldAnimateBlink = true

    var timer: Timer!
    var gate: Gate!
    var gateShare: GateShare?
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overCurrentContext
        guestMessages = [guestOpeningMessage ,guestWaitingMessage, guestStillWaitinggMessage , guestCallAgainMessage]
        ownerMessages = [ownerOpenGateMessage, ownerOpenningGateMessage, ownerCallAgainGateMessage]
        prepareCancelButton()
        prepareCtivityIndicator()
        prepareToolbar()
        prepareActionButtons()
        setupLabels()
        prepareGuestReportOpenButton()
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    //MARK: Actions
    
    @IBAction func guestReportOpen(_ sender: Any) {
  
        //dismiss
        self.dismiss(animated: true, completion: nil)
        print("guest reported open")
        //report to firebase as guest
        // set cancelled key to true
        let dbRef = FIRDatabase.database().reference()
        let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!).child(isCancelledKey)
        path.setValue(true)
    }
  
    func informOwnerGateOpen() {
        
        let name = gateShare?.guestName ?? ""
        gateNameLable?.text = name + " " + "is arriving."
        messageLabel?.text = "Gate is Open."
        dissableCallButton()
        stopTimer()
        stopBlinkAnimation()
    }
    
    func reloadAsOwner() {
        stopBlinkAnimation()
        gateNameLable.text =  (gateShare?.guestName)! + " asks to open again."
        messageLabel.text = ownerMessages[0]
    }
    
    func ownerDailing() {
    
        dissableCallButton()
        stopBlinkAnimation()
        stopTimer()
        messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
        messageLabel.text = "Owner Dailing"
        messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
        startBlinkAnimation()
        let _ = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(ownerCallingTimerAction), userInfo: nil, repeats: false)
    }

    func ownerCallingTimerAction() {
        enableCallButton()
        self.messageLabel.text = ownerMessages[2]
        stopBlinkAnimation()
        guestReportOpenButton.animateToAlphaWithSpring(0.2, alpha: 1)
    }

    func timerAction() {
        
        if gate!.isGuest {
            //change the maon label text
            guestMessageIndex += 1
            if guestMessageIndex < guestMessages.count {
             
                messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
                messageLabel.text = guestMessages[guestMessageIndex]
                messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
                if guestMessageIndex == guestMessages.count - 1 {
                    enableCallButton()
                    guestMessageIndex = 0
                    stopTimer()
                    stopBlinkAnimation()
                }
            }
        }
        
        else {
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
            messageLabel.text = ownerMessages[2]
            messageLabel.animateToAlphaWithSpring(0.1, alpha:1)
            stopBlinkAnimation()
            enableCallButton()
        }
    }
    
    @IBAction func callAction(_ sender: Any) {
        
        if gate!.isGuest {
            guestReportOpenButton.animateToAlphaWithSpring(0.1, alpha: 0)
            dissableCallButton()
            let dbRef = FIRDatabase.database().reference()
            let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!).child(kOwnerShouldFireKey)
            path.setValue(true)

            //gate!.shouldCall = true
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
            messageLabel.text = guestMessages[0]
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
            startTimer(secconds: 10, shouldRepeat: true)
            startBlinkAnimation()
        } else {
            dissableCallButton()
            ownerIndex = 1
            startBlinkAnimation()
            startTimer(secconds: 12, shouldRepeat: false)
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
            messageLabel.text = ownerMessages[1]
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
            PhoneDialer.callGate(gate.phoneNumber)
        }
    }
    
    @IBAction func stopCallAction(_ sender: Any) {
        stopBlinkAnimation()
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonAction() {
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
        activity.width = 40
        activity.height = 40
        activity.activityIndicatorViewStyle = .gray
        activity.color = .purple
        activity.hidesWhenStopped = true
    }

    fileprivate func prepareCancelButton() {
        cancelButton = IconButton(image: Icon.cm.close, tintColor: Color.red.base)
        cancelButton.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
    }

    fileprivate func prepareToolbar() {
        toolbar.rightViews = [cancelButton]
        toolbar.leftViews = [activity]
    }
    
    fileprivate func prepareActionButtons(){
        stopCallButton.image = UIImage(named: "ic_call_end_white_36pt.png")!.withRenderingMode(
            UIImageRenderingMode.alwaysTemplate)
        stopCallButton.tintColor = Color.red.base
        stopCallButton.backgroundColor = .white
        callButton.image = UIImage(named:"ic_call_36pt.png")!.withRenderingMode(
            UIImageRenderingMode.alwaysTemplate)
        callButton.backgroundColor = .white
        
        if gate.isGuest {
            dissableCallButton()
        } else {
            enableCallButton()
        }
    }

    func prepareGuestReportOpenButton() {
        guestReportOpenButton.title = "Gate's Open, Thanks."
        guestReportOpenButton.alpha = 0
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
        timer = Timer.scheduledTimer(timeInterval: secconds, target: self, selector: #selector(timerAction), userInfo: nil, repeats: shouldRepeat)
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    func enableCallButton() {
        self.callButton?.isEnabled = true
        self.callButton?.tintColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
    }
    
    func dissableCallButton() {
        self.callButton?.isEnabled = false
        self.callButton?.tintColor = .gray
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
