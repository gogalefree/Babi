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
        return self.storyboard?.instantiateViewControllerWithIdentifier("noGatesMessageVC") as UIViewController
        }()
    
    var presentingNoGatesMessage = false


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let gatesTVC = self.storyboard?.instantiateViewControllerWithIdentifier("GatesTVCNavController")
        as UINavigationController!
        self.addChildViewController(gatesTVC)
        gatesTVC.view.frame = self.view.bounds
        gatesTVC.didMoveToParentViewController(self)
        self.view.addSubview(gatesTVC.view)
        
        noGatesMessageIfNeeded()

    }

    func noGatesMessageIfNeeded() {
        
        let gates = Model.shared.gates()
        
        if gates == nil || gates?.count == 0 {
            
            var frame = CGRectMake(0,64, self.view.bounds.width, self.view.bounds.height)
            noGatesMessageVC.view.frame = frame
            self.addChildViewController(noGatesMessageVC)
            self.view.addSubview(noGatesMessageVC.view)
            self.view.bringSubviewToFront(noGatesMessageVC.view)
            noGatesMessageVC.didMoveToParentViewController(self)
            presentingNoGatesMessage = true
        }
    }
    
    func removeNoGatesMessageIfNeeded() {
        println("no gates message removed")
        if presentingNoGatesMessage {
            noGatesMessageVC.view.removeFromSuperview()
            noGatesMessageVC.removeFromParentViewController()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        noGatesMessageVC = nil
    }

}

