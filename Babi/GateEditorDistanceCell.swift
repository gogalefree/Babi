//
//  GateEditorDistanceCell.swift
//  Babi
//
//  Created by Guy Freedman on 4/9/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

class GateEditorDistanceCell: UITableViewCell {
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var stepper: UIStepper!
    
    
    @objc var gate: Gate? {
        didSet{ if let gate = gate{
            self.updateLabel()
            self.stepper.value = Double(gate.fireDistanceFromGate)
            }
        }
    }
    
    @objc func updateLabel() {
        
        self.distanceLabel.text = "\(gate!.fireDistanceFromGate)"
    }
    
    @objc func stepperPressed(){
        
        self.gate?.fireDistanceFromGate = Int(stepper.value)
        updateLabel()
    }
    
    @objc func configButtons() {
        
        stepper.addTarget(self, action: #selector(GateEditorDistanceCell.stepperPressed), for: UIControlEvents.valueChanged)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configButtons()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
        // Configure the view for the selected state
    }

}
