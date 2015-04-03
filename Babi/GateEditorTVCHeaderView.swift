//
//  GateEditorTVCHeaderView.swift
//  Babi
//
//  Created by Guy Freedman on 3/31/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

protocol GateEditorHeaderViewDelegate: NSObjectProtocol {
    func headerTapped(headerView: GateEditorTVCHeaderView)
}

class GateEditorTVCHeaderView: UIView, UIGestureRecognizerDelegate {

   
    enum Roll: Int {
        case GateName = 0, GatePhoneNumber = 1, GateLocation = 2, GateMode = 3
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    weak var delegate: GateEditorHeaderViewDelegate!

    var headerRoll: Roll! {
        didSet {
            setInitialTitles()
        }
    }
    
    func setInitialTitles() {
    
        switch headerRoll as Roll {
            
        case .GateName(let title):
            titleLabel.text = "Gate Name"
        case .GatePhoneNumber:
            titleLabel.text = "Gate Phone Number"
        case .GateLocation:
            titleLabel.text = "Gate Location: Current Location"
        case .GateMode:
            titleLabel.text = "Gate Mode"
        }
        
        titleLabel.textColor = UIColor.grayColor()
    }
    
    func headerTapped(recognizer: UITapGestureRecognizer) {
        self.delegate.headerTapped(self)
    }
    
    func animateNewText(text: String?) {
        
     //   titleLabel.animateToAlphaWithSpring(0.3, alpha: 0)
      
        if text == nil || text == "" {
            setInitialTitles()
        }
        else {
            titleLabel.textColor = UIColor.blackColor()
            titleLabel.text = text
        }

       // titleLabel.animateToAlphaWithSpring(0.3, alpha: 1)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tapGestureRecognizer.addTarget(self, action: "headerTapped:")
    }
    
}
