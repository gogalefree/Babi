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


class GatesTableViewController: UITableViewController, SwipeableCellDelegate, CNContactPickerDelegate, MFMessageComposeViewControllerDelegate, UIPopoverPresentationControllerDelegate {
    
//    var i = true
    var cellsCurrentlyEditing :NSMutableSet!
    var gates = Model.shared.gates() as [Gate]?
    var selectedIndexPath: IndexPath!
    var shouldUpdateLocation = true
    weak var guestOwnerDialogVC: GusetOwnerDialogVC?
    weak var guestOwnerDialogNav: UINavigationController?
    var sharedGate: Gate?
    var gateShare: GateShare?
    var shareId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.cellsCurrentlyEditing = NSMutableSet()
        if gates == nil || gates?.count == 0 {
            gates = [Gate]()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sutupFBObservers()
        setupObserversAsGuest()
        self.registerAppNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        FireBaseController.shared.currentUserPath.removeAllObservers()
        self.removeObserversAsGuest()
        NotificationCenter.default.removeObserver(self)
    }

    //MARK: Cell Delegate
      
    func automaticButtonAction(_ cell: SwipeableCellTableViewCell) {
        
        let indexPath = cell.indexPath!
        self.selectedIndexPath = indexPath
        let gate = gates![indexPath.row]
        gate.automatic = !gate.automatic
        Model.shared.saveGates()
        if gate.automatic {
            LocationNotifications.shared.registerGateForLocationNotification(gate)
        }
        else {
            LocationNotifications.shared.cancelLocalNotification(gate)
        }
    }
    
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
        LocationNotifications.shared.registerGateForLocationNotification(gate!)
        
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
    
    @IBAction func unwindeWithCancelButtonFromGateEditor(_ segue: UIStoryboardSegue) {
        print("canceked and back to gates table view controller", terminator: "")
    }

    @IBAction func toogleSleepMode() {
        //notifies the container that sleep mode button pressed

        let container = self.navigationController?.parent as! MainContainerController
        container.toogleSleepMode()
    }
}

//MARK: CardVC

extension GatesTableViewController: CardVCDelegate {
    
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
        }
    }
}

//MARK: Firebase Observers as owner
extension GatesTableViewController {
    
    func sutupFBObservers() {
        
        let currentUserPath = FireBaseController.shared.currentUserPath
        print("vurrent user path: " + (currentUserPath?.description())!)
        //setup Observers
        //an owner fetches his gate shares and observes them.
        currentUserPath?.observe(.childAdded) {snapshot in self.gateShareAddedAsOwner(snapshot)}
        currentUserPath?.observe(.childChanged) {snapshot in self.gateShareChangedAsOwner(snapshot)}
        currentUserPath?.observe(.childRemoved) {snapshot in self.gateShareRemovedAsOwner(snapshot)}
    }
    
    //this is where the owner gets his shres as owner in the next run
    func gateShareAddedAsOwner(_ snapshot: FIRDataSnapshot) {
        
        guard let gateShare = GateShare(snapshot: snapshot) else {return}
        addGateshareAndUpdateUI(gateShare)
    }
    
    func gateShareChangedAsOwner(_ snapshot: FIRDataSnapshot) {
        print(snapshot.value as Any)
        guard let gateShare = GateShare(snapshot: snapshot) else {return}
        guard let gate = self.gateForGateshare(gateShare) else {return        }
        
        if gateShare.ownerShouldFireCall {
            presentGuestOwnerDialog(gate: gate)
            snapshot.ref.child(kOwnerShouldFireKey).setValue(false)
        }
        
        if gateShare.isCancelled == true {
            //the guest has reported that the gate is open
            snapshot.ref.child(isCancelledKey).setValue(false)
            print(String(describing: self.guestOwnerDialogNav?.presentingViewController == nil))
            guard let goDialog = self.guestOwnerDialogVC else {return}
            goDialog.informOwnerGateOpen()
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
            if gateshare.ownerShouldFireCall {
                presentGuestOwnerDialog(gate: gate)
                let dbRef = FIRDatabase.database().reference()
                let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!).child(kOwnerShouldFireKey)
                path.setValue(false)
            }
        }
    }
    
    func presentGuestOwnerDialog(gate: Gate) {
        if self.guestOwnerDialogVC == nil {
            guard let index = self.gates?.index(of: gate) else {return}
            let cell  = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! SwipeableCellTableViewCell
            presentOpenGateVC(cell, gate, gateShare: gateShare)
        } else if (self.guestOwnerDialogNav?.presentingViewController == nil) {
            self.navigationController?.present(guestOwnerDialogNav!, animated: true) { (finished) in
                self.guestOwnerDialogVC?.reloadAsOwner()
            }
        } else {
            guestOwnerDialogVC?.reloadAsOwner()
        }
        
    }
    
    func gateForGateshare(_ gateShare: GateShare) -> Gate? {
        let filtered = self.gates?.filter {gate in gateShare.gateUid == gate.uid}
        return filtered?.first
    }
    
    func updateGateSharesForGate(_ gate: Gate?) {
        
        guard let gate = gate else { return }
        var changed = false
        
        for share in gate.shares {
            
            if share.gateName != gate.name {
                share.gateName = gate.name
                changed = true
            }
            
            if share.placemarkName != gate.placemarkName {
                share.placemarkName = gate.placemarkName
                changed = true
            }

            if share.longitude != gate.longitude {
                share.longitude = gate.longitude
                changed = true
            }
            
            if share.latitude != gate.latitude {
                share.latitude = gate.latitude
                changed = true
            }
            
            if changed {FireBaseController.shared.postGateShare(share)}
        }
    }
    
    //Mark: Notifications actions 
    
    func updateTableWithNewInvitation() {
        self.removeObserversAsGuest()
        self.gates = Model.shared.gates()
        tableView.reloadData()
        self.setupObserversAsGuest()
        let container = self.navigationController?.parent as! MainContainerController
        container.hideNoMessageVCIfNeeded()
    }
}

