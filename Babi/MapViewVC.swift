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

protocol MapVCDelegate: NSObjectProtocol {
    func didFinishPickingLocation(gateAnnotation: MKPointAnnotation?)
}

class MapViewVC: UIViewController , UIGestureRecognizerDelegate, MKMapViewDelegate{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonView: UIVisualEffectView!
    @IBOutlet weak var doneButton: UIButton!

    weak var delegate: MapVCDelegate?
    
    var gateAnnotation: MKPointAnnotation?
    var gate: Gate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "mapTapped:")
        tapGesture.delegate = self
        self.mapView.addGestureRecognizer(tapGesture)
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        
        if let gate = gate {
            
            if gate.longitude != 0.0 && gate.latitude != 0.0 {
                
                let gateAnnotation = MKPointAnnotation()
                gateAnnotation.coordinate = CLLocationCoordinate2DMake(gate.latitude, gate.longitude)
                self.gateAnnotation = gateAnnotation
            }
        }
        
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
    
    @IBAction func doneClicked() {
        
        println("doneClicked")

        if let mapAnnotation = gateAnnotation {
            gate?.latitude = mapAnnotation.coordinate.latitude
            gate?.longitude = mapAnnotation.coordinate.longitude
        }
        
        //inform gateEditor
        if let delegate = delegate {
            delegate.didFinishPickingLocation(gateAnnotation)
        }
        
        //dissmiss
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancelAction() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
