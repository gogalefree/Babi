//
//  ViewController.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import Foundation

class MainContainerController: UIViewController {
    
    lazy var noGatesMessageVC : UIViewController!  = {
        return self.storyboard?.instantiateViewControllerWithIdentifier("noGatesMessageVC") as! NoGatesVC
        }()
    
    lazy var gatesTVCNavigationVC: UINavigationController! = {
        return self.storyboard?.instantiateViewControllerWithIdentifier("GatesTVCNavController")
            as! UINavigationController!
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        presentWelcomeMessage()
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(2 * Double(NSEC_PER_SEC)))
        
        dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
            
            self.presentGatesTVCIfNeeded()
        })        
    }
    
    func presentGatesTVCIfNeeded() {
        
        let gates = Model.shared.gates()
        
        if let gates = gates {
            
            if gates.count > 0 {
                
                self.addChildViewController(gatesTVCNavigationVC)
                gatesTVCNavigationVC.view.frame = self.view.bounds
                gatesTVCNavigationVC.didMoveToParentViewController(self)
                self.view.addSubview(gatesTVCNavigationVC.view)
                self.noGatesMessageVC.view.alpha = 0
            }
        }
    }
    
    func presentWelcomeMessage() {
        
        var frame = CGRectMake(0,56, self.view.bounds.width, self.view.bounds.height)
        noGatesMessageVC.view.frame = frame
        self.addChildViewController(noGatesMessageVC)
        self.view.addSubview(noGatesMessageVC.view)
        self.view.bringSubviewToFront(noGatesMessageVC.view)
        noGatesMessageVC.didMoveToParentViewController(self)
    }
    
    
    func removeGatesTVCIfNeeded() {
        
        println("gates tvc removed")
        
        let gates = Model.shared.gates()
        
        if gates == nil || gates?.count == 0 {

            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.noGatesMessageVC.view.alpha = 1
            })
            
            gatesTVCNavigationVC.view.removeFromSuperview()
            gatesTVCNavigationVC.removeFromParentViewController()
        
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        noGatesMessageVC = nil
    }

}

