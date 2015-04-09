//
//  GatesTVCell.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

protocol SwipeableCellDelegate{
    func buttonZeroAction(cell: SwipeableCellTableViewCell)
    func buttonOneAction(cell: SwipeableCellTableViewCell)
    func buttonTwoAction(cell: SwipeableCellTableViewCell)
    func cellDidOpen(cell: UITableViewCell)
    func cellDidClose(cell: UITableViewCell)
}

class SwipeableCellTableViewCell: UITableViewCell, UIGestureRecognizerDelegate {
    
    
    @IBOutlet weak var button0: UIButton!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var myContentView: UIView!
    @IBOutlet weak var myTextLable: UILabel!
    @IBOutlet weak var contentViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewLeftConstraint: NSLayoutConstraint!
    
    
    var panRecognizer: UIPanGestureRecognizer!
    var panStartPoint: CGPoint!
    var startingRightLayoutConstraintConstant: CGFloat!
    let kBounceValue: CGFloat = 20.0
    
    var delegate: SwipeableCellDelegate?
    var indexPath: NSIndexPath!
    var itemText: String? {
        didSet {
            
            if let text = itemText {
                self.myTextLable.text = text
            }
        }
    }
    
    @IBAction func buttonClicked(sender: UIButton) {
        
        if let delegate = self.delegate {
            
            if sender == self.button0 {
                delegate.buttonZeroAction(self)
            }
            else if sender == self.button1 {
                delegate.buttonOneAction(self)
                
            }
            else if sender == self.button2 {
                delegate.buttonTwoAction(self)
            }
                
            else {
                println("Unknown Button Clicked")
            }
        }
    }
    
    func panThisCell(recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {
            
        case .Began:
            self.panStartPoint = recognizer.translationInView(self.myContentView);
            self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
            
        case .Changed:
            
            let currentPoint = recognizer.translationInView(self.myContentView)
            let deltaX = currentPoint.x - self.panStartPoint.x //negative if pan left
         //   println("Pan Moved \(deltaX)")
            
            var panningLeft = false
            if (currentPoint.x < self.panStartPoint.x) {  //determine left or right pan
                panningLeft = true;
            }
            
            if self.startingRightLayoutConstraintConstant == 0 { //true if the cell is closed
                
                if !panningLeft {
                    
                    let constant = max(-deltaX, 0)
                    
                    if constant == 0 {
                        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
                    }
                    else {
                        self.contentViewRightConstraint.constant = constant;
                    }
                }
                else {
                    let constant = min(-deltaX, self.buttonTotalWidth())
                    
                    if constant == self.buttonTotalWidth() {
                        self.setConstraintsToShowAllButtons(true, notifyDelegateDidOpen: false)
                    }
                    else {
                        self.contentViewRightConstraint.constant = constant
                    }
                }
            }
            else {
                //The cell was at least partially open.
                let adjustment = self.startingRightLayoutConstraintConstant - deltaX; //1
                
                if (!panningLeft) {
                    
                    let constant = max(adjustment, 0)
                    
                    if (constant == 0) {
                        
                        self.resetConstraintContstantsToZero(true ,notifyDelegateDidClose:false)
                    }
                    else {
                        
                        self.contentViewRightConstraint.constant = constant;
                    }
                }
                else {
                    
                    
                    let constant = min(adjustment, self.buttonTotalWidth()) //5
                    
                    if (constant == self.buttonTotalWidth()) { //6
                        
                        self.setConstraintsToShowAllButtons(true ,notifyDelegateDidOpen:false);
                    }
                    else { //7
                        
                        self.contentViewRightConstraint.constant = constant;
                    }
                }
            }
            
            
            self.contentViewLeftConstraint.constant = -self.contentViewRightConstraint.constant
            
            
        case .Ended:
            
            if (self.startingRightLayoutConstraintConstant == 0) { //1 //Cell was opening
                
                let halfOfButtonOne:CGFloat  = CGRectGetWidth(self.button1.frame) / 2;
                
                if (self.contentViewRightConstraint.constant >= halfOfButtonOne) {
                    
                    //Open all the way
                    self.setConstraintsToShowAllButtons(true ,notifyDelegateDidOpen:true);
                }
                else {
                    //Re-close
                    self.resetConstraintContstantsToZero(true ,notifyDelegateDidClose:true);
                }
            }
            else {
                
                //Cell was closing
                let buttonOnePlusHalfOfButton2:CGFloat = CGRectGetWidth(self.button1.frame) + (CGRectGetWidth(self.button2.frame) / 2);
                if (self.contentViewRightConstraint.constant >= buttonOnePlusHalfOfButton2) {
                    //Re-open all the way
                    self.setConstraintsToShowAllButtons(true ,notifyDelegateDidOpen:true)
                }
                else {
                    //Close
                    self.resetConstraintContstantsToZero(true ,notifyDelegateDidClose:true)
                }
            }
            
        case .Cancelled:
            
            if (self.startingRightLayoutConstraintConstant == 0) {
                //Cell was closed - reset everything to 0
                self.resetConstraintContstantsToZero(true ,notifyDelegateDidClose:true)
            }
            else {
                //Cell was open - reset to the open state
                self.setConstraintsToShowAllButtons(true ,notifyDelegateDidOpen:true)
            }
            
        default:
            break
        }
        
    }
    
