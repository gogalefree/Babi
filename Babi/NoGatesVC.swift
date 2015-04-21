//
//  NoGatesVC.swift
//  Babi
//
//  Created by Guy Freedman on 4/14/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import Foundation

class NoGatesVC: UIViewController {
    
    @IBOutlet weak var messageLable: UILabel!

    let noGatesMessage = String.localizedStringWithFormat("Hi BaBi,\n You have no gates yet.", "a title saying that the user has no gates yet")
    
    let helloMessage1 = String.localizedStringWithFormat("Hi BaBi,\n Whats Up?", "a title saying hello to the user")
    let helloMessage2 = String.localizedStringWithFormat("Hi BaBi,\n Where to?", "a title saying hello to the user")
    let helloMessage3 = String.localizedStringWithFormat("Hi BaBi,\n have a nice trip.", "a title saying hello to the user")
    let helloMessage4 = String.localizedStringWithFormat("Hi BaBi,\n Drive safe.", "a title saying hello to the user")
    let helloMessage5 = String.localizedStringWithFormat("Hi BaBi,\n Have fun!" , "a title saying hello to the user")
    
    var messages = [String]()
    
    
    override func viewDidLoad() {
       
        super.viewDidLoad()
        
        let gates = Model.shared.gates()
        messages = [helloMessage1 , helloMessage2, helloMessage3, helloMessage4, helloMessage5]
        
        if gates == nil || gates?.count == 0 {
            self.messageLable.text = noGatesMessage
        }
        else {
            self.messageLable.text = generateHelloMessage()
        }
    }
    
    func generateHelloMessage() -> String {
        
        let random = Int(arc4random_uniform(5))
        return messages[random]
    }
    
    func showNoGatesMessage() {
        self.messageLable.alpha = 0
        self.messageLable.text = noGatesMessage
        self.messageLable.animateToAlphaWithSpring(0.4, alpha: 1)
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
