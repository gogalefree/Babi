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

let initialTitles = ["Gate Name" , "Gate Phone Number" , "Gate Location: Current Location" , "Automatic"]

let locationHeaderTitles = ["Location: Current Location" , "Location: Defined"]

let automaticHeaderTitles = ["Manual" , "Automatic"]


class GateEditorTVCHeaderView: UIView, UIGestureRecognizerDelegate {

   
    enum Roll: Int {
        case GateName = 0, GatePhoneNumber = 1, GateLocation = 2, GateMode = 3
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    var expanded = false
    
    
    var section: Int!
    
    weak var delegate: GateEditorHeaderViewDelegate!

    var headerRoll: Roll! {
        didSet {
            setInitialTitles()
        }
    }
    
    var gate: Gate? {
        didSet {
            if let gate = gate {
                setGateTitles(gate)
            }
        }
    }
    
    func setInitialTitles() {
        
        titleLabel.textColor = UIColor.grayColor()
        titleLabel.text = initialTitles[section]
        
        switch headerRoll as Roll {
        case .GateMode , .GateLocation:
            titleLabel.textColor = UIColor.darkGrayColor()
           
        default:
            break

        }
    }
    
    func setGateTitles(gate: Gate) {
        
        titleLabel.textColor = UIColor.darkGrayColor()
        
        switch headerRoll as Roll {
        case .GateName:
            titleLabel.text = gate.name
        case .GatePhoneNumber:
            titleLabel.text = gate.phoneNumber
        case .GateLocation:
            titleLabel.text = locationHeaderTitles[1]
        case .GateMode:
            titleLabel.text = automaticHeaderTitles[gate.automatic.hashValue]
        }
    }

    
    func headerTapped(recognizer: UITapGestureRecognizer) {
        self.delegate.headerTapped(self)
        expanded = !expanded
        if expanded {
            
            UIView.animateWithDuration(0.4, animations: {
            
            self.iconImageView.transform =  CGAffineTransformMakeRotation((180.0 * CGFloat(M_PI)) / 180.0)
            })
        }
        else {
            
            UIView.animateWithDuration(0.4, animations: {
                
                self.iconImageView.transform =  CGAffineTransformIdentity
            })
        }
    }
    
    func animateNewText(text: String?) {
        
      
        if text == nil || text == "" {
            setInitialTitles()
        }
        else {
            titleLabel.textColor = UIColor.darkGrayColor()
            titleLabel.text = text
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tapGestureRecognizer.addTarget(self, action: "headerTapped:")
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 66))
        
        }
    
}
