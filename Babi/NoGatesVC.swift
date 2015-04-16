//
//  NoGatesVC.swift
//  Babi
//
//  Created by Guy Freedman on 4/14/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

class NoGatesVC: UIViewController {
    
    @IBOutlet weak var messageLable: UILabel!

    let noGatesMessage = String.localizedStringWithFormat("Hi BaBi,\n You have no gates yet.", "a title saying that the user has no gates yet")
    
    let helloMessage = String.localizedStringWithFormat("Hi BaBi,\n Whats Up?.", "a title saying hello to the user")
    
    
    
    override func viewDidLoad() {
       
        super.viewDidLoad()
        
        let gates = Model.shared.gates()
        
        if gates == nil || gates?.count == 0 {
            self.messageLable.text = noGatesMessage
        }
        else {
            self.messageLable.text = helloMessage
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.messageLable.alpha = 0
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.messageLable.alpha = 1
        })
    }
 }
