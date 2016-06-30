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

let initialTitles = ["Gate Name" , "Gate Phone Number" , "Gate Location" , "Automatic"]

let locationHeaderTitles = ["Gate Location" , "Location: Defined"]

let automaticHeaderTitles = ["Manual" , "Automatic"]


class GateEditorTVCHeaderView: UIView, UIGestureRecognizerDelegate, UITextFieldDelegate {

   
    enum Roll: Int {
        case GateName = 0, GatePhoneNumber = 1, GateLocation = 2, GateMode = 3
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField:  UITextField!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
   
    var selected = false
    let digits = "0123456789-"

    
    var section: Int!
    
    weak var delegate: GateEditorHeaderViewDelegate!

    var headerRoll: Roll! {
        didSet {
            setInitialTitles()
        }
    }
    
    var gate: Gate?
    
    func setInitialTitles() {
        
        titleLabel.textColor = UIColor.grayColor()
        titleLabel.text = initialTitles[section]

        if self.headerRoll == .GateMode {
            titleLabel.textColor = UIColor.darkGrayColor()
        }
        else if self.headerRoll == .GateName || self.headerRoll == .GatePhoneNumber {

            iconImageView.image = UIImage(named: "pen.png")
        }
        else if self.headerRoll == .GateLocation {
            iconImageView.image = UIImage(named: "facebook30.png")
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
            if gate.placemarkName != kGatePlacemarkNameDefaultValue {
                titleLabel.text = gate.placemarkName
            }
            else{
                titleLabel.text = locationHeaderTitles[1]
            }
            
        case .GateMode:
            titleLabel.text = automaticHeaderTitles[gate.automatic.hashValue]
        }
    }

    
    func headerTapped(recognizer: UITapGestureRecognizer) {
        
        selected = !selected
        animateIcon()
        
        if selected {setSelectedState()}
        else        {setIdeleState()}

        if let delegate = delegate {delegate.headerTapped(self)}
    }
    
    func setSelectedState() {
        
        if self.titleLabel.text != initialTitles[section] {textField.text = titleLabel.text}
        
        switch headerRoll as Roll {

        case .GateName:
            showTextField()
            self.textField.keyboardType = .Default

        case .GatePhoneNumber:
            showTextField()
            self.textField.keyboardType = .NumbersAndPunctuation


        default:
            break
        }
    }
    
    func setIdeleState() {
        switch headerRoll as Roll {
        
        case .GateName, .GatePhoneNumber:
            
            if self.textField.text != "" {
                self.titleLabel.text = self.textField.text
                self.titleLabel.textColor = UIColor.darkGrayColor()
                saveGateData()
            }
                
            else {setInitialTitles()}
            hideTextField()
     
        default:
            break
        }
        
        animateIcon()
    }
    
    func saveGateData() {
       
        if let gate = gate {
            
            switch headerRoll as Roll {
            case .GateName:
                gate.name = textField.text
                print("saved gate name: \(gate.name)")
            case .GatePhoneNumber:
                gate.phoneNumber = textField.text
                print("saved gate phone: \(gate.phoneNumber)")

            default:
                break
            }
        }
    }
    
    func animateNewText(text: String?) {
        
      
        if text == nil || text == "" {
            setInitialTitles()
        }
        else {
            titleLabel.textColor = UIColor.darkGrayColor()
            titleLabel.alpha = 0
            titleLabel.text = text
            titleLabel.animateToAlphaWithSpring(0.4, alpha: 1)
        }
    }
    
    func showTextField() {
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.textField.alpha = 1
            self.titleLabel.alpha = 0
        }) { (completion) -> Void in
            self.textField.becomeFirstResponder()
        }
    }
    
    func hideTextField() {
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.textField.alpha = 0
            self.titleLabel.alpha = 1
            self.textField.resignFirstResponder()
        })
    }
    
    func animateIcon() {
        
        if selected && self.headerRoll == .GateMode{
            
            UIView.animateWithDuration(0.4, animations: {
                
                self.iconImageView.transform =  CGAffineTransformMakeRotation((180.0 * CGFloat(M_PI)) / 180.0)
            })
        }
        else if self.headerRoll == .GateMode {
            
            UIView.animateWithDuration(0.4, animations: {
                
                self.iconImageView.transform =  CGAffineTransformIdentity
            })
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        headerTapped(UITapGestureRecognizer())
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if headerRoll != .GatePhoneNumber {return true}
        
        let digitsCharecterSet = NSCharacterSet(charactersInString: digits).invertedSet
        let components = string.componentsSeparatedByCharactersInSet(digitsCharecterSet)
        let filtered = components.joinWithSeparator("")
        var shouldChange = true
        shouldChange =  string == filtered
        return shouldChange
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tapGestureRecognizer.addTarget(self, action: "headerTapped:")
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 66))
    
        self.textField.delegate = self
        self.hideTextField()
    }
    
}
