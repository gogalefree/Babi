//
//  GateEditorTVCHeaderView.swift
//  Babi
//
//  Created by Guy Freedman on 3/31/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

protocol GateEditorHeaderViewDelegate: NSObjectProtocol {
    func headerTapped(_ headerView: GateEditorTVCHeaderView)
}

let initialTitles = ["Gate Name" , "Gate Phone Number" , "Gate Location" , "Automatic"]

let locationHeaderTitles = ["Gate Location" , "Location: Defined"]

let automaticHeaderTitles = ["Manual" , "Automatic"]


class GateEditorTVCHeaderView: UIView, UIGestureRecognizerDelegate, UITextFieldDelegate {

   
    enum Roll: Int {
        case gateName = 0, gatePhoneNumber = 1, gateLocation = 2, gateMode = 3
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
        
        titleLabel.textColor = UIColor.gray
        titleLabel.text = initialTitles[section]

        if self.headerRoll == .gateMode {
            titleLabel.textColor = UIColor.darkGray
        }
        else if self.headerRoll == .gateName || self.headerRoll == .gatePhoneNumber {

            iconImageView.image = UIImage(named: "ic_edit.png")
        }
        else if self.headerRoll == .gateLocation {
            iconImageView.image = UIImage(named: "ic_near_me.png")
        }
    }
    
    func setGateTitles(_ gate: Gate) {
        
        titleLabel.textColor = UIColor.darkGray
        
        switch headerRoll as Roll {
        case .gateName:
            titleLabel.text = gate.name
        case .gatePhoneNumber:
            titleLabel.text = gate.phoneNumber
        case .gateLocation:
            if gate.placemarkName != kGatePlacemarkNameDefaultValue {
                titleLabel.text = gate.placemarkName
            }
            else{
                titleLabel.text = locationHeaderTitles[1]
            }
            
        case .gateMode:
            titleLabel.text = automaticHeaderTitles[gate.automatic.hashValue]
        }
    }

    
    func headerTapped(_ recognizer: UITapGestureRecognizer) {
        
        selected = !selected
        //animateIcon()
        
        if selected {setSelectedState()}
        else        {setIdeleState()}

        if let delegate = delegate {delegate.headerTapped(self)}
    }
    
    func setSelectedState() {
        
        if self.titleLabel.text != initialTitles[section] {textField.text = titleLabel.text}
        
        switch headerRoll as Roll {

        case .gateName:
            showTextField()
            self.textField.keyboardType = .default

        case .gatePhoneNumber:
            showTextField()
            self.textField.keyboardType = .numbersAndPunctuation


        default:
            break
        }
    }
    
    func setIdeleState() {
        switch headerRoll as Roll {
        
        case .gateName, .gatePhoneNumber:
            
            if self.textField.text != "" {
                self.titleLabel.text = self.textField.text
                self.titleLabel.textColor = UIColor.darkGray
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
            case .gateName:
                gate.name = textField.text ?? ""
                print("saved gate name: \(gate.name)")
            case .gatePhoneNumber:
                gate.phoneNumber = textField.text ?? ""
                print("saved gate phone: \(gate.phoneNumber)")

            default:
                break
            }
        }
    }
    
    func animateNewText(_ text: String?) {
        
      
        if text == nil || text == "" {
            setInitialTitles()
        }
        else {
            titleLabel.textColor = UIColor.darkGray
            titleLabel.alpha = 0
            titleLabel.text = text
            titleLabel.animateToAlphaWithSpring(0.4, alpha: 1)
        }
    }
    
    func showTextField() {
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.textField.alpha = 1
            self.titleLabel.alpha = 0
        }, completion: { (completion) -> Void in
            self.textField.becomeFirstResponder()
        }) 
    }
    
    func hideTextField() {
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.textField.alpha = 0
            self.titleLabel.alpha = 1
            self.textField.resignFirstResponder()
        })
    }
    
    func animateIcon() {
        
        if selected && self.headerRoll == .gateMode{
            
            UIView.animate(withDuration: 0.4, animations: {
                
                self.iconImageView.transform =  CGAffineTransform(rotationAngle: (180.0 * CGFloat(M_PI)) / 180.0)
            })
        }
        else if self.headerRoll == .gateMode {
            
            UIView.animate(withDuration: 0.4, animations: {
                
                self.iconImageView.transform =  CGAffineTransform.identity
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        headerTapped(UITapGestureRecognizer())
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if headerRoll != .gatePhoneNumber {return true}
        
        let digitsCharecterSet = CharacterSet(charactersIn: digits).inverted
        let components = string.components(separatedBy: digitsCharecterSet)
        let filtered = components.joined(separator: "")
        var shouldChange = true
        shouldChange =  string == filtered
        return shouldChange
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.tapGestureRecognizer.addTarget(self, action: #selector(GateEditorTVCHeaderView.headerTapped(_:)))
        self.addConstraint(NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1, constant: 66))
    
        self.textField.delegate = self
        self.hideTextField()
    }
    
}
