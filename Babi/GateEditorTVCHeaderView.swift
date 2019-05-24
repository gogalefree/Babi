//
//  GateEditorTVCHeaderView.swift
//  Babi
//
//  Created by Guy Freedman on 3/31/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import Material

protocol GateEditorHeaderViewDelegate: NSObjectProtocol {
    func headerTapped(_ headerView: GateEditorTVCHeaderView)
}

let initialTitles = ["Name" , "Phone Number" , "Location" , "Automatic"]
let locationHeaderTitles = ["Gate Location" , "Location: Defined"]
let automaticHeaderTitles = ["Manual" , "Automatic"]
let automaticHeaderIcons =  [Icon.cm.pause , Icon.cm.play]
let automaticHeaderTintColors = [ UIColor.gray , #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1)]

class GateEditorTVCHeaderView: UIView, UIGestureRecognizerDelegate, UITextFieldDelegate {

   
    enum Roll: Int {
        case gateName = 0, gatePhoneNumber = 1, gateLocation = 2, gateMode = 3
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField:  TextField!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
   
    @objc var selected = false
    @objc let digits = "0123456789-"

    
    var section: Int!
    
    weak var delegate: GateEditorHeaderViewDelegate!

    var headerRoll: Roll! {
        didSet {
            setInitialTitles()
        }
    }
    
    @objc var gate: Gate?
    
    @objc func setInitialTitles() {
        
        titleLabel.textColor = UIColor.gray
        titleLabel.text = initialTitles[section]

        if self.headerRoll == .gateMode {
            titleLabel.textColor = UIColor.darkGray
            iconImageView.image = Icon.cm.play
        }
            
        else if self.headerRoll == .gateName{

            iconImageView.image = UIImage(named: "ic_edit.png")!.withRenderingMode(
                UIImageRenderingMode.alwaysTemplate)
        }
        
        else if headerRoll ==  .gatePhoneNumber {
            iconImageView.image = UIImage(named:"ic_phone.png")!.withRenderingMode(
                UIImageRenderingMode.alwaysTemplate)
        }
        
        else if self.headerRoll == .gateLocation {
            iconImageView.image = UIImage(named: "ic_near_me.png")!.withRenderingMode(
                UIImageRenderingMode.alwaysTemplate)
        }
        
        setIconTintColor()
    }
    
    @objc func setGateTitles(_ gate: Gate) {
        
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
         let automaticState = gate.automatic.hashValue
         let automaticValue = automaticState < 2 ? automaticState : 0
            titleLabel.text = automaticHeaderTitles[automaticValue]
            iconImageView.image = automaticHeaderIcons[automaticValue]?.tint(with: automaticHeaderTintColors[automaticValue])
        }
    }

    
    @objc func headerTapped(_ recognizer: UITapGestureRecognizer) {
        
        selected = !selected
        //animateIcon()
        
        if selected {setSelectedState()}
        else        {setIdeleState()}

        if let delegate = delegate {delegate.headerTapped(self)}
    }
    
    @objc func setSelectedState() {
        
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
    
    @objc func setIdeleState() {
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
        
        setIconTintColor()
       // animateIcon()
    }
    
    @objc func saveGateData() {
       
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
    
    @objc func animateNewText(_ text: String?) {
        
      
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
    
    @objc func showTextField() {
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.textField.alpha = 1
            self.titleLabel.alpha = 0
        }, completion: { (completion) -> Void in
            _ = self.textField.becomeFirstResponder()
        }) 
    }
    
    @objc func hideTextField() {
        UIView.animate(withDuration: 0.4, animations: { () -> Void in
            self.textField.alpha = 0
            self.titleLabel.alpha = 1
            self.textField.resignFirstResponder()
        })
    }
    
    @objc func animateIcon() {
        
        if selected && self.headerRoll == .gateMode{
            
            UIView.animate(withDuration: 0.4, animations: {
                
                self.iconImageView.transform =  CGAffineTransform(rotationAngle: (180.0 * CGFloat.pi) / 180.0)
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
        
    
        textField.clearButtonMode = .whileEditing
        textField.isVisibilityIconButtonEnabled = false
        textField.isSecureTextEntry = false
    }
    
    @objc func setIconTintColor() {
        
        
        var tintColor = UIColor.black
        
        guard  let gate = self.gate else {
            self.iconImageView.tintColor = tintColor
         if self.headerRoll == .gateMode {
            self.iconImageView.tintColor = .green
            
         }
            return
        }
        
        
        switch headerRoll as Roll{
            
        case .gateName:
            if gate.name != kGateNameDefaultValue && gate.name != initialTitles[0] {
                tintColor = .green
            }
        case .gatePhoneNumber:
            if gate.phoneNumber != kGatePhoneNumberDefaultValue && gate.phoneNumber != initialTitles[1] {
                tintColor = .green
            }
            
        case .gateLocation:
            if gate.latitude != kGateLatitudeDefaultValue && gate.longitude != kGateLongitudeDefaultValue{
                tintColor = .green
            }
         
        case .gateMode:
         tintColor = .green
            }
        
        self.iconImageView.tintColor = tintColor
    }
}
