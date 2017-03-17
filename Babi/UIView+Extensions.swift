//
//  UIView+Extensions.swift
//  FoodCollector
//
//  Created by Guy Freedman on 2/13/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func animateToAlphaWithSpring(_ duration: TimeInterval , alpha: CGFloat) {
        
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            self.alpha = alpha
        }, completion: nil)
    }
    
    func animateToCenterWithSpring(_ duration: TimeInterval , center: CGPoint, completion: @escaping (_ completion:Bool)->()) {
        
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            self.center = center
            }, completion: completion)
    }
    
    func animateToYWithSpring(_ duration: TimeInterval , Yvalue: CGFloat ,completion: @escaping (_ completion:Bool)->()) {
        
        var newOrigin = self.frame.origin
        newOrigin.y = Yvalue
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            self.frame.origin = newOrigin
            self.superview?.layoutIfNeeded()
            }, completion: completion)
    }
}

extension UIView {
    class func loadFromNibNamed(_ nibNamed: String, bundle : Bundle? = nil) -> UIView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle
            ).instantiate(withOwner: nil, options: nil)[0] as? UIView
    }
}

extension UITabBar{
    
    func animateCenterWithSpring(_ duration: TimeInterval , center: CGPoint) {
        
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: { () -> Void in
            self.center = center
            }, completion: nil)
    }
}
