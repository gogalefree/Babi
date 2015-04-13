//
//  GateEditorTableMainHeader.swift
//  Babi
//
//  Created by Guy Freedman on 4/13/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

class GateEditorTableMainHeader: UIView {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.lightGrayColor().CGColor
        self.clipsToBounds = true
    }
    
}
