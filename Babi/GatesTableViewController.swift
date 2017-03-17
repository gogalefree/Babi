//
//  GatesTableViewController.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit
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


class GatesTableViewController: UITableViewController, SwipeableCellDelegate {
    
       
    var cellsCurrentlyEditing :NSMutableSet!
    var gates = Model.shared.gates() as [Gate]?
    var selectedIndexPath: IndexPath!
    var shouldUpdateLocation = true
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cellsCurrentlyEditing = NSMutableSet()
        if gates == nil || gates?.count == 0 {
            gates = [Gate]()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(GatesTableViewController.locationUpdated), name: NSNotification.Name(rawValue: kLocationUpdateNotification), object: nil)

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
        let title = gate.name + "\n\(floor(gate.distanceFromUserLocation() / 1000))"
        cell.itemText = title
        
        
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
        
        tableView.deselectRow(at: indexPath, animated: true)
        let gate = gates![indexPath.row]
        let phoneNumber = gate.phoneNumber
        PhoneDialer.callGate(phoneNumber)
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
        
    func buttonOneAction(_ cell: SwipeableCellTableViewCell){
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
        
     //   self.cellsCurrentlyEditing.removeObject(indexPath)
        
        Model.shared.locationNotifications.cancelLocalNotification(gate)
    }
    
    func buttonTwoAction(_ cell: SwipeableCellTableViewCell) {

        let indexPath = tableView.indexPath(for: cell)!
        self.selectedIndexPath = indexPath
        let gate = gates![indexPath.row]
        gate.automatic = !gate.automatic
        cell.setAutomaticButtonTitle(gate.automatic)
        
        if gate.automatic {
            Model.shared.locationNotifications.registerGateForLocationNotification(gate)
        }
        else {
            Model.shared.locationNotifications.cancelLocalNotification(gate)
        }
    }
    
    func shareButtonClicked(_ cell: SwipeableCellTableViewCell) {
        print("starting share process")
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
        //we dont register local notifications for now
        Model.shared.locationNotifications.registerGateForLocationNotification(gate!)
        
        if gateEditor.state == GateEditorState.editGate {
            if let selectedIndexPath = self.selectedIndexPath {
                tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
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
                        
                        let distance = gate.distanceFromUserLocation()
                        let distanceInMeters = Int(distance)
                        let title = gate.name + "\n\(distanceInMeters) m"
                        cell.itemText = title
                    }
                }
                
          //      if !Model.shared.isInRegion(Model.shared.userLocation){
                    reorderGates()
            //    }
            }
        }
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

 //       reorderGates()
        let container = self.navigationController?.parent as! MainContainerController
        container.toogleSleepMode()
    }
    
}
