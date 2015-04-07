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

var initialTitles = ["Gate Name" , "Gate Phone Number" , "Gate Location: Current Location" , "Automatic"]

class GateEditorTVCHeaderView: UIView, UIGestureRecognizerDelegate {

   
    enum Roll: Int {
        case GateName = 0, GatePhoneNumber = 1, GateLocation = 2, GateMode = 3
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    
    
    var section: Int!
    
    weak var delegate: GateEditorHeaderViewDelegate!

    var headerRoll: Roll! {
        didSet {
            setInitialTitles()
        }
    }
    
    func setInitialTitles() {
        
        titleLabel.textColor = UIColor.grayColor()
        titleLabel.text = initialTitles[section]
        
        switch headerRoll as Roll {
        case .GateMode , .GateLocation:
            titleLabel.textColor = UIColor.blackColor()
            var color = UIColor.greenColor().colorWithAlphaComponent(0.1)
            self.backgroundColor = color
        default:
            var color = UIColor.orangeColor().colorWithAlphaComponent(0.1)
            self.backgroundColor = color
            break

        }
        
    }
    
    func headerTapped(recognizer: UITapGestureRecognizer) {
        self.delegate.headerTapped(self)
    }
    
    func animateNewText(text: String?) {
        
       // titleLabel.animateToAlphaWithSpring(0.4, alpha: 0)
      
        if text == nil || text == "" {
            setInitialTitles()
        }
        else {
            titleLabel.textColor = UIColor.blackColor()
            titleLabel.text = text
            var color = UIColor.greenColor().colorWithAlphaComponent(0.1)
            self.backgroundColor = color
        }

//        titleLabel.animateToAlphaWithSpring(0.4, alpha: 1)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tapGestureRecognizer.addTarget(self, action: "headerTapped:")
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 66))
        }
    
}
