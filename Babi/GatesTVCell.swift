//
//  GatesTVCell.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

protocol SwipeableCellDelegate{
    func buttonOneAction(_ cell: SwipeableCellTableViewCell)
    func buttonTwoAction(_ cell: SwipeableCellTableViewCell)
    func shareButtonClicked(_ cell: SwipeableCellTableViewCell)
    func cellDidOpen(_ cell: UITableViewCell)
    func cellDidClose(_ cell: UITableViewCell)
}

class SwipeableCellTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var myContentView: UIView!
    @IBOutlet weak var myTextLable: UILabel!
    @IBOutlet weak var contentViewRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var arrowImageView: UIImageView!
    
    let automaticColor = UIColor.black// UIColor(red: 134.0/255.0, green: 46.0/255.0, blue: 73.0/255.0, alpha: 0.9)
    let manualColor = UIColor.black

    
    
    var panRecognizer: UIPanGestureRecognizer!
    var panStartPoint: CGPoint!
    var startingRightLayoutConstraintConstant: CGFloat! = 0
    let kBounceValue: CGFloat = 20.0
    var isOpen: Bool = false {
        didSet{
            print("gate open: \(isOpen)")
        }
    }
    
    var gate: Gate!{
        didSet{
            if let gate = gate {setAutomaticButtonTitle(gate.automatic)}
        }
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
    
    @IBAction func buttonClicked(_ sender: UIButton) {
        
        if let delegate = self.delegate {
            

            if sender == self.button1 {
                delegate.buttonOneAction(self)
                
            }
            else if sender == self.button2 {
                delegate.buttonTwoAction(self)
            }
                
            else if sender == self.button3 {
                delegate.shareButtonClicked(self)
            }
        }
    }
    
    func panThisCell(_ recognizer: UIPanGestureRecognizer) {
        
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
                let buttonOnePlusHalfOfButton2:CGFloat = self.button1.frame.width + (self.button2.frame.width / 2);
                
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
    
    func updateConstraintsIfNeeded(_ animated: Bool ,completion:@escaping (_ finished: Bool) ->Void ) {
        
        var duration = 0.0;
        if (animated) {
            duration = 0.4;
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: UIViewAnimationOptions() , animations: { () -> Void in
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
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: (180.0 * CGFloat(M_PI)) / 180.0)
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetConstraintContstantsToZero(false ,notifyDelegateDidClose:false)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SwipeableCellTableViewCell.panThisCell(_:)))
        self.panRecognizer.delegate = self;
        self.myContentView.addGestureRecognizer(self.panRecognizer)
    }
    
    func setAutomaticButtonTitle(_ automatic: Bool) {
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.button2.setTitle(automaticHeaderTitles[automatic.hashValue], for: UIControlState())
            if automatic {
                self.button2.setTitleColor(self.automaticColor, for: UIControlState())
            }
            else {
                self.button2.setTitleColor(self.manualColor, for: UIControlState())
            }
        })
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