    func updateConstraintsIfNeeded(animated: Bool ,completion:(finished: Bool) ->Void ) {
        
        var duration = 0.0;
        if (animated) {
            duration = 0.4;
        }
        
        UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut , animations: { () -> Void in
            self.layoutIfNeeded()
            }, completion: completion)
    }
    
    func buttonTotalWidth() -> CGFloat {
        
        return CGRectGetWidth(self.frame) - CGRectGetMinX(self.button2.frame);
    }
    
    func resetConstraintContstantsToZero(animated: Bool ,notifyDelegateDidClose endEditing:Bool) {
        
        if (endEditing) {
            self.delegate?.cellDidClose(self);
        }
        
        if (self.startingRightLayoutConstraintConstant != nil && self.startingRightLayoutConstraintConstant == 0 &&
            self.contentViewRightConstraint.constant == 0) {
                //Already all the way closed, no bounce necessary
                return;
        }
        
        self.contentViewRightConstraint.constant = -kBounceValue;
        self.contentViewLeftConstraint.constant = kBounceValue;
        
        self.updateConstraintsIfNeeded(animated, completion: { (finished) -> Void in
            self.contentViewRightConstraint.constant = 0;
            self.contentViewLeftConstraint.constant = 0;
            
            self.updateConstraintsIfNeeded(animated, completion: { (finished) -> Void in
                self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant
            })
        })
    }
    
    func setConstraintsToShowAllButtons(animated:Bool ,notifyDelegateDidOpen notifyDelegate:Bool) {
        
        if (notifyDelegate) {
            self.delegate?.cellDidOpen(self)
        }
        
       
        if (self.startingRightLayoutConstraintConstant == self.buttonTotalWidth() &&
            self.contentViewRightConstraint.constant == self.buttonTotalWidth()) {
                return;
        }
        
        self.contentViewLeftConstraint.constant = -self.buttonTotalWidth() - kBounceValue;
        self.contentViewRightConstraint.constant = self.buttonTotalWidth() + kBounceValue;
        
        self.updateConstraintsIfNeeded(animated, completion: { (finished) -> Void in
            
            self.contentViewLeftConstraint.constant = -self.buttonTotalWidth()
            self.contentViewRightConstraint.constant = self.buttonTotalWidth()
            
            self.updateConstraintsIfNeeded(animated, completion: { (finished) -> Void in
                self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant
            })
        })
    }
    
    func openCell() {
        self.setConstraintsToShowAllButtons(false ,notifyDelegateDidOpen:false);
    }
    
    
    override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetConstraintContstantsToZero(false ,notifyDelegateDidClose:false)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: "panThisCell:")
        self.panRecognizer.delegate = self;
        self.myContentView.addGestureRecognizer(self.panRecognizer)
    }
    
    func setAutomaticButtonTitle(automatic: Bool) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.button2.setTitle(automaticHeaderTitles[automatic.hashValue], forState: UIControlState.Normal)
            if automatic {
                self.button2.setTitleColor(UIColor.greenColor(), forState: .Normal)
            }
            else {
                self.button2.setTitleColor(UIColor.redColor(), forState: .Normal)
            }
        })
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
