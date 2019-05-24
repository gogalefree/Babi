//
//  GatesTVCell+Swipe.swift
//  Babi
//
//  Created by Guy Freedman on 29/03/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import Foundation
import UIKit

extension SwipeableCellTableViewCell {
    
   @objc func panThisCell(_ recognizer: UIPanGestureRecognizer) {
        
        switch recognizer.state {
            
        case .began:
            self.panStartPoint = recognizer.translation(in: self.myContentView);
            self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant;
            
        case .changed:
            
            let currentPoint = recognizer.translation(in: self.myContentView)
            let deltaX = currentPoint.x - self.panStartPoint.x //negative if pan left
            //   println("Pan Moved \(deltaX)")
            
            var panningLeft = false
            if (currentPoint.x < self.panStartPoint.x) {  //determine left or right pan
                panningLeft = true;
            }
            
            if self.startingRightLayoutConstraintConstant == 0 { //true if the cell is closed
                if !panningLeft {
                    print("paning right when the cell is closed")
                    
                    
                    let constant = max(-deltaX, 0)
                    
                    if constant == 0 {
                        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
                    }
                    else {
                        self.contentViewRightConstraint.constant = constant;
                    }
                }
                else {
                    print("paning left when the cell is closed \(-deltaX)")
                    
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
                    print("paning right when the cell is open \(deltaX)")
                    
                    
                    let constant = max(adjustment, 0)
                    
                    if (constant == 0) {
                        
                        self.resetConstraintContstantsToZero(true ,notifyDelegateDidClose:false)
                    }
                    else {
                        
                        self.contentViewRightConstraint.constant = constant;
                    }
                }
                else {
                    print("paning left when the cell is open")
                    
                    
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
            
            
        case .ended:
            
            if (self.startingRightLayoutConstraintConstant == 0) { //1 //Cell was opening
                
                let halfOfButtonOne:CGFloat  = self.button1.frame.width / 2;
                
                //added
                animateIconCellOpen()
                //ended
                
                if (self.contentViewRightConstraint.constant >= halfOfButtonOne) {
                    
                    //Open all the way
                    self.setConstraintsToShowAllButtons(true ,notifyDelegateDidOpen:true);
                }
                else {
                    //Re-close
                    self.resetConstraintContstantsToZero(true ,notifyDelegateDidClose:true);
                    animateIconCellCloased()
                }
            }
            else {
                
                //Cell was closing
                let buttonOnePlusHalfOfButton2:CGFloat = self.button1.frame.width + (self.button3.frame.width / 2);
                
                //added
                animateIconCellCloased()
                //ended
                if (self.contentViewRightConstraint.constant >= buttonOnePlusHalfOfButton2) {
                    //Re-open all the way
                    self.setConstraintsToShowAllButtons(true ,notifyDelegateDidOpen:true)
                    animateIconCellOpen()
                }
                else {
                    //Close
                    self.resetConstraintContstantsToZero(true ,notifyDelegateDidClose:true)
                    animateIconCellCloased()
                }
            }
            
        case .cancelled:
            
            if (self.startingRightLayoutConstraintConstant == -8) {
                //Cell was closed - reset everything to 0
                self.resetConstraintContstantsToZero(true ,notifyDelegateDidClose:true)
                animateIconCellCloased()
            }
            else {
                //Cell was open - reset to the open state
                self.setConstraintsToShowAllButtons(true ,notifyDelegateDidOpen:true)
                animateIconCellOpen()
            }
            
        default:
            break
        }
        
    }
    
    func updateConstraintsIfNeeded(_ animated: Bool ,completion:@escaping (_ finished: Bool) ->Void ) {
        
        var duration = 0.0;
        if (animated) {
            duration = 0.4;
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions() , animations: { () -> Void in
            self.layoutIfNeeded()
        }, completion: completion)
    }
    
    func buttonTotalWidth() -> CGFloat {
        
        return self.frame.width - self.button3.frame.minX;
    }
    
    func resetConstraintContstantsToZero(_ animated: Bool ,notifyDelegateDidClose endEditing:Bool) {
        
        isOpen = false
        
        if (endEditing) {
            self.delegate?.cellDidClose(self)
            animateIconCellCloased()
        }
        
        if (self.startingRightLayoutConstraintConstant != nil && self.startingRightLayoutConstraintConstant == -8 &&
            self.contentViewRightConstraint.constant == -8) {
            //Already all the way closed, no bounce necessary
            return;
        }
        
        self.contentViewRightConstraint.constant = -kBounceValue;
        self.contentViewLeftConstraint.constant = kBounceValue;
        
        self.updateConstraintsIfNeeded(animated, completion: { (finished) -> Void in
            self.contentViewRightConstraint.constant = -8;
            self.contentViewLeftConstraint.constant = -8;
            
            self.updateConstraintsIfNeeded(animated, completion: { (finished) -> Void in
                self.startingRightLayoutConstraintConstant = self.contentViewRightConstraint.constant
            })
        })
    }
    
    func setConstraintsToShowAllButtons(_ animated:Bool ,notifyDelegateDidOpen notifyDelegate:Bool) {
        
        self.isOpen = true
        
        if (notifyDelegate) {
            self.delegate?.cellDidOpen(self)
            animateIconCellOpen()
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
    
    func animateIconCellOpen() {
        UIView.animate(withDuration: 0.8, animations: {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: (180.0 * CGFloat.pi) / 180.0)
        })
    }
    
    func animateIconCellCloased() {
        UIView.animate(withDuration: 0.8, animations: {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: 0)
        })
        
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            let touchPoint = touch.location(in: self)
            let callRect = CGRect(x: 0,y: 0,
                                  width: self.arrowImageView.frame.minX - 30 ,
                                  height: self.frame.height)
            
            let closeCellRect = CGRect(x: 0,y: 0,
                                       width: arrowImageView.frame.maxX,
                                       height: self.frame.height)
            
            let shouldCall = callRect.contains(touchPoint)
            let shouldCloseCell = closeCellRect.contains(touchPoint)
            
            if !shouldCall && !isOpen {
                //open cell
                print("Arrow touched")
                self.setConstraintsToShowAllButtons(true ,notifyDelegateDidOpen:true);
                animateIconCellOpen()
            }
            else if shouldCloseCell && isOpen {
                //close the cell
                print("Arrow touched to close", terminator: "")
                self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: true)
                animateIconCellCloased()
            }
            else {
                //call gate phone number
                super.touchesBegan(touches, with: event)
            }
        }
    }

    
}
