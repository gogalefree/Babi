//
//  GatesTVCell.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import Material

protocol SwipeableCellDelegate{
    func settingsButtonAction(_ cell: SwipeableCellTableViewCell)
    func automaticButtonAction(_ cell: SwipeableCellTableViewCell)
    func shareButtonClicked(_ cell: SwipeableCellTableViewCell)
    func callActionAsGuest(_ cell: SwipeableCellTableViewCell)
    func presentSharesPopup(indexPath: IndexPath)
    func cellDidOpen(_ cell: UITableViewCell)
    func cellDidClose(_ cell: UITableViewCell)
}

class SwipeableCellTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var invitationsButton: IconButton!
    @IBOutlet weak var invitationsCounterLabel: UILabel!
    @IBOutlet weak var actionsView: UIView!
    @IBOutlet weak var verticalDeviderView: UIView!
    @IBOutlet weak var topDeviderView: UIView!
    @IBOutlet weak var bottomDeviderView: UIView!
    @IBOutlet weak var distanceUnitLabel: UILabel!
    @IBOutlet weak var distanceNumberLabel: UILabel!
    @IBOutlet weak var button1: UIButton!
    // @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: IconButton!
    @IBOutlet weak var myContentView: UIView!
    @IBOutlet weak var myTextLable: UILabel!
    @IBOutlet weak var contentViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var arrowImageView: UIImageView!
    var callButton: IconButton!
    var guestButton: FlatButton!
    let automaticColor = UIColor.black// UIColor(red: 134.0/255.0, green: 46.0/255.0, blue: 73.0/255.0, alpha: 0.9)
    let manualColor = UIColor.black
    let deviderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    let numberColor = #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)
    var automaticButton: IconButton!
    var panRecognizer: UIPanGestureRecognizer!
    var panStartPoint: CGPoint!
    var startingRightLayoutConstraintConstant: CGFloat! = -8
    let kBounceValue: CGFloat = 20.0
    var isOpen: Bool = false {
        didSet{
            print("gate open: \(isOpen)")
        }
    }
    
    var gate: Gate!{
        didSet{
            
            if !gate.isGuest {
                setupAsOwner()
            }
            
            else {
                setupAsGuest()
            }
        }
    }
    
    func setupAsOwner() {
        invitationsCounterLabel.layer.cornerRadius = 10
        invitationsCounterLabel.text = String(gate!.shares.count)
        let alpha: CGFloat = gate!.shares.isEmpty ? 0.0 : 1.0
        invitationsButton.alpha = alpha
        invitationsCounterLabel.alpha = alpha
        button3.alpha = 1
        let button1Image = UIImage(named: "settings-64")
        button1.setImage(button1Image, for: .normal)
        guestButton?.alpha = 0
        prepareActionsView()
    }
    
    func setupAsGuest() {
        invitationsButton.alpha = 0
        invitationsCounterLabel.alpha = 0
        button3.alpha = 0
        let button1Image = UIImage(named: "ic_delete.png")
        button1.setImage(button1Image, for: .normal)
        
        if guestButton == nil {
          
            guestButton = FlatButton(title: "Guest", titleColor: #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1))
            guestButton.frame = invitationsButton.frame
            guestButton.frame.size = CGSize(width: 80, height: 40)
            guestButton.frame.origin.x = (verticalDeviderView.x - 80) / 2
            myContentView.addSubview(guestButton)
        }
        
        guestButton.alpha = 1
        prepareActionsView()
    }
    
    var delegate: SwipeableCellDelegate?
    var indexPath: IndexPath!
    var itemText: String? {
        didSet {
            
            if let text = itemText {
                self.myTextLable.text = text
            }
        }
    }
    
    //Mark: Button Actions

    @IBAction func buttonClicked(_ sender: UIButton) {
        
        if let delegate = self.delegate {
            
            
            if sender == self.button1 {
                //settings
                delegate.settingsButtonAction(self)
            }
                
                
            else if sender == self.button3 {
                //share Button
                delegate.shareButtonClicked(self)
            }
        }
    }
    
    func presentSharesPopup() {
        print(#function + "present popup in gates cell")
        delegate?.presentSharesPopup(indexPath: indexPath)
    }
    
    func automaticButtonAction() {
        
        let image = gate.automatic == true ? Icon.cm.pause : Icon.cm.play
        automaticButton.animateToAlphaWithSpring(0.1, alpha: 0)
        automaticButton.image = image
        automaticButton.animateToAlphaWithSpring(0.1, alpha: 1)
        delegate?.automaticButtonAction(self)
        setAutomaticButtonTint()
    }
    
    func verticalMenuAction() {
        if self.isOpen {
            resetConstraintContstantsToZero(true, notifyDelegateDidClose: true)
        } else {
            setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: true)
        }
    }
    
    func callButtonAction() {
        
        if self.gate.isGuest {
          
            delegate?.callActionAsGuest(self)
            return
        }
        
        PhoneDialer.callGate(gate?.phoneNumber)
    }
        
    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetConstraintContstantsToZero(false ,notifyDelegateDidClose:false)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipeableCellTableViewCell.panThisCell(_:)))
        self.panRecognizer.delegate = self;
        self.myContentView.addGestureRecognizer(self.panRecognizer)
        topDeviderView.backgroundColor = deviderColor
        bottomDeviderView.backgroundColor = deviderColor
        distanceNumberLabel.textColor = numberColor
        distanceUnitLabel.textColor = numberColor
        button3.image = Icon.cm.share
        button3.tintColor = .black
       // prepareActionsView()
    }
    
    private func prepareActionsView() {
        
        let shareButton = IconButton(image: Icon.cm.moreVertical)
        let automaticButton = IconButton(image: Icon.cm.play)
        let callButton = IconButton(image: UIImage(named:"ic_phone.png")!.withRenderingMode(
            UIImageRenderingMode.alwaysTemplate))
        self.callButton = callButton
        self.automaticButton = automaticButton

        //buttons layout
        actionsView.layout.vertically(shareButton, top: 0, bottom: 0)
        actionsView.layout.vertically(automaticButton, top: 0, bottom: 0)
        actionsView.layout.vertically(callButton, top: 0, bottom: 0)
        actionsView.layout.horizontally([automaticButton, callButton, shareButton], left: 5, right: 5, interimSpace: 5)
        
        //button actions
        shareButton.addTarget(self, action: #selector(verticalMenuAction), for: .touchUpInside)
        automaticButton.addTarget(self, action: #selector(automaticButtonAction), for: .touchUpInside)
        callButton.addTarget(self, action: #selector(callButtonAction), for: .touchUpInside)
        invitationsButton.addTarget(self, action: #selector(presentSharesPopup), for: .touchUpInside)
        
        callButton.tintColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        shareButton.tintColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        setAutomaticButtonTint()
        invitationsButton.image = Icon.cm.share
        
        let callButtonAlpha: CGFloat = self.gate.isGuest == true ? 0 : 1
        callButton.alpha = callButtonAlpha
        
    }
    
    func setAutomaticButtonTint() {
        print("automatic: " + String(describing: gate?.automatic))
        let tint  = gate?.automatic == false ? UIColor.gray : #colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1)
        automaticButton.tintColor = tint
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
