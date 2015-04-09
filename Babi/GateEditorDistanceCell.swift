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

    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!

    
    var gate: Gate? {
        didSet{ if let gate = gate{ self.updateLabel()}}
    }
    
    
    @IBAction func addOneMeter(sender: UIButton) {
    
        if let gate = gate {
            var currentDistance = gate.fireDistanceFromGate
            currentDistance++
            gate.fireDistanceFromGate = currentDistance
            updateLabel()
        }
    }
    
    @IBAction func reduceOneMeter(sender: UIButton) {
        
        if let gate = gate {
            var currentDistance = gate.fireDistanceFromGate
            currentDistance--
            gate.fireDistanceFromGate = currentDistance
            updateLabel()
        }
    }
    
    func updateLabel() {
        self.distanceLabel.text = "\(gate!.fireDistanceFromGate)"
    }
    
    func configButtons() {
        plusButton.layer.cornerRadius = 10
        plusButton.layer.borderColor = UIColor.blackColor().CGColor
        plusButton.layer.borderWidth = 1
        
        minusButton.layer.cornerRadius = 10
        minusButton.layer.borderColor = UIColor.blackColor().CGColor
        minusButton.layer.borderWidth = 1
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
