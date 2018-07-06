//
//  CardVC.swift
//  Babi
//
//  Created by Guy Freedman on 24/03/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import UIKit
import Material

protocol CardVCDelegate: NSObjectProtocol {
    func cardVCContinueAction(_ carrdVC: CardVC)
}

@objc public class CardVC: UIViewController {
    
    var sharedGate: Gate!
    var guestPhoneNumber = ""
    var guestName = ""
    var instructions = String.localizedStringWithFormat("This Invitation is valid untill you cancell it. You can do so at anytime by clicking the blue share icon in Gates screen.")
    
    var card: Card!
    weak var delegate: CardVCDelegate!
    fileprivate var toolbar: Toolbar!
    fileprivate var cancelButton: IconButton!
    fileprivate var contentView: UILabel!
    fileprivate var bottomBar: Bar!
    fileprivate var continueButton: IconButton!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        //view.backgroundColor = Color.grey.lighten5
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overCurrentContext
        prepareCrad()
    }
    
    func prepareCrad() {
        
        prepareContinueButton()
        prepareCancelButton()
        prepareToolbar()
        prepareContentView()
        prepareBottomBar()
        prepareImageCard()
    }
    
    fileprivate func prepareContinueButton() {
        continueButton = IconButton(image: Icon.cm.check, tintColor: Color.green.base)
        continueButton.addTarget(self, action: #selector(continueButtonAction), for: .touchUpInside)
    }
    
    fileprivate func prepareCancelButton() {
        cancelButton = IconButton(image: Icon.cm.close, tintColor: Color.red.base)
        cancelButton.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
    }
    
    fileprivate func prepareToolbar() {
        
        toolbar = Toolbar(rightViews: [cancelButton])
        toolbar.title = "Invite " + guestName
        toolbar.titleLabel.textAlignment = .left
        toolbar.titleLabel.font = RobotoFont.regular(with: 22)
        toolbar.detail = sharedGate.name
        toolbar.detailLabel.textAlignment = .left
        toolbar.detailLabel.textColor = Color.grey.base
        toolbar.detailLabel.font = RobotoFont.regular(with: 18)
    }
    
    fileprivate func prepareContentView() {
        contentView = UILabel()
        contentView.numberOfLines = 0
        contentView.font = RobotoFont.regular(with: 18)
    }
    
    fileprivate func prepareBottomBar() {
        bottomBar = Bar()
        bottomBar.leftViews = []
        bottomBar.rightViews = [continueButton]
    }
    
    fileprivate func prepareImageCard() {
        card = Card()
        card.toolbar = toolbar
        card.toolbarEdgeInsetsPreset = .square3
        card.toolbarEdgeInsets.bottom = 0
        card.toolbarEdgeInsets.right = 8
        contentView.text = instructions
        contentView.bounds.size.height = CGFloat(contentView.intrinsicContentSize.height + 50.0)
        card.contentView = contentView
        card.contentViewEdgeInsetsPreset = .wideRectangle3
        card.bottomBar = bottomBar
        card.bottomBarEdgeInsetsPreset = .wideRectangle2
       // card.layou
        view.layout(card).horizontally(left: 20, right: 20).center()
        print("height: \(contentView.bounds.size.height)")
        
    }
    
   @objc public func continueButtonAction() {
        self.dismiss(animated: true) { 
            self.delegate?.cardVCContinueAction(self)
        }
    }
    
   @objc public func cancelButtonAction() {
        self.dismiss(animated: true) {
        //    self.delegate?.cardVCCancelAction(self)
        }
    }
}
