//
//  GatesTableViewController.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI
import MessageUI
import Firebase

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class GatesTableViewController: UITableViewController, SwipeableCellDelegate, CNContactPickerDelegate, MFMessageComposeViewControllerDelegate, UIPopoverPresentationControllerDelegate {
    
       
    var cellsCurrentlyEditing :NSMutableSet!
    var gates = Model.shared.gates() as [Gate]?
    var selectedIndexPath: IndexPath!
    var shouldUpdateLocation = true
    var guestOwnerDialogVC: GusetOwnerDialogVC?
    
    var sharedGate: Gate?
    var gateShare: GateShare?
    var shareId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cellsCurrentlyEditing = NSMutableSet()
        if gates == nil || gates?.count == 0 {
            gates = [Gate]()
        }
        
        
        let numberColor = #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)
        navigationController?.navigationBar.barTintColor = numberColor
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SwipeableCellTableViewCell
        cell.gate = gates![indexPath.row]
        cell.indexPath = indexPath
        cell.delegate = self
        let gate = gates![indexPath.row] as Gate
        setCellDistanceLabels(cell: cell, gate: gate)
        
        if self.cellsCurrentlyEditing.contains(indexPath) {
            cell.openCell()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let gates = gates {
            return gates.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none

    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
      /*  tableView.deselectRow(at: indexPath, animated: true)
        let gate = gates![indexPath.row]
        let phoneNumber = gate.phoneNumber
         honeDialer.callGate(phoneNumber)
         */
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
        }
        else {
            print("Unhandled Editing style")
        }
    }
    
    func cellDidOpen(_ cell: UITableViewCell) {
        let currentEditingIndexPath = self.tableView.indexPath(for: cell)
        self.cellsCurrentlyEditing.add(currentEditingIndexPath!)
    }
    
    func cellDidClose(_ cell: UITableViewCell) {
        
        self.cellsCurrentlyEditing.remove(self.tableView.indexPath(for: cell)!);
    }
        
    func settingsButtonAction(_ cell: SwipeableCellTableViewCell) {
        
        if !cell.gate.isGuest {
        
            //present gate editor for editing
            Model.shared.stopLocationUpdates()
            let indexPath = tableView.indexPath(for: cell)!
            self.selectedIndexPath = indexPath
            let gate = gates![indexPath.row]
            let gateEditorNavController = self.storyboard?.instantiateViewController(withIdentifier: "gateEditorNavController") as! UINavigationController
            gateEditorNavController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            let gateEditor = gateEditorNavController.viewControllers[0] as! GateEditorVC
            gateEditor.gate = gate
            gateEditor.state = .editGate
            self.navigationController?.present(gateEditorNavController, animated: true, completion: nil)
            Model.shared.locationNotifications.cancelLocalNotification(gate)
        } else {
            //Guest Gate. delete the gate
            
            print("delete gate as guest")
            //delete gate
            let indexPath = cell.indexPath
            let gate = gates![(indexPath!.row)]
            if cellsCurrentlyEditing.contains(indexPath!){
                cellsCurrentlyEditing.remove(indexPath!)
            }
            
            let alert = UIAlertController(title: "Delete ", message: "\(gate.name)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action) -> Void in
                
                Model.shared.stopLocationUpdates()
                self.tableView.beginUpdates()
                self.gates!.remove(at: (indexPath?.row)!)
                self.tableView.deleteRows(at: [indexPath!], with: .automatic)
                Model.shared.deleteGate(gate)
                self.tableView.endUpdates()
                
                let container =
                    self.navigationController?.parent as!MainContainerController
                container.showNoMessageVCIfNeeded()
                Model.shared.startLocationUpdates()
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func automaticButtonAction(_ cell: SwipeableCellTableViewCell) {
        
        let indexPath = tableView.indexPath(for: cell)!
        self.selectedIndexPath = indexPath
        let gate = gates![indexPath.row]
        gate.automatic = !gate.automatic
        
        if gate.automatic {
            Model.shared.locationNotifications.registerGateForLocationNotification(gate)
        }
        else {
            Model.shared.locationNotifications.cancelLocalNotification(gate)
        }
    }
    
    //MARK: Share gate
    func shareButtonClicked(_ cell: SwipeableCellTableViewCell) {
        cell.resetConstraintContstantsToZero(true, notifyDelegateDidClose: true)
        self.selectedIndexPath = cell.indexPath
        let gate = cell.gate
        sharedGate = gate
        getContacts()
    }
    
    @IBAction func presentGateEditor(_ sender: AnyObject) {
        //for creating a new gate
        Model.shared.stopLocationUpdates()

        let gateEditorNavController = self.storyboard?.instantiateViewController(withIdentifier: "gateEditorNavController") as! UINavigationController
        gateEditorNavController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        let gateEditor = gateEditorNavController.viewControllers[0] as! GateEditorVC
        gateEditor.state = .newGate
        self.navigationController?.present(gateEditorNavController, animated: true, completion: nil)
    }
    
    func presentSharesPopup(indexPath: IndexPath) {
        print("present popup on table view controller)")
        let nav = storyboard?.instantiateViewController(withIdentifier: "popnav") as! UINavigationController
        let vc = nav.viewControllers[0] as! InvitationsPOPTVC
        vc.shares = gates![indexPath.row].shares
        nav.modalPresentationStyle = .popover
        nav.preferredContentSize = CGSize(width: 300, height: 300)

        nav.popoverPresentationController?.permittedArrowDirections = .any
        nav.popoverPresentationController?.delegate = self
        nav.popoverPresentationController?.sourceView = (tableView.cellForRow(at: indexPath) as! SwipeableCellTableViewCell).invitationsButton
        nav.popoverPresentationController?.sourceRect = (tableView.cellForRow(at: indexPath) as! SwipeableCellTableViewCell).invitationsButton.bounds
        self.present(nav, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // return UIModalPresentationStyle.FullScreen
        return UIModalPresentationStyle.none
    }
    
    @IBAction func unwindFromGateEditorVC(_ segue: UIStoryboardSegue) {
       //created new gate or finished editing
        let gateEditor = segue.source as! GateEditorVC
        let gate = gateEditor.gate
        
        //Save Gate
        //the should call inits with false so calls are'nt initiated till the gate is completly configured

        gate?.shouldCall = true
        
        do {
            try Model.shared.context!.save()
        } catch let error1 as NSError { print(error1)}
        Model.shared.startLocationUpdates()
        
        //register notification if needed
        //we dont register local notifications for now
        Model.shared.locationNotifications.registerGateForLocationNotification(gate!)
        
        if gateEditor.state == GateEditorState.editGate {
            if let selectedIndexPath = self.selectedIndexPath {
                tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
                self.updateGateSharesForGate(gate)
            }
            
            return
        }
        
        //notify container to remove no gates message
        let container = self.navigationController?.parent as! MainContainerController
        container.hideNoMessageVCIfNeeded()
       
        tableView.beginUpdates()
        gates?.insert(gate!, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
    
    @IBAction func unwindWithDeleteButtonFromEditorVC(_ segue: UIStoryboardSegue) {
        //delete gate
        let indexPath = self.selectedIndexPath
        let gate = gates![(indexPath?.row)!]
        if cellsCurrentlyEditing.contains(indexPath!){
            cellsCurrentlyEditing.remove(indexPath!)
        }

        tableView.beginUpdates()
        gates!.remove(at: (indexPath?.row)!)
        tableView.deleteRows(at: [indexPath!], with: .automatic)
        Model.shared.deleteGate(gate)
        tableView.endUpdates()
        
        let container =
        self.navigationController?.parent as!MainContainerController
        
        container.showNoMessageVCIfNeeded()
        Model.shared.startLocationUpdates()

    }
    
    func locationUpdated() {
        
        if let gates = gates {
            
            if shouldUpdateLocation {
                
                for (index , gate) in gates.enumerated() {
                    
                    let indexpath = IndexPath(row: index, section: 0)
                    let cell = tableView.cellForRow(at: indexpath) as? SwipeableCellTableViewCell
                    

                    if let cell = cell {
                        informOwnerIfNeeded(cell, gate, gateShare: nil)
                        setCellDistanceLabels(cell: cell, gate: gate)
                    }
                }
                
                reorderGates()
            }
        }
    }
    
    func setCellDistanceLabels(cell: SwipeableCellTableViewCell, gate: Gate) {
        
        let title = gate.name
        
        
        var distance = gate.distanceFromUserLocation() / 1000 < 1 ? gate.distanceFromUserLocation() : gate.distanceFromUserLocation() / 1000
        distance = distance > 1000 ? 999 : distance
        let unit = gate.distanceFromUserLocation() / 1000 < 1 ? "m" : "km"
        
        cell.itemText = title
        cell.distanceUnitLabel.text = unit
        cell.distanceNumberLabel.text = String(Int(distance))
    }
    
    func reorderGates() {
        
        
        var didMove = false
        shouldUpdateLocation = false
        if self.gates != nil && self.gates?.count > 1{
            
            for index in 0  ..< self.gates!.count - 1  {
                
                let firstGate = self.gates![index]
                let seccondGate = self.gates![index+1]
                
                if seccondGate.distanceFromUserLocation() < firstGate.distanceFromUserLocation() {
                   
                    didMove = true
                    
                    let fromIndexPath = IndexPath(row: index+1, section: 0)
                    let toIndexPath = IndexPath(row: index, section: 0)
                    
                    self.gates!.remove(at: index+1)
                    self.gates!.insert(seccondGate, at: index)
                    tableView.moveRow(at: fromIndexPath, to: toIndexPath)
                    
                    if self.cellsCurrentlyEditing.contains(fromIndexPath){
                        self.cellsCurrentlyEditing.remove(fromIndexPath)
                        self.cellsCurrentlyEditing.add(toIndexPath)
                    }
                   break
                }
            }
            
            if didMove {
                reorderGates()
            }
        }
        shouldUpdateLocation = true
//        Model.shared.setUserRegion()
    }

    
    @IBAction func unwindeWithCancelButtonFromGateEditor(_ segue: UIStoryboardSegue) {
        print("canceked and back to gates table view controller", terminator: "")
    }

    @IBAction func toogleSleepMode() {
        //notifies the container that sleep mode button pressed

        let container = self.navigationController?.parent as! MainContainerController
        container.toogleSleepMode()
    }
    
    //Contacts
    
    func getContacts() {
        
        if #available(iOS 9.0, *) {
            
            let store = CNContactStore()
            if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                store.requestAccess(for: .contacts, completionHandler: {
                    (authorized: Bool, error: Error?) -> Void in
                    if authorized {
                        self.presentContactsUI(store)
                    }
                })
            } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                self.presentContactsUI(store)
            } else {
                //no contacts permission
            }
            
        } else {
            // Fallback on earlier versions
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
        
        var guestName = name
        
        if !middleName.isEmpty {
            guestName += " " + middleName
        }
        if !familyName.isEmpty {
            guestName += " " + familyName
        }
        
        var phoneNumber = ""
        
        if let number = numbers.first?.value.stringValue {
            phoneNumber = number
        }
        
        self.navigationController?.dismiss(animated: true, completion: {
        
            self.presentShareCard(guestName, guestPhoneNumber: phoneNumber)
        })
        
    }
    
    func presentShareCard(_ guestName: String, guestPhoneNumber: String) {
        
        guard let gate = sharedGate else {return}
        let cardVC = storyboard?.instantiateViewController(withIdentifier: "CardVC") as! CardVC
        cardVC.delegate = self
        cardVC.guestName = guestName
        cardVC.sharedGate = gate
        cardVC.guestPhoneNumber = guestPhoneNumber
        let navVC = UINavigationController(rootViewController: cardVC)
        navVC.modalPresentationStyle = .overCurrentContext
        self.navigationController?.present(navVC, animated: true, completion: nil)
    }

}

//MARK: CardVC Delegate

extension GatesTableViewController: CardVCDelegate {
    
    func cardVCContinueAction(_ cardVC: CardVC) {
        
        guard let userUid = FireBaseController.shared.userUid,
            let gateToShare = cardVC.sharedGate
            else {
                print (#function + "no user id. exit!")
                return
            }
        
        let phoneNumber = cardVC.guestPhoneNumber
        let gateShare = GateShare(gate: gateToShare, ownerUid: userUid, guestname: cardVC.guestName)
        self.gateShare = gateShare
        let message = gateShare.invitationMessage()
        //let actionSheet = prepareActionSheet(message, phoneNumber)
        
        let controller = MFMessageComposeViewController()
        controller.body = message
        controller.recipients = [phoneNumber]
        controller.messageComposeDelegate = self
        self.present(controller, animated: true, completion: nil)
      
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
        
        if result != .sent {
            print("cancelled)")
        }
            
        else {
            print("sent")

            guard let gateShare = self.gateShare else {return}
            FireBaseController.shared.postGateShare(gateShare)
            //self.sharedGate?.shares.append(gateShare)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sutupFBObservers()
        setupObserversAsGuest()
        self.registerAppNotifications()
        
        let ownerId     = "lto8rQ8GcuQ6Tq10fCrfqB4Ao2v2"
        let shareToken  = "abcdesgtac"
        let shareId     =  "share10"
        FireBaseController.shared.fetchGateShareasGuest(ownerId, shareToken, shareId)
    
        //TODO: Delete in prod
        let kNavVCID = "guestOwnerNav"
        let nav = storyboard?.instantiateViewController(withIdentifier:kNavVCID) as! UINavigationController
        let vc = nav.viewControllers[0] as! GusetOwnerDialogVC
        vc.gate = self.gates![1]
        self.guestOwnerDialogVC = vc
        nav.modalTransitionStyle = .crossDissolve
        nav.modalPresentationStyle = .overCurrentContext
        self.navigationController?.present(nav, animated: true) 

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        FireBaseController.shared.currentUserPath.removeAllObservers()
        self.removeObserversAsGuest()
        NotificationCenter.default.removeObserver(self)
    }
}

extension GatesTableViewController {
    
    func sutupFBObservers() {
        
        let currentUserPath = FireBaseController.shared.currentUserPath
        print("vurrent user path: " + (currentUserPath?.description())!)
        //setup Observers
        //an owner fetches his gate shares and observes them.
        currentUserPath?.observe(.childAdded) {snapshot in self.gateShareAddedAsOwner(snapshot)}
        currentUserPath?.observe(.childChanged) {snapshot in self.gateShareChangedAsOwner(snapshot)}
        currentUserPath?.observe(.childRemoved) {snapshot in self.gateShareRemovedAsOwner(snapshot)}
        
        
        
        //a guest observs his invitations in case it got cancelled by the owner
    }
    
    //this is where the owner gets his shres as owner in the next run
    func gateShareAddedAsOwner(_ snapshot: FIRDataSnapshot) {
        
        guard let gateShare = GateShare(snapshot: snapshot) else {return}
        addGateshareAndUpdateUI(gateShare)
    }
    
    func gateShareChangedAsOwner(_ snapshot: FIRDataSnapshot) {
        print(snapshot.value as Any)
        guard let gateShare = GateShare(snapshot: snapshot) else {
            
            print("cant create gate shate: " + #function)
            return
        }
        
        guard let gate = self.gateForGateshare(gateShare) else {
            
            print("cant find gate: " + #function)

            return
        }

        guard let index = self.gates?.index(of: gate) else {
           
            print("cant find gate index: " + #function)
            return
        }
        if gateShare.ownerShouldFireCall {
           
            let cell  = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! SwipeableCellTableViewCell
            presentOpenGateVCAsGuest(cell, gate, gateShare: gateShare)
            snapshot.ref.child(kOwnerShouldFireKey).setValue(false)
        }
    }
    
    func gateShareRemovedAsOwner(_ snapshot: FIRDataSnapshot) {
        
        guard let gateShare = GateShare(snapshot: snapshot) else {return}
        guard let gate = self.gateForGateshare(gateShare) else {return}
        gate.removeGateShare(gateShare)
        print(#function + "shareReomed as owner")
        print(snapshot.key)
        print(snapshot.value as Any)
        self.tableView.reloadData()
    }
    
    func addGateshareAndUpdateUI(_ gateshare: GateShare) {
        guard let gate = self.gateForGateshare(gateshare) else {return}
        let gateshareExists = gate.hasGateshare(gateshare)
        if !gateshareExists {
            gate.shares.append(gateshare)
            self.tableView.reloadData()
        }
    }
    
    func gateForGateshare(_ gateShare: GateShare) -> Gate? {
        let filtered = self.gates?.filter {gate in gateShare.gateUid == gate.uid}
        return filtered?.first
    }
    
    func updateGateSharesForGate(_ gate: Gate?) {
        guard let gate = gate else {return}
        for share in gate.shares {
            if share.gateName != gate.name ||
            share.placemarkName != gate.placemarkName ||
            share.longitude != gate.longitude ||
            share.latitude != gate.longitude {
             
                share.gateName = gate.name
                share.placemarkName = gate.placemarkName
                share.longitude = gate.longitude
                share.latitude = gate.latitude
                FireBaseController.shared.postGateShare(share)
            }
        }
    }
    
    //Mark: Notifications actions 
    
    func updateTableWithNewInvitation() {
        self.removeObserversAsGuest()
        self.gates = Model.shared.gates()
        tableView.reloadData()
        self.setupObserversAsGuest()
    }
}

//Mark: setup Firebase Observers as guest
extension GatesTableViewController {
    
    func registerAppNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(GatesTableViewController.locationUpdated), name: NSNotification.Name(rawValue: kLocationUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableWithNewInvitation), name: NSNotification.Name(rawValue: knewGateAsGuestNotification), object: nil)
    }
    
    func removeObserversAsGuest() {
        let dbRef = FIRDatabase.database().reference()
        guard let gates = self.gates else {return}
        for gate in gates {
            
            if gate.isGuest == false || gate.shareId == "shareId" || gate.ownerUid == "ownerUid" {continue}
            
            let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!)
            path.removeAllObservers()
        }
    }
    
    func setupObserversAsGuest() {
    
        let dbRef = FIRDatabase.database().reference()
        guard let gates = self.gates else {return}
        for gate in gates {
            
            if gate.isGuest == false || gate.shareId == "shareId" || gate.ownerUid == "ownerUid" {continue}
            
            let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!)
            
            path.observe(.childChanged) {snapshot in self.gateShareChangedAsGuest(snapshot)}
            path.observe(.childRemoved) {snapshot in self.gateShareRemovedAsGuest(snapshot)}
        }
    }
    
    func gateShareChangedAsGuest(_ snapshot: FIRDataSnapshot) {
        //get notified only with the changes key
        print(snapshot.value as Any)
        print(snapshot.key)
        
        let components = String(describing: snapshot.ref).components(separatedBy: "/")
        let share = components.filter { item in item.hasPrefix("share")}
        guard let shareId = share.first else {return}
        let ownerUidIndex = components.count - 3
        let ownerUid = components[ownerUidIndex]
        guard let gates = Model.shared.gates() else {return}
        let gatesToUpdate = gates.filter { gate in gate.shareId == shareId && gate.ownerUid == ownerUid }
        guard let gateToUpdate = gatesToUpdate.first else {return}
        
        switch snapshot.key {
            
        case kGateNamekey:
            gateToUpdate.name = snapshot.value as! String
            
        case kLatitudeKey:
            gateToUpdate.latitude = snapshot.value as! Double
        
        case kLongitudeKey:
            gateToUpdate.longitude  = snapshot.value as! Double
            
        case kPlacemarkNameKey:
            gateToUpdate.placemarkName = snapshot.value as? String ?? ""
            
        case kOwnerShouldFireKey:
            let shouldFire = snapshot.value as? Bool ?? false
            if !shouldFire {
                self.guestOwnerDialogVC!.ownerDailing()
            }
            default:
            break
        }
        
        
        
        do {
            try Model.shared.context?.save()
        } catch  {
            print("cant save gate while creating as Guset: \(error.localizedDescription)")
        }
        
        self.gates = Model.shared.gates()
        self.tableView.reloadData()
    }
    
    func gateShareRemovedAsGuest(_ snapshot: FIRDataSnapshot) {
        //delete the gate by the share token
        print(snapshot.key)
        if snapshot.key == kShareTokenKey {
            
            guard let gateToDelete = Gate.gateAsGuestForToken(snapshot.value as? String) else {return}
            FireBaseController.shared.removeObserverAsGuest(gateToDelete)
            
            let alert = UIAlertController(title: "Invitation cancelled by owner for: ", message: "\(gateToDelete.name)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action) -> Void in
                
                Model.shared.deleteGate(gateToDelete)
                let indexToDelete = self.gates?.index(of: gateToDelete)
                guard let index = indexToDelete else {return}
                self.tableView.beginUpdates()
                self.gates?.remove(at: index)
                let ipToDelete = IndexPath(row: index, section: 0)
                self.tableView.deleteRows(at: [ipToDelete], with: .fade)
                self.tableView.endUpdates()
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //this is called when a guest arrives at the gate region
    func informOwnerIfNeeded(_ cell: SwipeableCellTableViewCell, _ gate: Gate, gateShare: GateShare?) {
        
        if gate.isGuest && gate.shouldCall && gate.userInRegion {
        
            //set firebase to Should call = true
            let dbRef = FIRDatabase.database().reference()
            let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!).child(kOwnerShouldFireKey)
            path.setValue(true)
            gate.shouldCall = false
            
            
            //show UI for calling owner
            //show the cell's call button to let uaera initiate dialog with owner
            cell.callButton.alpha = 1
            presentOpenGateVCAsGuest(cell, gate, gateShare: gateShare)
        }
        
        else if gate.isGuest && !gate.userInRegion{
            cell.callButton.animateToAlphaWithSpring(0.2, alpha: 0)
        }
    }
    
    func presentOpenGateVCAsGuest(_ cell: SwipeableCellTableViewCell, _ gate: Gate, gateShare: GateShare?) {
        let kNavVCID = "guestOwnerNav"
        let nav = storyboard?.instantiateViewController(withIdentifier:kNavVCID) as! UINavigationController
        let vc = nav.viewControllers[0] as! GusetOwnerDialogVC
        vc.gate = gate
        vc.gateShare = gateShare
        self.guestOwnerDialogVC = vc
        nav.modalTransitionStyle = .crossDissolve
        nav.modalPresentationStyle = .overCurrentContext
        self.navigationController?.present(nav, animated: true) { (finished) in}
    }
    
    func callActionAsGuest(_ cell: SwipeableCellTableViewCell) {
        informOwnerIfNeeded(cell, cell.gate, gateShare: nil)
    }

}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
