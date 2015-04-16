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
    @IBOutlet weak var arrowImageView: UIImageView!
    
    let automaticColor = UIColor(red: 134.0/255.0, green: 46.0/255.0, blue: 73.0/255.0, alpha: 0.9)
    let manualColor = UIColor.blackColor()

    
    
    var panRecognizer: UIPanGestureRecognizer!
    var panStartPoint: CGPoint!
    var startingRightLayoutConstraintConstant: CGFloat! = 0
    let kBounceValue: CGFloat = 20.0
    var isOpen: Bool = false {
        didSet{
            println("gate open: \(isOpen)")
        }
    }
    
    var gate: Gate!{
        didSet{
            if let gate = gate {setAutomaticButtonTitle(gate.automatic)}
        }
    }
    
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
            
//            if sender == self.button0 {
//                delegate.buttonZeroAction(self)
//            }
            if sender == self.button1 {
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
                    println("paning right when the cell is closed")

                    
                    let constant = max(-deltaX, 0)
                    
                    if constant == 0 {
                        self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: false)
                    }
                    else {
                        self.contentViewRightConstraint.constant = constant;
                    }
                }
                else {
                    println("paning left when the cell is closed \(-deltaX)")

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
                    println("paning right when the cell is open \(deltaX)")

                    
                    let constant = max(adjustment, 0)
                    
                    if (constant == 0) {
                        
                        self.resetConstraintContstantsToZero(true ,notifyDelegateDidClose:false)
                    }
                    else {
                        
                        self.contentViewRightConstraint.constant = constant;
                    }
                }
                else {
                    println("paning left when the cell is open")

                    
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
                let buttonOnePlusHalfOfButton2:CGFloat = CGRectGetWidth(self.button1.frame) + (CGRectGetWidth(self.button2.frame) / 2);
                
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
            
        case .Cancelled:
            
            if (self.startingRightLayoutConstraintConstant == 0) {
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
        
        isOpen = false
        
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
        
        self.isOpen = true
        
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
    
    func animateIconCellOpen() {
        UIView.animateWithDuration(0.8, animations: {
            self.arrowImageView.transform = CGAffineTransformMakeRotation((180.0 * CGFloat(M_PI)) / 180.0)
        })
    }
    
    func animateIconCellCloased() {
        UIView.animateWithDuration(0.8, animations: {
            self.arrowImageView.transform = CGAffineTransformMakeRotation(0)
        })
        
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationUpdated", name: kLocationUpdateNotification, object: nil)

    }
    
    func setAutomaticButtonTitle(automatic: Bool) {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.button2.setTitle(automaticHeaderTitles[automatic.hashValue], forState: UIControlState.Normal)
            if automatic {
                self.button2.setTitleColor(self.automaticColor, forState: .Normal)
            }
            else {
                self.button2.setTitleColor(self.manualColor, forState: .Normal)
            }
        })
    }
    
    func locationUpdated() {
        
        if let gate = gate {
        
            println("location update in cell**********")
            gate.toString()
            let distance = Int(gate.distanceFromUserLocation)
            println("distance \(distance)")
            let title = gate.name + "\n\(distance) m"
            itemText = title
        }
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        let touch = touches.first as! UITouch
        let touchPoint = touch.locationInView(self)
        let callRect = CGRectMake(0,0,
            CGRectGetMinX(self.arrowImageView.frame) - 10 ,
            CGRectGetHeight(self.frame))
        
        let closeCellRect = CGRectMake(0,0,
            CGRectGetMaxX(arrowImageView.frame),
            CGRectGetHeight(self.frame))
        
        let shouldCall = CGRectContainsPoint(callRect, touchPoint)
        let shouldCloseCell = CGRectContainsPoint(closeCellRect, touchPoint)
        
        if !shouldCall && !isOpen {
            //open cell
            println("Arrow touched")
            self.setConstraintsToShowAllButtons(true ,notifyDelegateDidOpen:true);
            animateIconCellOpen()
        }
        else if shouldCloseCell && isOpen {
            //close the cell
            print("Arrow touched to close")
            self.resetConstraintContstantsToZero(true, notifyDelegateDidClose: true)
            animateIconCellCloased()
        }
        else {
            //call gate phone number
            super.touchesBegan(touches, withEvent: event)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
