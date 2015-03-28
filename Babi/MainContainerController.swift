//
//  ViewController.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

class MainContainerController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let gatesTVC = self.storyboard?.instantiateViewControllerWithIdentifier("GatesTVCNavController")
        as UINavigationController!
        self.addChildViewController(gatesTVC)
        gatesTVC.view.frame = self.view.bounds
        gatesTVC.didMoveToParentViewController(self)
        self.view.addSubview(gatesTVC.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

