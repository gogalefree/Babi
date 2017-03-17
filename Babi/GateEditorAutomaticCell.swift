//
//  GateEditorAutomaticCell.swift
//  Babi
//
//  Created by Guy Freedman on 4/4/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

protocol GateAutomaticCellDelegate: NSObjectProtocol {
    func didChangeGateAutomaticMode(_ isAutomatic: Bool)
}

class GateEditorAutomaticCell: UITableViewCell {

    @IBOutlet weak var automaticSwitch: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
   
    weak var delegate: GateAutomaticCellDelegate!
    
    var gate : Gate! {
        didSet{
            defineTitle()
            automaticSwitch.isOn = gate.automatic
        }
    }
    
    var titles = ["Automaticaly opens the gate When you're close","Call Manually"]

    override func awakeFromNib() {
       
        super.awakeFromNib()
        automaticSwitch.addTarget(self, action: #selector(GateEditorAutomaticCell.automaticSwitchMoved(_:)), for: UIControlEvents.valueChanged)
        titleLabel.text = titles[1]
        automaticSwitch.layer.borderColor = UIColor.black.cgColor
        automaticSwitch.layer.borderWidth = 1
        automaticSwitch.layer.cornerRadius = 15
    }
    
    func automaticSwitchMoved(_ sender: UISwitch) {
        gate.automatic = automaticSwitch.isOn
        if let delegate = delegate {
            delegate.didChangeGateAutomaticMode(gate.automatic)
        }
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

}
