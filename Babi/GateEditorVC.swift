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
import AddressBook
import AddressBookUI

enum GateEditorState {
    case NewGate
    case EditGate
}

class GateEditorVC: UIViewController, UITableViewDataSource, UITableViewDelegate, GateEditorHeaderViewDelegate, GateAutomaticCellDelegate,UIScrollViewDelegate, ABPeoplePickerNavigationControllerDelegate, MapVCDelegate {
    
    @IBOutlet weak var tableView: UITableView!
  
    var doneButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    var addressBookButton: UIBarButtonItem!
    
    private let kTableViewHeaderHeight: CGFloat = 160.0

    
    var visibleSections: [Bool] = [false, false, false, false, false] //count must be equal to the sections count
    
    var selectedSection: Int!
    
    var headers = [GateEditorTVCHeaderView]()
    var didCreateHeaders = false
    
    var gate: Gate!
    var state: GateEditorState!
    
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
        
        let addressBookImage = UIImage(named: "address20.png")
        self.addressBookButton = UIBarButtonItem(image: addressBookImage, style: UIBarButtonItemStyle.Plain, target: self, action: "addressBookAction")
        
        self.navigationItem.rightBarButtonItems = [self.doneButton, self.deleteButton, self.addressBookButton]
    }
    
   
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
        if !sectionIsVisible {return 0}
        
        switch section {
        
        case 3:
            if gate.automatic { return 2 } //mode (automatic + distance to fire)
            return 1
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        switch indexPath.section {
            
        case 2:
            var cell = tableView.dequeueReusableCellWithIdentifier("GateEditorLocationCell", forIndexPath: indexPath) as! GateEditorLocationCell
            return cell
            
        case 3:
            if indexPath.row == 0 {
                //automatic cell
                var cell = tableView.dequeueReusableCellWithIdentifier("GateEditorAutomaticCell", forIndexPath: indexPath) as! GateEditorAutomaticCell
                cell.gate = gate
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
            didCreateHeaders = true
            let fenceView = UIView.loadFromNibNamed("GateEditorFenceHeaderVIew")
            return fenceView
        }
        
        if !didCreateHeaders {
            
            let headerView = UIView.loadFromNibNamed("GateEditorTVCHeaderView") as! GateEditorTVCHeaderView
            headerView.section = section
            headerView.headerRoll = GateEditorTVCHeaderView.Roll(rawValue: section)
            headerView.gate = gate
            headerView.delegate = self
            if self.state == .EditGate {
                headerView.setGateTitles(gate)
            }
            headers.append(headerView)
            return headerView
        }
        
        else{ return headers[section]}
    }
    
  
    // MARK: - Headers Delegate
    
    func headerTapped(headerView: GateEditorTVCHeaderView) {
        println("gates tvc header tappd: \(headerView.headerRoll.rawValue)")
        
        //if the header is location header then we show the map vc
        if headerView.headerRoll == GateEditorTVCHeaderView.Roll.GateLocation {
            //headerView.selected = false
            presentMapVC()
        }
        
        let section = headerView.section
        let visible = visibleSections[section]

        if visible && section < 3 {
        
            let gateState = authenticateGate()
            if gateState.authenticated {showDoneButton()}
            else {hideDoneButton()}
        }
        
        visibleSections[section] = !visible
        
        //mode section
        if section == 3 {
            tableView.reloadSections(NSIndexSet(index:section), withRowAnimation: .Automatic)
        }
        
        //if a header becomes selected - hide all other headers
        if headerView.selected {
            hideHeaders(section)
        }
        
    }
    
    func hideHeaders(visibleSection: Int?) {
        
        for index in 0...3 {
            
            //skip hiding the visible section
            if let visibleSection = visibleSection {
                if visibleSection == index {continue}
            }
            
            let sectionVisible = visibleSections[index]
            if sectionVisible {
                
                visibleSections[index] = false
                let header = headers[index]
                header.selected = false
                header.setIdeleState()

                switch index {
                case 2, 3:
                    tableView.reloadSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                default:
                    break
                }
            }
        }
    }
    
    func presentMapVC() {
    
        let mapNavigationVC = self.storyboard?.instantiateViewControllerWithIdentifier("mapViewNavController") as! UINavigationController
        let mapVC = mapNavigationVC.viewControllers[0] as! MapViewVC
        mapVC.delegate = self
        mapVC.gate = gate
        self.navigationController?.presentViewController(mapNavigationVC, animated: true, completion: nil)
        
        
    }
    
    //mapVC Delegate
    func didFinishPickingLocation(gateAnnotation: MKPointAnnotation?) {

        if let gateAnnotation = gateAnnotation {
            let locationHeader = headers[2]
            locationHeader.selected = false
            visibleSections[2] = false
            locationHeader.animateNewText(locationHeaderTitles[1])
            let authenticated = authenticateGate()
            if authenticated.authenticated {
                showDoneButton()
            }
        }
    }

    //MARK: - AutomaticCell Delegate
    
    func didChangeGateAutomaticMode(isAutomatic: Bool) {
        let header = headers[3]
        header.animateNewText(automaticHeaderTitles[isAutomatic.hashValue])        
        tableView.reloadSections(NSIndexSet(index: 3), withRowAnimation: .Automatic)
    }
    
    //MARK: - Configure State


    func configureWithState(gateState: GateEditorState) {
        switch gateState {
           
        case .NewGate:

            gate = Gate.instansiateWithZero()
            gate.shouldCall = false
            Model.shared.context?.save(nil)
            hideDoneButton()
            hideDeleteButton()
      
        case .EditGate:
            break
        }
    }
    
    //MARK: - Hide Sow Done Button
    
    func hideDoneButton() {
        self.doneButton.enabled = false
    }
    
    func showDoneButton() {
        self.doneButton.enabled = true
    }
    
    func hideDeleteButton() {
        self.deleteButton.enabled = false
    }

    //MARK: - Button Actions
    func doneButtonClicked(sender: AnyObject) {
    
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
    
    //MARK: - Address Book
    
    func addressBookAction() {
        //show address nav controller
    
        let addressBookController = ABPeoplePickerNavigationController()
        addressBookController.peoplePickerDelegate = self
        self.presentViewController(addressBookController, animated: true, completion: nil)
    }
    
    func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!,
        didSelectPerson person: ABRecord!) {
            
            
        var gateName = ""
        var gatePhoneNumber = ""
        
        //first name
        let firstNameTemp = ABRecordCopyValue(person, kABPersonFirstNameProperty)
        let firstName: NSObject! = Unmanaged<NSObject>.fromOpaque(firstNameTemp.toOpaque()).takeRetainedValue()
        
        if let firstName = firstName{
            gateName = firstName as! String
            println("firstName: \(firstName)")
        }
        else {
            println("fristName is nil")
        }
            
        
        //last name
        let lastNameTemp = ABRecordCopyValue(person, kABPersonLastNameProperty)
        if let lastNameTemp = lastNameTemp {
            
            let lastName: NSObject! = Unmanaged<NSObject>.fromOpaque(lastNameTemp.toOpaque()).takeRetainedValue()
        
            if let lastName = lastName {
                gateName = gateName + " " + (lastName as! String)
                println("gate name including lastName: \(gateName)")
            }
        }
            
        else {
            println("lastName is nil")
  
        }
       
            var pho: ABMultiValueRef
            let phoneV : Unmanaged<AnyObject>? = ABRecordCopyValue(person, kABPersonPhoneProperty)
            
            if let phonehasv = phoneV {
                pho = phoneV!.takeUnretainedValue() as ABMultiValueRef
            
            //.takeUnretainedValue() as ABMultiValueRef
        
            
            
        if ABMultiValueGetCount(pho) > 0
        {
            var phones: ABMultiValueRef = ABRecordCopyValue(person, kABPersonPhoneProperty).takeUnretainedValue() as ABMultiValueRef
            
                for var index = 0; index < ABMultiValueGetCount(phones); ++index{
                    
                    let currentPhoneLabel = ABMultiValueCopyLabelAtIndex(phones, index).takeUnretainedValue() as CFStringRef as String
                    let currentPhoneValue = ABMultiValueCopyValueAtIndex(phones, index).takeUnretainedValue() as! CFStringRef as String
                    
                    gatePhoneNumber = currentPhoneValue
                    println("phone value \(currentPhoneValue)")
                    println("phone label \(currentPhoneLabel)")
                    break
                    
                }
            
        }
            }
            println("final name: \(gateName)")
            println("final phone: \(gatePhoneNumber)")
            
            updateGateAndUIFromAddressBook(gateName , gatePhoneNumber: gatePhoneNumber)

    }
    
    func updateGateAndUIFromAddressBook(gateName: String , gatePhoneNumber: String){
        
        //close headers 
        //update header labels

        if gateName != "" {
            let gateNameHeader = headers[0]
            gateNameHeader.selected = false
            gateNameHeader.setIdeleState()
            gateNameHeader.titleLabel.text = gateName
            gateNameHeader.titleLabel.textColor = UIColor.darkGrayColor()
            gate.name = gateName
        }

        if gatePhoneNumber != "" {
            let gatePhoneHeader = headers[1]
            gatePhoneHeader.selected = false
            gatePhoneHeader.setIdeleState()
            gatePhoneHeader.titleLabel.text = gatePhoneNumber
            gatePhoneHeader.titleLabel.textColor = UIColor.darkGrayColor()
            gate.phoneNumber = gatePhoneNumber
        }
        
    }

    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, shouldContinueAfterSelectingPerson person: ABRecord!, property: ABPropertyID, identifier: ABMultiValueIdentifier) -> Bool {
        return false
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, shouldContinueAfterSelectingPerson person: ABRecord!) -> Bool {
        
        
        return false
    }
    
    // MARK: - Authenticate Gate

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
    
 
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
         if segue.identifier == "cancelButtonSegue" {
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