//MARK: setup Firebase Observers as guest
extension GatesTableViewController {
    
    
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
                guard let goDialog = self.guestOwnerDialogVC else {return}
                goDialog.ownerDailing()
            }
            default:
            break
        }
        
        do {
            try Model.shared.context?.save()
        } catch  {print("cant save gate while creating as Guset: \(error.localizedDescription)") }
        
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
    
    func callActionAsGuest(_ cell: SwipeableCellTableViewCell) {
        cell.gate.shouldCall = true
        informOwnerIfNeeded(cell, cell.gate, gateShare: nil)
    }

}

//MARK: App Notifications

extension GatesTableViewController {
    func registerAppNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(GatesTableViewController.locationUpdated), name: NSNotification.Name(rawValue: kLocationUpdateNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableWithNewInvitation), name: NSNotification.Name(rawValue: knewGateAsGuestNotification), object: nil)
    }
}

//MARK: GuestOwner Dialog

extension GatesTableViewController {
    
    func presentOpenGateVC(_ cell: SwipeableCellTableViewCell, _ gate: Gate, gateShare: GateShare?) {
        let kNavVCID = "guestOwnerNav"
        let nav = storyboard?.instantiateViewController(withIdentifier:kNavVCID) as! UINavigationController
        let vc = nav.viewControllers[0] as! GusetOwnerDialogVC
        vc.gate = gate
        vc.gateShare = gateShare
        self.guestOwnerDialogVC = vc
        self.guestOwnerDialogNav = nav
        nav.modalTransitionStyle = .crossDissolve
        nav.modalPresentationStyle = .overCurrentContext
        self.navigationController?.present(nav, animated: true) { (finished) in}
    }

    
    //this is called when a guest arrives at the gate region
    func informOwnerIfNeeded(_ cell: SwipeableCellTableViewCell, _ gate: Gate, gateShare: GateShare?) {
        
//        if i && gate.isGuest{
//            
//            gate.userInRegion = true
//            i = false
//        }
        if (gate.isGuest && gate.shouldCall && gate.userInRegion) {
            
            //set firebase to Should call = true
            let dbRef = FIRDatabase.database().reference()
            let path = dbRef.child("users").child(gate.ownerUid!).child(gate.shareId!).child(kOwnerShouldFireKey)
            path.setValue(true)
            gate.shouldCall = false
            
            
            //show UI for calling owner
            //show the cell's call button to let uaera initiate dialog with owner
            cell.callButton.alpha = 1
            presentOpenGateVC(cell, gate, gateShare: gateShare)
        }
            
        else if gate.isGuest && !gate.userInRegion{
            cell.callButton.animateToAlphaWithSpring(0.2, alpha: 0)
        }
    }
}

//MARK: Contacts

extension GatesTableViewController {
    func getContacts() {
        
        if #available(iOS 9.0, *) {
            
            let store = CNContactStore()
            if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                store.requestAccess(for: .contacts, completionHandler: {
                    (authorized: Bool, error: Error?) -> Void in
                    if authorized {
                        log.info("Did  Authorize contacts for iOS < 9")
                        self.presentContactsUI(store)
                    } else {
                        log.warning("Did Not Authorize contacts for iOS < 9")
                    }
                })
            } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                log.info("Did Authorize contacts for iOS > 9")

                self.presentContactsUI(store)
            } else {
                //no contacts permission
                log.warning("Did Not Authorize contacts for iOS > 9")

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
}
//MARK: Shares Popup
extension GatesTableViewController {
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
    
}
extension GatesTableViewController {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // return UIModalPresentationStyle.FullScreen
        return UIModalPresentationStyle.none
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
