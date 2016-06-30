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
    
    
    var gate: Gate? {
        didSet{ if let gate = gate{
            self.updateLabel()
            self.stepper.value = Double(gate.fireDistanceFromGate)
            }
        }
    }
    
    func updateLabel() {
        
        self.distanceLabel.text = "\(gate!.fireDistanceFromGate)"
    }
    
    func stepperPressed(){
        
        self.gate?.fireDistanceFromGate = Int(stepper.value)
        updateLabel()
    }
    
    func configButtons() {
        
        stepper.addTarget(self, action: #selector(GateEditorDistanceCell.stepperPressed), forControlEvents: UIControlEvents.ValueChanged)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configButtons()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
        // Configure the view for the selected state
    }

}
