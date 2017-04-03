//
//  GateEditorAutomaticCell.swift
//  Babi
//
//  Created by Guy Freedman on 4/4/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import Material

protocol GateAutomaticCellDelegate: NSObjectProtocol {
    func didChangeGateAutomaticMode(_ isAutomatic: Bool)
}

class GateEditorAutomaticCell: UITableViewCell, SwitchDelegate {

    @IBOutlet weak var autoSwitch: Switch!
    @IBOutlet weak var titleLabel: UILabel!
   
    weak var delegate: GateAutomaticCellDelegate!
    
    var gate : Gate! {
        didSet{
            defineTitle()
            
            let switchState: SwitchState = gate.automatic ? .on : .off
            autoSwitch.setSwitchState(state: switchState, animated: false, completion: nil)
        }
    }
    
    var titles = ["Automaticaly opens the gate When you're close","Call Manually"]

    override func awakeFromNib() {
       
        super.awakeFromNib()
        autoSwitch.delegate = self
        autoSwitch.switchSize = .medium
        titleLabel.text = titles[1]
//        automaticSwitch.layer.borderColor = UIColor.black.cgColor
//        automaticSwitch.layer.borderWidth = 1
//        automaticSwitch.layer.cornerRadius = 15
    }
    
    
    func defineTitle() {
        
        if !gate.automatic {
            animateTitle(titles[1])
        }
        else {
            animateTitle(titles[0])
            
        }
    }

    func animateTitle(_ title: String) {
        titleLabel.animateToAlphaWithSpring(0.4, alpha: 0)
        titleLabel.text = title
        titleLabel.animateToAlphaWithSpring(0.4, alpha: 1)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func switchDidChangeState(control: Switch, state: SwitchState) {
        
        let on = state == .on
        control.setSwitchState(state: state, animated: true, completion: nil)
        gate.automatic = on
        if let delegate = delegate {
            delegate.didChangeGateAutomaticMode(gate.automatic)
        }        
    }
}
