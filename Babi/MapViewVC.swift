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

@objc protocol MapVCDelegate: NSObjectProtocol {
    func didFinishPickingLocation(_ gateAnnotation: MKPointAnnotation?)
}

@objc public class MapViewVC: UIViewController , UIGestureRecognizerDelegate, MKMapViewDelegate{

    @IBOutlet weak var mapView:         MKMapView!
    @IBOutlet weak var trackUserButton: UIButton!
    @IBOutlet weak var blureView:       UIVisualEffectView!
    
    
    weak var delegate: MapVCDelegate?
    
    var gateAnnotation: MKPointAnnotation?
    var gate: Gate?
    var trackingUserLocation = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        addTapGestureToMap()
        addPanRecognizer()
        addGateAnnotationIfNeeded()
        configureTrackButton()
        self.navigationItem.rightBarButtonItem?.isEnabled = false
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
        self.mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)

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
        self.blureView.layer.borderColor = UIColor.gray.cgColor
    }
    
    @objc func didDragMap(_ recognizer: UIPanGestureRecognizer) {
        
        if (recognizer.state == UIGestureRecognizer.State.began) {
                
            self.trackingUserLocation = false
            self.blureView.animateToAlphaWithSpring(0.4, alpha: 1)
        }
    }
    
    //MARK: - Track button action
    @IBAction func trackUserAction(_ sender: AnyObject) {
        
        self.trackingUserLocation = true
        self.blureView.animateToAlphaWithSpring(0.4, alpha: 0)
        self.mapView.setCenter(self.mapView.userLocation.coordinate, animated: true)
    }
    

    @objc public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }


    
  @objc public   func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if trackingUserLocation {
            
            self.mapView.setCenter(self.mapView.userLocation.coordinate, animated: true)
            if let newCamera = self.mapView.camera.copy() as? MKMapCamera {
             
                if let location = self.mapView.userLocation.location {
                
                    newCamera.heading = location.course
                    self.mapView.setCamera(newCamera, animated: true)
                }
                
            }
        }
    }
    
    @objc public func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
        print("will start rendernig")
    }
    
    @objc public func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        print("did finish rendernig")

    }
    
   @objc func mapTapped(_ recognizer: UITapGestureRecognizer) {
        
        if let gateAnnotation = gateAnnotation {
            mapView.removeAnnotation(gateAnnotation)
        }
        
        let point = recognizer.location(in: self.mapView)
        let coords = mapView.convert(point, toCoordinateFrom: self.mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coords
        gateAnnotation = annotation
        self.mapView.addAnnotation(annotation)
        self.navigationItem.rightBarButtonItem?.isEnabled = true
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
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAction() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
