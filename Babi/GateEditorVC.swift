//
//  GateEditorVC.swift
//  Babi
//
//  Created by Guy Freedman on 3/31/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import MapKit

enum GateEditorState {
    case NewGate
    case EditGate
}

class GateEditorVC: UIViewController, UITableViewDataSource, UITableViewDelegate, GateEditorHeaderViewDelegate, GateEditorTextFieldCellDeleagte, GateEditorLocationCellDelegate, GateAutomaticCellDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    
    var visibleSections: [Bool] = [false, false, false, false]
    var headers = [GateEditorTVCHeaderView]()
    let automaticHeaderTitles = ["Manual" , "Automatic"]
    
    var gate: Gate!
    var state: GateEditorState! {
        didSet{
            configureWithState(state)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 66
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        /*
        //0 gate name
        //1 gate phone number
        //2 gate location
        //3 gate mode
        */
        return 4
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 66
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 66
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        let sectionIsVisible = visibleSections[section]
        println("section visible \(sectionIsVisible)")
        if !sectionIsVisible {return 0}
        
        switch section {
        case 0:
            return 1 //textViewCell
        case 1:
            return 1 //textViewCell
        case 2:
            return 1 //location
        case 3:
            return 1 //mode
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        switch indexPath.section {
        case 0:
            var cell = tableView.dequeueReusableCellWithIdentifier("gateEditorTextFieldCell", forIndexPath: indexPath) as gateEditorTextFieldCell
            cell.delegate = self
            cell.indexPath = indexPath
            cell.textField.keyboardType = .Default
            cell.textField.becomeFirstResponder()
            return cell
        
        case 1:
            var cell = tableView.dequeueReusableCellWithIdentifier("gateEditorTextFieldCell", forIndexPath: indexPath) as gateEditorTextFieldCell
            cell.delegate = self
            cell.indexPath = indexPath
            cell.textField.keyboardType = .PhonePad
            cell.textField.becomeFirstResponder()
            return cell
            
        case 2:
            var cell = tableView.dequeueReusableCellWithIdentifier("GateEditorLocationCell", forIndexPath: indexPath) as GateEditorLocationCell
            return cell
            
        case 3:
            var cell = tableView.dequeueReusableCellWithIdentifier("GateEditorAutomaticCell", forIndexPath: indexPath) as GateEditorAutomaticCell
            cell.automatic = gate.automatic
            cell.delegate = self
            return cell
            
        default:
            var cell = UITableViewCell()
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headersMaxIndex = headers.count - 1
        
        if headersMaxIndex >= section  {
            return headers[section]
        }
        
        let headerView = UIView.loadFromNibNamed("GateEditorTVCHeaderView") as GateEditorTVCHeaderView
        headerView.section = section
        headerView.headerRoll = GateEditorTVCHeaderView.Roll(rawValue: section)
        headerView.delegate = self
        headers.append(headerView)
        return headerView
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        }
    
    // MARK: - Headers Delegate
    
    func headerTapped(headerView: GateEditorTVCHeaderView) {
        println("gates tvc header tappd: \(headerView.headerRoll.rawValue)")
        
        let section = headerView.headerRoll.rawValue
        let visible = visibleSections[section]

        if visible && section < 2 {
        
            saveNewText(headerView.titleLabel.text!, section: section)
        }
        
        visibleSections[section] = !visible
        tableView.reloadSections(NSIndexSet(index:section), withRowAnimation: .Automatic)
    }
    
    func saveNewText(text: String, section: Int) {
        switch section {
        case 0:
            gate.name = text
        case 1:
            gate.phoneNumber = text
        default:
            break
        }

        println("saved " + text)
    }

    
    //MARK: - TextFieldCell Delegate
    
    func editingText(text: String, indexpath: NSIndexPath){
        let header = headers[indexpath.section]
        header.animateNewText(text)
    }

    func didFinishEditingText(text: String?, indexpath: NSIndexPath) {
    
        let header = headers[indexpath.section]
        self.headerTapped(header)
    }
    
    //MARK: - LocationCell Delegate
    
    func didRequestMapView() {
        
    }

    @IBAction func unwindFromMapViewVC(segue: UIStoryboardSegue) {
        
        println("unwind from map view")
        let mapVC = segue.sourceViewController as MapViewVC
        let mapAnnotation = mapVC.gateAnnotation
        if let mapAnnotation = mapAnnotation {
            gate.latitude = mapAnnotation.coordinate.latitude
            gate.longitude = mapAnnotation.coordinate.longitude
        }
        
        let locationHeader = headers[2]
        locationHeader.animateNewText("Defined")
        headerTapped(locationHeader)
    }

    //MARK: - AutomaticCell Delegate
    
    func didChangeGateAutomaticMode(isAutomatic: Bool) {
        gate.automatic = isAutomatic
        let header = headers[3]
        let c = headers[isAutomatic.hashValue]
        header.animateNewText(automaticHeaderTitles[isAutomatic.hashValue])
    }

    func configureWithState(gateState: GateEditorState) {
        switch gateState {
           
        case .NewGate:

            gate = Gate.instansiateWithZero()
        
        case .EditGate:
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
        if segue.identifier == "presentMapView" {
            
            if gate.longitude != 0.0 && gate.latitude != 0.0 {
            
                let mapNavController = segue.destinationViewController as UINavigationController
                let mapVC = mapNavController.viewControllers[0] as MapViewVC
                let gateAnnotation = MKPointAnnotation()
                gateAnnotation.coordinate = CLLocationCoordinate2DMake(gate.latitude, gate.longitude)
                mapVC.gateAnnotation = gateAnnotation
            }
        }
        
        else {println("back to tvc: \(segue.identifier)")}
    }
    

}
