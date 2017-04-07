//
//  GusetOwnerDialogVC.swift
//  Babi
//
//  Created by Guy Freedman on 06/04/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import UIKit
import Material

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
    private let ownerCallAgainGateMessage = "Call Again? "
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
    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    //MARK: Actions
    
    func ownerDailing() {
    
        callButton.isEnabled = false
        stopBlinkAnimation()
        stopTimer()
        messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
        messageLabel.text = "Owner Dailing"
        messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
        startBlinkAnimation()
        let _ = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(ownerCallingTimerAction), userInfo: nil, repeats: false)
    }

    func ownerCallingTimerAction() {
        self.callButton.isEnabled = true
        self.messageLabel.text = ownerMessages[2]
        stopBlinkAnimation()
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
                    callButton.isEnabled = true
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
            callButton.isEnabled = true
        }
    }
    
    @IBAction func callAction(_ sender: Any) {
        
        if gate!.isGuest {
            callButton.isEnabled = false
            gate!.shouldCall = true
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 0)
            messageLabel.text = guestMessages[0]
            messageLabel.animateToAlphaWithSpring(0.1, alpha: 1)
            startTimer(secconds: 5, shouldRepeat: true)
            startBlinkAnimation()
        } else {
            self.callButton.isEnabled = false
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
            startTimer(secconds: 5, shouldRepeat: true)
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
        callButton.tintColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        callButton.backgroundColor = .white
        callButton.isEnabled = gate.isGuest ? false : true
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
            dot!.animateToAlphaWithSpring(0.1 , alpha: 0)
        }
        activity.stopAnimating()
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
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(timerAction), userInfo: nil, repeats: shouldRepeat)
    }
    
    func stopTimer() {
        timer?.invalidate()
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
