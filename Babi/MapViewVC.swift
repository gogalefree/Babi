//
//  MapViewVC.swift
//  Babi
//
//  Created by Guy Freedman on 4/3/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewVC: UIViewController , UIGestureRecognizerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonView: UIVisualEffectView!
    
    
    var gateAnnotation: MKPointAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "mapTapped:")
        tapGesture.delegate = self
        self.mapView.addGestureRecognizer(tapGesture)

        if let gateAnnotation = gateAnnotation {
            
            self.mapView.addAnnotation(gateAnnotation)
            self.mapView.centerCoordinate = gateAnnotation.coordinate
        }
        
        buttonView.layer.cornerRadius = 5
        buttonView.alpha = 0
    }
    
    func mapTapped(recognizer: UITapGestureRecognizer) {
        
        if let gateAnnotation = gateAnnotation {
            mapView.removeAnnotation(gateAnnotation)
        }
        
        let point = recognizer.locationInView(self.mapView)
        let coords = mapView.convertPoint(point, toCoordinateFromView: self.mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coords
        gateAnnotation = annotation
        self.mapView.addAnnotation(annotation)
        
        self.buttonView.animateToAlphaWithSpring(0.4, alpha: 1)
    }
    
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
