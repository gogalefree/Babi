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

    @IBOutlet weak var mapView:         MKMapView!
    @IBOutlet weak var trackUserButton: UIButton!
    @IBOutlet weak var blureView:       UIVisualEffectView!
    
    
    weak var delegate: MapVCDelegate?
    
    var gateAnnotation: MKPointAnnotation?
    var gate: Gate?
    var trackingUserLocation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addTapGestureToMap()
        addPanRecognizer()
        addGateAnnotationIfNeeded()
        configureTrackButton()
        self.navigationItem.rightBarButtonItem?.enabled = false
    }
    
    func addGateAnnotationIfNeeded() {
        
        if let gate = gate {
    
            if gate.longitude != 0.0 && gate.latitude != 0.0 {
        
                let gateAnnotation = MKPointAnnotation()
                gateAnnotation.coordinate = CLLocationCoordinate2DMake(gate.latitude, gate.longitude)
                self.gateAnnotation = gateAnnotation
                self.mapView.addAnnotation(gateAnnotation)
                self.mapView.centerCoordinate = gateAnnotation.coordinate
            }
        }
    }
    
    func addTapGestureToMap() {
    
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewVC.mapTapped(_:)))
        tapGesture.delegate = self
        self.mapView.addGestureRecognizer(tapGesture)
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)

    }
    
    func addPanRecognizer() {
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(MapViewVC.didDragMap(_:)))
        panRecognizer.delegate = self
        self.mapView.addGestureRecognizer(panRecognizer)
    }
    
    func configureTrackButton() {
        
        self.trackUserButton.layer.cornerRadius = self.trackUserButton.frame.size.width / 2
        self.blureView.layer.cornerRadius = self.blureView.frame.size.width / 2
        self.blureView.layer.borderWidth = 1
        self.blureView.layer.borderColor = UIColor.grayColor().CGColor
    }
    
    func didDragMap(recognizer: UIPanGestureRecognizer) {
        
        if (recognizer.state == UIGestureRecognizerState.Began) {
                
            self.trackingUserLocation = false
            self.blureView.animateToAlphaWithSpring(0.4, alpha: 1)
        }
    }
    
    //MARK: - Track button action
    @IBAction func trackUserAction(sender: AnyObject) {
        
        self.trackingUserLocation = true
        self.blureView.animateToAlphaWithSpring(0.4, alpha: 0)
        self.mapView.setCenterCoordinate(self.mapView.userLocation.coordinate, animated: true)
    }
    

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }


    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        
        if trackingUserLocation {
            
            self.mapView.setCenterCoordinate(self.mapView.userLocation.coordinate, animated: true)
            if let newCamera = self.mapView.camera.copy() as? MKMapCamera {
             
                if let location = self.mapView.userLocation.location {
                
                    newCamera.heading = location.course
                    self.mapView.setCamera(newCamera, animated: true)
                }
                
            }
        }
    }
    
    func mapViewWillStartRenderingMap(mapView: MKMapView) {
        print("will start rendernig")
    }
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        print("did finish rendernig")

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
        self.navigationItem.rightBarButtonItem?.enabled = true
    }
    
    @IBAction func doneClicked() {
        
        print("doneClicked")

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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
