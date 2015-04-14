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

    let message = String.localizedStringWithFormat("Hi BaBi,\n You have no gates yet.", "a title saying that the user has no gates yet")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageLable.text = ""//message
    }
 }
