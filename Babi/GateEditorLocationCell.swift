//
//  GateEditorLocationCell.swift
//  Babi
//
//  Created by Guy Freedman on 4/1/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

protocol GateEditorLocationCellDelegate: NSObjectProtocol {
    func didRequestMapView()
}

class GateEditorLocationCell: UITableViewCell {

    @IBOutlet weak var mapViewButton: UIButton!
    
    weak var delegate: GateEditorLocationCellDelegate!
    
    var initialTitle = String.localizedStringWithFormat("Choose a different location", "tells the user to chose a different location")
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mapViewButton.titleLabel?.text = initialTitle
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func buttonTapped() {
        if let dlelegate = delegate {
            delegate.didRequestMapView()
        }
    }
}
