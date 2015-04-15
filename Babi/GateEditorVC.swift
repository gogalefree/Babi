//
//  GateEditorVC.swift
//  Babi
//
//  Created by Guy Freedman on 3/31/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import MapKit
import CoreData

enum GateEditorState {
    case NewGate
    case EditGate
}

class GateEditorVC: UIViewController, UITableViewDataSource, UITableViewDelegate, GateEditorHeaderViewDelegate, GateEditorTextFieldCellDeleagte, GateEditorLocationCellDelegate, GateAutomaticCellDelegate,UIScrollViewDelegate{
    
    @IBOutlet weak var tableView: UITableView!
  
    var doneButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    
    private let kTableViewHeaderHeight: CGFloat = 160.0
    var headerView: GateEditorTableMainHeader!

    
    var visibleSections: [Bool] = [false, false, false, false, false] //count must be equal to the sections count
    
    var headers = [GateEditorTVCHeaderView]()
    
    var gate: Gate!
    var state: GateEditorState! {
        didSet{
//            configureWithState(state)
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 66
        self.tableView.contentInset.top = 68
        addNavigationBarItems()
        configureWithState(state)

    }
    
    func addNavigationBarItems() {
                
        let doneImage = UIImage(named: "tick10.png")
        self.doneButton = UIBarButtonItem(image: doneImage, style: UIBarButtonItemStyle.Plain, target: self, action: "doneButtonClicked:")
        
        let deleteImage = UIImage(named: "garbage11.png")
        self.deleteButton = UIBarButtonItem(image: deleteImage, style: UIBarButtonItemStyle.Plain, target: self, action: "deleteAction")
        
        self.navigationItem.rightBarButtonItems = [self.doneButton, self.deleteButton]
    }
    
    /*
    func configureHeaderView() {
        
        headerView = self.tableView.tableHeaderView as! GateEditorTableMainHeader
        self.tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        
        self.tableView.contentInset = UIEdgeInsets(top: kTableViewHeaderHeight, left: 0, bottom: 100, right: 0)
        self.tableView.contentOffset = CGPointMake(0, -kTableViewHeaderHeight)
        updateHeaderView()
        
    }
    
    func updateHeaderView() {
        
        var headerRect = CGRect(x: 0, y: -kTableViewHeaderHeight, width: self.tableView.bounds.width, height: kTableViewHeaderHeight)
        if self.tableView.contentOffset.y < -kTableViewHeaderHeight {
            headerRect.origin.y = tableView.contentOffset.y
            headerRect.size.height = -tableView.contentOffset.y
        }
        self.headerView.frame = headerRect
    }
*/
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
    }

   
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        /*
        //0 gate name
        //1 gate phone number
        //2 gate location
        //3 gate mode
        //4 fence header
        */
        return 5
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
            return 2 //mode (automatic + distance to fire)
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        switch indexPath.section {
        case 0:
            var cell = tableView.dequeueReusableCellWithIdentifier("gateEditorTextFieldCell", forIndexPath: indexPath) as! gateEditorTextFieldCell
            cell.delegate = self
            cell.indexPath = indexPath
            cell.textField.keyboardType = .Default
            cell.textField.becomeFirstResponder()
            return cell
        
        case 1:
            var cell = tableView.dequeueReusableCellWithIdentifier("gateEditorTextFieldCell", forIndexPath: indexPath) as! gateEditorTextFieldCell
            cell.delegate = self
            cell.indexPath = indexPath
            cell.textField.keyboardType = UIKeyboardType.NumbersAndPunctuation
            cell.textField.becomeFirstResponder()
            return cell
            
        case 2:
            var cell = tableView.dequeueReusableCellWithIdentifier("GateEditorLocationCell", forIndexPath: indexPath) as! GateEditorLocationCell
            return cell
            
        case 3:
            if indexPath.row == 0 {
                //automatic cell
                var cell = tableView.dequeueReusableCellWithIdentifier("GateEditorAutomaticCell", forIndexPath: indexPath) as! GateEditorAutomaticCell
                cell.automatic = gate.automatic
                cell.delegate = self
                return cell
            }
            else {
                var cell = tableView.dequeueReusableCellWithIdentifier("GateEditorDistanceToCallCell", forIndexPath: indexPath) as! GateEditorDistanceCell
                cell.gate = gate
                return cell
            }
            
        default:
            var cell = UITableViewCell()
            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == 4 {
            //fence view
            let fenceView = UIView.loadFromNibNamed("GateEditorFenceHeaderVIew")
            return fenceView
        }
        
        let headersMaxIndex = headers.count - 1
        //if the headers were already created
        if headersMaxIndex >= section  {
            return headers[section]
        }
        
        let headerView = UIView.loadFromNibNamed("GateEditorTVCHeaderView") as! GateEditorTVCHeaderView
        headerView.section = section
        headerView.headerRoll = GateEditorTVCHeaderView.Roll(rawValue: section)
        headerView.delegate = self
        if self.state == .EditGate {
            headerView.gate = gate
        }
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
            let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section)) as! gateEditorTextFieldCell
            cell.textField.resignFirstResponder()
            let gateState = authenticateGate()
            if gateState.authenticated {showDoneButton()}
            else {hideDoneButton()}
        }
        
        visibleSections[section] = !visible
        tableView.reloadSections(NSIndexSet(index:section), withRowAnimation: .Automatic)
        
        if !visible {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section), atScrollPosition: .Top, animated: true)
        }

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
        saveNewText(text, section: indexpath.section)
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
        let mapVC = segue.sourceViewController as! MapViewVC
        let mapAnnotation = mapVC.gateAnnotation
        if let mapAnnotation = mapAnnotation {
            gate.latitude = mapAnnotation.coordinate.latitude
            gate.longitude = mapAnnotation.coordinate.longitude
        }
        
        let locationHeader = headers[2]
        locationHeader.animateNewText(locationHeaderTitles[1])
        headerTapped(locationHeader)
    }

    //MARK: - AutomaticCell Delegate
    
    func didChangeGateAutomaticMode(isAutomatic: Bool) {
        gate.automatic = isAutomatic
        let header = headers[3]
        header.animateNewText(automaticHeaderTitles[isAutomatic.hashValue])
    }

    func configureWithState(gateState: GateEditorState) {
        switch gateState {
           
        case .NewGate:

            gate = Gate.instansiateWithZero()
            gate.longitude = Model.shared.userLocation.coordinate.longitude
            gate.latitude = Model.shared.userLocation.coordinate.latitude
            hideDoneButton()
            hideDeleteButton()
        case .EditGate:
            break
        }
    }
    
    func hideDoneButton() {
        self.doneButton.enabled = false
    }
    
    func showDoneButton() {
        self.doneButton.enabled = true
    }
    
    func hideDeleteButton() {
        self.deleteButton.enabled = false
    }

    func doneButtonClicked(sender: AnyObject) {
    
        println("doneButtonClicked")
        let gateAuthenticated = authenticateGate()
        if !gateAuthenticated.authenticated {showAlert(gateAuthenticated.section!)}
        else {self.performSegueWithIdentifier("unwindToGatesTVC", sender:self)}
    }
    
    func deleteAction() {
        let alert = UIAlertController(title: "Sure you want to delete?", message: "\(gate.name)", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { (action) -> Void in
            
            self.performSegueWithIdentifier("unwindwithdeletesegue", sender: self)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func authenticateGate() -> (authenticated: Bool, section: Int?) {
        
        
        if gate.name == kGateNameDefaultValue || gate.name == initialTitles[0] {
            return (false, 0)
        }
        else if gate.phoneNumber == kGatePhoneNumberDefaultValue || gate.phoneNumber == initialTitles[1] {
            return (false, 1)
        }
        else if gate.latitude == kGateLatitudeDefaultValue || gate.longitude == kGateLongitudeDefaultValue {
            return (false , 2)
        }
        
        return (true , nil)
    }
    
    func showAlert(section: Int) {
        var message = ""
        switch section {
        case 0:
            message = "Please Enter Gate Name"
        case 1:
            message = "Please Enter Gate Phone Number"
        default:
            message = "Unknown error"
        }
        let alert = UIAlertController(title: message, message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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
            
                let mapNavController = segue.destinationViewController as! UINavigationController
                let mapVC = mapNavController.viewControllers[0] as! MapViewVC
                let gateAnnotation = MKPointAnnotation()
                gateAnnotation.coordinate = CLLocationCoordinate2DMake(gate.latitude, gate.longitude)
                mapVC.gateAnnotation = gateAnnotation
            }
        }
        
        else if segue.identifier == "cancelButtonSegue" {
            //if state is .NewGate and the user has canceled
            //we need to delete the new gate from the context
            if self.state == .NewGate {
                let context = Model.shared.context
                if let context = context {
                    context.deleteObject(gate)
                    context.save(nil)
                }
            }
        }
    }
}
