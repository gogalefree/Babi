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
import Contacts
import ContactsUI

enum GateEditorState {
    case newGate
    case editGate
}

class GateEditorVC: UIViewController, UITableViewDataSource, UITableViewDelegate, GateEditorHeaderViewDelegate, GateAutomaticCellDelegate,UIScrollViewDelegate, ABPeoplePickerNavigationControllerDelegate, MapVCDelegate, CNContactPickerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var doneButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    var addressBookButton: UIBarButtonItem!
    let addressBookRef: ABAddressBook = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()

    fileprivate let kTableViewHeaderHeight: CGFloat = 160.0
    
    
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
        
        //let doneImage = UIImage(named: "tick10.png")
        let gmdDoneImage = UIImage(named: "ic_done.png")
        self.doneButton = UIBarButtonItem(image: gmdDoneImage, style: UIBarButtonItemStyle.plain, target: self, action: #selector(GateEditorVC.doneButtonClicked(_:)))
        
        //let deleteImage = UIImage(named: "garbage11.png")
        let gmdDeleteImage = UIImage(named: "ic_delete.png")
        self.deleteButton = UIBarButtonItem(image: gmdDeleteImage, style: UIBarButtonItemStyle.plain, target: self, action: #selector(GateEditorVC.deleteAction))
        
        //let addressBookImage = UIImage(named: "address20.png")
        let gmdAddressBookImage = UIImage(named: "ic_import_contacts.png")

        self.addressBookButton = UIBarButtonItem(image: gmdAddressBookImage, style: UIBarButtonItemStyle.plain, target: self, action: #selector(GateEditorVC.addressBookAction))
        
        self.navigationItem.rightBarButtonItems = [self.doneButton, self.deleteButton, self.addressBookButton]
    }
    
    //MARK: - Table View delegate datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        /*
           0 gate name
           1 gate phone number
           2 gate location
           3 gate mode
           4 fence header
         */
        return 4
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        switch indexPath.section {
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "GateEditorLocationCell", for: indexPath) as! GateEditorLocationCell
            return cell
            
        case 3:
            if indexPath.row == 0 {
                //automatic cell
                let cell = tableView.dequeueReusableCell(withIdentifier: "GateEditorAutomaticCell", for: indexPath) as! GateEditorAutomaticCell
                cell.gate = gate
                cell.delegate = self
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "GateEditorDistanceToCallCell", for: indexPath) as! GateEditorDistanceCell
                cell.gate = gate
                return cell
            }
            
        default:
            let cell = UITableViewCell()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
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
            
            if self.state == .editGate {
                headerView.setGateTitles(gate)
            }
            
            headers.append(headerView)
            return headerView
        }
            
        else{ return headers[section]}
    }
    
    
    // MARK: - Headers Delegate
    
    func headerTapped(_ headerView: GateEditorTVCHeaderView) {
        print("gates tvc header tappd: \(headerView.headerRoll.rawValue)")
        
        //if the header is location header then we show the map vc
        if headerView.headerRoll == GateEditorTVCHeaderView.Roll.gateLocation {
            presentMapVC()
        }
        
        let section = headerView.section
        let visible = visibleSections[section!]
        
        if visible && section! < 3 {
            
            showDoneButtonIfNeeded()
        }
        
        visibleSections[section!] = !visible
        
        //mode section
        if section == 3 {
            tableView.reloadSections(IndexSet(integer:section!), with: .automatic)
        }
        
        //if a header becomes selected - hide all other headers
        if headerView.selected {
            hideHeaders(section)
        }
        
    }
    
    func hideHeaders(_ visibleSection: Int?) {
        
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
                    tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                default:
                    break
                }
            }
        }
    }
    
    func presentMapVC() {
        
        let mapNavigationVC = self.storyboard?.instantiateViewController(withIdentifier: "mapViewNavController") as! UINavigationController
        let mapVC = mapNavigationVC.viewControllers[0] as! MapViewVC
        mapVC.delegate = self
        mapVC.gate = gate
        self.navigationController?.present(mapNavigationVC, animated: true, completion: nil)
        
        
    }
    
    //mapVC Delegate
    func didFinishPickingLocation(_ gateAnnotation: MKPointAnnotation?) {
        
        if  gateAnnotation != nil {
            let locationHeader = headers[2]
            locationHeader.selected = false
            visibleSections[2] = false
            let authenticated = authenticateGate()
            if authenticated.authenticated {
                showDoneButton()
            }
            
            let location = CLLocation(latitude: gate.latitude, longitude: gate.longitude)
            let coder = CLGeocoder()
            coder.reverseGeocodeLocation(location) { (placemarks,error) in
                
                if error != nil || placemarks?.count == 0 {
                    locationHeader.animateNewText(locationHeaderTitles[1])
                    return
                }
                
                guard let placemarks = placemarks else  { return }
                if let placemark = placemarks.first  {
                let name = placemark.name
                if let name = name {
                    self.gate.placemarkName = name
                    locationHeader.animateNewText(name)
                    locationHeader.setIconTintColor()
                }
                }
            }
        }
    }
    
    
    
    //MARK: - AutomaticCell Delegate
    
    func didChangeGateAutomaticMode(_ isAutomatic: Bool) {
        
        let header = headers[3]
        header.animateNewText(automaticHeaderTitles[isAutomatic.hashValue])
        tableView.reloadSections(IndexSet(integer: 3), with: .automatic)
    }
    
    //MARK: - Configure State
    
    
    func configureWithState(_ gateState: GateEditorState) {
        switch gateState {
            
        case .newGate:
            
            gate = Gate.instansiateWithZero()
            gate.shouldCall = false
            do {
                try Model.shared.context?.save()
            } catch _ {
            }
            hideDoneButton()
            hideDeleteButton()
            
        case .editGate:
            break
        }
    }
    
    //MARK: - Hide Sow Done Button
    
    func hideDoneButton() {
        self.doneButton.isEnabled = false
    }
    
    func showDoneButton() {
        self.doneButton.isEnabled = true
    }
    
    func hideDeleteButton() {
        self.deleteButton.isEnabled = false
    }
    
    //MARK: - Button Actions
    func doneButtonClicked(_ sender: AnyObject) {
        
        let gateAuthenticated = authenticateGate()
        if !gateAuthenticated.authenticated {showAlert(gateAuthenticated.section!)}
        else {self.performSegue(withIdentifier: "unwindToGatesTVC", sender:self)}
    }
    
    func deleteAction() {
        let alert = UIAlertController(title: "Sure you want to delete?", message: "\(gate.name)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action) -> Void in
            
            self.performSegue(withIdentifier: "unwindwithdeletesegue", sender: self)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Address Book
    
    func addressBookAction() {
        //show address nav controller
        getContacts()
//        
//        let authorizationStatus = ABAddressBookGetAuthorizationStatus()
//        switch authorizationStatus {
//        case .denied, .restricted:
//            promptForAddressBookRequestAccess()
//            
//        case .authorized:
//            presentAddressBook()
//            print("Authorized")
//        case .notDetermined:
//            promptForAddressBookRequestAccess()
//            print("Not Determined")
//        }
    }
    
    func promptForAddressBookRequestAccess() {
        
        ABAddressBookRequestAccessWithCompletion(addressBookRef) {
            (granted, error) in
            DispatchQueue.main.async {
                if !granted {
                    log.warning("Did Not Authorize contacts for iOS < 9")
                } else {
                    self.presentAddressBook()
                    log.info("Authorized contacts for iOS < 9")

                }
            }
        }
    }
    

    func presentAddressBook() {
        let addressBookController = ABPeoplePickerNavigationController()
        addressBookController.peoplePickerDelegate = self
        self.present(addressBookController, animated: true, completion: nil)
    }
    
    func peoplePickerNavigationControllerDidCancel(_ peoplePicker: ABPeoplePickerNavigationController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func peoplePickerNavigationController(_ peoplePicker: ABPeoplePickerNavigationController,
                                          didSelectPerson person: ABRecord) {
        
        
        var gateName = ""
        var gatePhoneNumber = ""
        
        //first name
        let firstNameTemp = ABRecordCopyValue(person, kABPersonFirstNameProperty)
        let firstName: NSObject! = Unmanaged<NSObject>.fromOpaque(firstNameTemp!.toOpaque()).takeRetainedValue()
        
        if let firstName = firstName{
            gateName = firstName as! String
            print("firstName: \(firstName)")
        }
        else {
            print("fristName is nil")
        }
        
        
        //last name
        let lastNameTemp = ABRecordCopyValue(person, kABPersonLastNameProperty)
        if let lastNameTemp = lastNameTemp {
            
            let lastName: NSObject! = Unmanaged<NSObject>.fromOpaque(lastNameTemp.toOpaque()).takeRetainedValue()
            
            if let lastName = lastName {
                gateName = gateName + " " + (lastName as! String)
                print("gate name including lastName: \(gateName)")
            }
        }
            
        else {
            print("lastName is nil")
            
        }
        
        var pho: ABMultiValue
        let phoneV : Unmanaged<AnyObject>? = ABRecordCopyValue(person, kABPersonPhoneProperty)
        
        if  phoneV != nil {
            pho = phoneV!.takeUnretainedValue() as ABMultiValue
            
            
            if ABMultiValueGetCount(pho) > 0
            {
                let phones: ABMultiValue = ABRecordCopyValue(person, kABPersonPhoneProperty).takeUnretainedValue() as ABMultiValue
                
                for index in 0 ..< ABMultiValueGetCount(phones){
                    
                    let currentPhoneLabel = ABMultiValueCopyLabelAtIndex(phones, index).takeUnretainedValue() as CFString as String
                    let currentPhoneValue = ABMultiValueCopyValueAtIndex(phones, index).takeUnretainedValue() as! CFString as String
                    
                    gatePhoneNumber = currentPhoneValue
                    print("phone value \(currentPhoneValue)")
                    print("phone label \(currentPhoneLabel)")
                    break
                    
                }
                
            }
        }
        print("final name: \(gateName)")
        print("final phone: \(gatePhoneNumber)")
        
        updateGateAndUIFromAddressBook(gateName , gatePhoneNumber: gatePhoneNumber)
        
    }
    
    func updateGateAndUIFromAddressBook(_ gateName: String , gatePhoneNumber: String){
        
        //close headers
        //update header labels
        
        if gateName != "" {
            let gateNameHeader = headers[0]
            gateNameHeader.selected = false
            gateNameHeader.setIdeleState()
            gateNameHeader.titleLabel.text = gateName
            gateNameHeader.titleLabel.textColor = UIColor.darkGray
            gate.name = gateName
            gateNameHeader.setIconTintColor()
        }
        
        if gatePhoneNumber != "" {
            let gatePhoneHeader = headers[1]
            gatePhoneHeader.selected = false
            gatePhoneHeader.setIdeleState()
            gatePhoneHeader.titleLabel.text = gatePhoneNumber
            gatePhoneHeader.titleLabel.textColor = UIColor.darkGray
            gate.phoneNumber = gatePhoneNumber
            gatePhoneHeader.setIconTintColor()
        }
        
        showDoneButtonIfNeeded()
    }
    
    
    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        shouldContinueAfterSelectingPerson person: ABRecord,
        property: ABPropertyID, identifier: ABMultiValueIdentifier) -> Bool {
        return false
    }
    
    func peoplePickerNavigationController(
        _ peoplePicker: ABPeoplePickerNavigationController,
        shouldContinueAfterSelectingPerson person: ABRecord) -> Bool {
        return false
    }
    
    //MARK: Contacts
    
    func getContacts() {
        
        if #available(iOS 9.0, *) {
            
            let store = CNContactStore()
            if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                store.requestAccess(for: .contacts, completionHandler: {
                    (authorized: Bool, error: Error?) -> Void in
                    if authorized {
                        self.presentContactsUI(store)
                        log.info("authorized contacts iOS > 9")

                    }
                })
            } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                self.presentContactsUI(store)
            } else {
                //no contacts permission
                log.warning("DID NOT authorize contacts iOS > 9")

            }
            
        } else {
            // Fallback on earlier versions
            promptForAddressBookRequestAccess()
            log.info("request contacts for iOS < 9")
        }
    }
    
    @available(iOS 9.0, *)
    func presentContactsUI(_ store: CNContactStore) {
        
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        self.present(contactPicker, animated: true, completion: nil)

    }
    
    @available(iOS 9.0, *)
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    
        let name = contact.givenName
        let middleName = contact.middleName
        let familyName = contact.familyName 
        let numbers = contact.phoneNumbers

        var gateName = name

        if !middleName.isEmpty {
            gateName += " " + middleName
        }
        if !familyName.isEmpty {
            gateName += " " + familyName
        }
        
        var phoneNumber = ""
        
        if let number = numbers.first?.value.stringValue {
            phoneNumber = number
        }
        
        updateGateAndUIFromAddressBook(gateName, gatePhoneNumber: phoneNumber)
    }
    
    
    // MARK: - Authenticate Gate
    
    func showDoneButtonIfNeeded() {
        let authenticated = authenticateGate()
        if authenticated.authenticated {showDoneButton()}
        else {hideDoneButton()}
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
    
    func showAlert(_ section: Int) {
        var message = ""
        switch section {
        case 0:
            message = "Please Enter Gate Name"
        case 1:
            message = "Please Enter Gate Phone Number"
        default:
            message = "Unknown error"
        }
        let alert = UIAlertController(title: message, message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "cancelButtonSegue" {
            //if state is .NewGate and the user has canceled
            //we need to delete the new gate from the context
            if self.state == .newGate {
                let context = Model.shared.context
                if let context = context {
                    context.delete(gate)
                    do {
                        try context.save()
                    } catch _ {
                    }
                }
            } 
        }
    }
}
