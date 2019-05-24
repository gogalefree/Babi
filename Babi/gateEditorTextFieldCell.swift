//
//  gateEditorTextFieldCell.swift
//  Babi
//
//  Created by Guy Freedman on 4/1/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

let kGateEditorGateNameTitle = String.localizedStringWithFormat("Enter Gate Name", "a title explaining that the user should enter a name for the gate")
let kGateEditorPhoneNumberTitle = String.localizedStringWithFormat("Gate phone number. digits only.", "a title explaining that the user should enter a phone number for the gate")

protocol GateEditorTextFieldCellDeleagte: NSObjectProtocol {
    func didFinishEditingText(_ text: String?,indexpath: IndexPath)
    func editingText(_ text: String, indexpath: IndexPath)
}

class gateEditorTextFieldCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    
    var titles: [String] =
    [String.localizedStringWithFormat("Enter Gate Name", "a title explaining that the user should enter a name for the gate"),
    String.localizedStringWithFormat("Gate phone number. digits only.", "a title explaining that the user should enter a phone number for the gate")]
    let digits = "0123456789"
    
    weak var delegate: GateEditorTextFieldCellDeleagte!
    
    var indexPath: IndexPath! {
        didSet{
            titleLabel.text = titles[indexPath.section]
        }
    }
    
    //MARK: - Text Field Delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let delegate = delegate {
            //deleting chars
            delegate.didFinishEditingText(textField.text, indexpath: indexPath)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var shouldChange = true
        
        guard let text = textField.text else {return shouldChange}
        
        //validate phone number - digits only
        if indexPath.section == 1 {
            
            let newLength = (text as NSString).length + (string as NSString).length - range.length
            
            let digitsCharecterSet = CharacterSet(charactersIn: digits).inverted
            
            let components = string.components(separatedBy: digitsCharecterSet)
            
            let filtered = components.joined(separator: "")
            
            shouldChange =  string == filtered && newLength <= 10
        }

        
        let currentString = text + string
        if let delegate = delegate {
            if shouldChange {
                delegate.editingText(currentString, indexpath: indexPath)
            }
        }
        
        
        //deleting chars
        if string == "" {
            let str = String(text[...text.endIndex])
            delegate.editingText(str, indexpath: indexPath)
        }
        
        return shouldChange
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.textField.text = ""
        return true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
