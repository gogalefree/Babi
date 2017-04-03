//
//  ViewController.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import Foundation

let kSleepModeKey = "kSleepModeKey"

class MainContainerController: UIViewController {
    
    lazy var noGatesMessageVC : NoGatesVC!  = {
        return self.storyboard?.instantiateViewController(withIdentifier: "noGatesMessageVC") as! NoGatesVC
        }()
    
    lazy var gatesTVCNavigationVC: UINavigationController! = {
        return self.storyboard?.instantiateViewController(withIdentifier: "GatesTVCNavController")
            as! UINavigationController!
    }()
    
    @IBOutlet weak var dimmingView: UIView!
    @IBOutlet weak var sleepModeMessageView: UIView!
    @IBOutlet weak var sleepMessageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var wakeUpButton: UIButton!
    let kSleepMessageHiddenConstant: CGFloat = -400.0
    let kSleepMessageVisibleConstant: CGFloat = 70.0
   
    
    var sleepMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.dimmingView.alpha = 0
        self.sleepModeMessageView.alpha = 0
        self.wakeUpButton.alpha = 0
        self.sleepMessageTopConstraint.constant = kSleepMessageHiddenConstant
        self.wakeUpButton.layer.borderColor = UIColor.white.cgColor
        self.wakeUpButton.layer.borderWidth = 1
        self.wakeUpButton.layer.cornerRadius = 10
        
        presentWelcomeMessage()
        
        let delayTime = DispatchTime.now() + Double(Int64(2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: { () -> Void in
            
            self.presentGatesTVC()
        })        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if sleepMode {
            wakeUpFromSleepMode()
        }
    }
    
    func presentGatesTVC() {
    
            gatesTVCNavigationVC.view.alpha = 0
            self.addChildViewController(gatesTVCNavigationVC)
            gatesTVCNavigationVC.view.frame = self.view.bounds
            gatesTVCNavigationVC.didMove(toParentViewController: self)
            self.view.addSubview(gatesTVCNavigationVC.view)
    
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                
                self.gatesTVCNavigationVC.view.alpha = 1
                self.noGatesMessageVC.view.alpha = 1

                
                if Model.shared.gates() != nil {
                    self.noGatesMessageVC.view.alpha = 0
                }
            })
    }
    
    func presentWelcomeMessage() {
        
        let frame = CGRect(x: 0,y: 56, width: self.view.bounds.width, height: self.view.bounds.height)
        noGatesMessageVC.view.frame = frame
        self.addChildViewController(noGatesMessageVC)
        self.view.addSubview(noGatesMessageVC.view)
        self.view.bringSubview(toFront: noGatesMessageVC.view)
        noGatesMessageVC.didMove(toParentViewController: self)
    }
    
    func hideNoMessageVCIfNeeded() {
        let gates = Model.shared.gates()
        if gates != nil && gates?.count != 0{
            self.noGatesMessageVC.view.alpha = 0
        }
    }
    
    func showNoMessageVCIfNeeded() {
        
        
        let gates = Model.shared.gates()
        
        if gates == nil || gates?.count == 0 {

            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                self.noGatesMessageVC.view.alpha = 1
                self.noGatesMessageVC.showNoGatesMessage()
            })
        
        }
    }
    
    func toogleSleepMode() {
        
        sleepMode = true
        UserDefaults.standard.set(true, forKey: kSleepModeKey)
        //update model
        Model.shared.stopLocationUpdates()
        UIApplication.shared.isIdleTimerDisabled = false
        
        //updateUI
        UIView.animate(withDuration: 0.8, animations: { () -> Void in
            
            self.dimmingView.alpha = 0.8
            self.sleepModeMessageView.alpha = 1
            self.view.bringSubview(toFront: self.dimmingView)
            self.view.bringSubview(toFront: self.sleepModeMessageView)
            
        }, completion: { (completed) -> Void in
            
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                
                self.sleepMessageTopConstraint.constant = self.kSleepMessageVisibleConstant
                self.view.layoutIfNeeded()
                self.wakeUpButton.alpha = 1
                
            }, completion: { (finished) -> Void in
                
            })
            
        }) 
    }
    
    @IBAction func wakeUpFromSleepMode() {
        
        sleepMode = false
        UserDefaults.standard.set(false, forKey: kSleepModeKey)

        //update model
        Model.shared.startLocationUpdates()
        UIApplication.shared.isIdleTimerDisabled = true
        
        //updateUI
        UIView.animate(withDuration: 0.8, animations: { () -> Void in
            
          
            self.sleepMessageTopConstraint.constant = self.kSleepMessageHiddenConstant
            self.view.layoutIfNeeded()
            self.wakeUpButton.alpha = 0

         
            
            }, completion: { (completed) -> Void in
                
                UIView.animate(withDuration: 0.4, animations: { () -> Void in
                    
                    self.dimmingView.alpha = 0
                    self.sleepModeMessageView.alpha = 0

                    
                    
                    }, completion: { (finished) -> Void in
                        
                })
        }) 
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        noGatesMessageVC = nil
    }

}

