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
    
    lazy var noGatesMessageVC : UIViewController!  = {
        return self.storyboard?.instantiateViewControllerWithIdentifier("noGatesMessageVC") as! NoGatesVC
        }()
    
    lazy var gatesTVCNavigationVC: UINavigationController! = {
        return self.storyboard?.instantiateViewControllerWithIdentifier("GatesTVCNavController")
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
        self.wakeUpButton.layer.borderColor = UIColor.whiteColor().CGColor
        self.wakeUpButton.layer.borderWidth = 1
        self.wakeUpButton.layer.cornerRadius = 10
        
        presentWelcomeMessage()
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(2 * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
            
            self.presentGatesTVC()
        })        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if sleepMode {
            wakeUpFromSleepMode()
        }
    }
    
    func presentGatesTVC() {
    
            gatesTVCNavigationVC.view.alpha = 0
            self.addChildViewController(gatesTVCNavigationVC)
            gatesTVCNavigationVC.view.frame = self.view.bounds
            gatesTVCNavigationVC.didMoveToParentViewController(self)
            self.view.addSubview(gatesTVCNavigationVC.view)
    
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                
                self.gatesTVCNavigationVC.view.alpha = 1
                
                if Model.shared.gates() != nil {self.noGatesMessageVC.view.alpha = 0}
            })
    }
    
    func presentWelcomeMessage() {
        
        var frame = CGRectMake(0,56, self.view.bounds.width, self.view.bounds.height)
        noGatesMessageVC.view.frame = frame
        self.addChildViewController(noGatesMessageVC)
        self.view.addSubview(noGatesMessageVC.view)
        self.view.bringSubviewToFront(noGatesMessageVC.view)
        noGatesMessageVC.didMoveToParentViewController(self)
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

            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.noGatesMessageVC.view.alpha = 1
            })
//            
//            gatesTVCNavigationVC.view.removeFromSuperview()
//            gatesTVCNavigationVC.removeFromParentViewController()
        
        }
    }
    
    func toogleSleepMode() {
        
        sleepMode = true
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: kSleepModeKey)
        //update model
        Model.shared.stopLocationUpdates()
        UIApplication.sharedApplication().idleTimerDisabled = false
        
        //updateUI
        UIView.animateWithDuration(0.8, animations: { () -> Void in
            
            self.dimmingView.alpha = 0.8
            self.sleepModeMessageView.alpha = 1
            self.view.bringSubviewToFront(self.dimmingView)
            self.view.bringSubviewToFront(self.sleepModeMessageView)
            
        }) { (completed) -> Void in
            
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                
                self.sleepMessageTopConstraint.constant = self.kSleepMessageVisibleConstant
                self.view.layoutIfNeeded()
                self.wakeUpButton.alpha = 1
                
            }, completion: { (finished) -> Void in
                
            })
            
        }
    }
    
    @IBAction func wakeUpFromSleepMode() {
        
        sleepMode = false
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: kSleepModeKey)

        //update model
        Model.shared.startLocationUpdates()
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        //updateUI
        UIView.animateWithDuration(0.8, animations: { () -> Void in
            
          
            self.sleepMessageTopConstraint.constant = self.kSleepMessageHiddenConstant
            self.view.layoutIfNeeded()
            self.wakeUpButton.alpha = 0

         
            
            }) { (completed) -> Void in
                
                UIView.animateWithDuration(0.4, animations: { () -> Void in
                    
                    self.dimmingView.alpha = 0
                    self.sleepModeMessageView.alpha = 0

                    
                    
                    }, completion: { (finished) -> Void in
                        
                })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        noGatesMessageVC = nil
    }

}

