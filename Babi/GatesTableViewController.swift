//
//  GatesTableViewController.swift
//  Babi
//
//  Created by Guy Freedman on 3/28/15.
//  Copyright (c) 2015 Guy Freeman. All rights reserved.
//

import UIKit

class GatesTableViewController: UITableViewController  , UITableViewDataSource, UITableViewDelegate, SwipeableCellDelegate {
    
       
    var cellsCurrentlyEditing :NSMutableSet!
    var gates = Model.shared.gates() as [Gate]?
    var selectedIndexPath: NSIndexPath!
    var shouldUpdateLocation = true
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cellsCurrentlyEditing = NSMutableSet()
        if gates == nil || gates?.count == 0 {
            gates = [Gate]()
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationUpdated", name: kLocationUpdateNotification, object: nil)

    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! SwipeableCellTableViewCell
        cell.gate = gates![indexPath.row]
        cell.indexPath = indexPath
        cell.delegate = self
        let gate = gates![indexPath.row] as Gate
        let title = gate.name + "\n\(floor(gate.distanceFromUserLocation() / 1000))"
        cell.itemText = title
        
        
        if self.cellsCurrentlyEditing.containsObject(indexPath) {
            cell.openCell()
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let gates = gates {
            return gates.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None

    }
    
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let gate = gates![indexPath.row]
        let phoneNumber = gate.phoneNumber
        PhoneDialer.callGate(phoneNumber)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
        }
        else {
            println("Unhandled Editing style")
        }
    }
    
    func cellDidOpen(cell: UITableViewCell) {
        let currentEditingIndexPath = self.tableView.indexPathForCell(cell)
        self.cellsCurrentlyEditing.addObject(currentEditingIndexPath!)
    }
    
    func cellDidClose(cell: UITableViewCell) {
        
        self.cellsCurrentlyEditing.removeObject(self.tableView.indexPathForCell(cell)!);
    }
        
    func buttonOneAction(cell: SwipeableCellTableViewCell){
        //present gate editor for editing
        Model.shared.stopLocationUpdates()

        let indexPath = tableView.indexPathForCell(cell)!
        self.selectedIndexPath = indexPath
        
        let gate = gates![indexPath.row]
        
        let gateEditorNavController = self.storyboard?.instantiateViewControllerWithIdentifier("gateEditorNavController") as! UINavigationController
        gateEditorNavController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        let gateEditor = gateEditorNavController.viewControllers[0] as! GateEditorVC
        gateEditor.gate = gate
        gateEditor.state = .EditGate
        
        self.navigationController?.presentViewController(gateEditorNavController, animated: true, completion: nil)
        
     //   self.cellsCurrentlyEditing.removeObject(indexPath)
        
        Model.shared.locationNotifications.cancelLocalNotification(gate)
    }
    
    func buttonTwoAction(cell: SwipeableCellTableViewCell) {

        let indexPath = tableView.indexPathForCell(cell)!
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
    
    @IBAction func presentGateEditor(sender: AnyObject) {
        //for creating a new gate
        Model.shared.stopLocationUpdates()

        let gateEditorNavController = self.storyboard?.instantiateViewControllerWithIdentifier("gateEditorNavController") as! UINavigationController
        gateEditorNavController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        let gateEditor = gateEditorNavController.viewControllers[0] as! GateEditorVC
        gateEditor.state = .NewGate
        self.navigationController?.presentViewController(gateEditorNavController, animated: true, completion: nil)
    }
    
    @IBAction func unwindFromGateEditorVC(segue: UIStoryboardSegue) {
       //created new gate or finished editing
        let gateEditor = segue.sourceViewController as! GateEditorVC
        let gate = gateEditor.gate
        
        //Save Gate
        //the should call inits with false so calls are'nt initiated till the gate is completly configured

        gate.shouldCall = true
        
        var error: NSError? = nil
        if !Model.shared.context!.save(&error) {println(error)}
        Model.shared.startLocationUpdates()
        
        //register notification if needed
        Model.shared.locationNotifications.registerGateForLocationNotification(gate)
        
        if gateEditor.state == GateEditorState.EditGate {
            if let selectedIndexPath = self.selectedIndexPath {
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
            }
            
            return
        }
        
        //notify container to remove no gates message
        let container = self.navigationController?.parentViewController as! MainContainerController
        container.hideNoMessageVCIfNeeded()
       
        tableView.beginUpdates()
        gates?.insert(gate, atIndex: 0)
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
        tableView.endUpdates()
    }
    
    @IBAction func unwindWithDeleteButtonFromEditorVC(segue: UIStoryboardSegue) {
        //delete gate
        let indexPath = self.selectedIndexPath
        let gate = gates![indexPath.row]
        if cellsCurrentlyEditing.containsObject(indexPath){
            cellsCurrentlyEditing.removeObject(indexPath)
        }

        tableView.beginUpdates()
        gates!.removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        Model.shared.deleteGate(gate)
        tableView.endUpdates()
        
        let container =
        self.navigationController?.parentViewController as!MainContainerController
        
        container.showNoMessageVCIfNeeded()
        Model.shared.startLocationUpdates()

    }
    
    func locationUpdated() {
        
        if let gates = gates {
            
            if shouldUpdateLocation {
                
                for (index , gate) in enumerate(gates) {
                    
                    let indexpath = NSIndexPath(forRow: index, inSection: 0)
                    let cell = tableView.cellForRowAtIndexPath(indexpath) as? SwipeableCellTableViewCell
                    

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
        if var gates = self.gates {
            
            for var index = 0 ; index < self.gates!.count - 1; index++  {
                
                let firstGate = self.gates![index]
                let seccondGate = self.gates![index+1]
                
                if seccondGate.distanceFromUserLocation() < firstGate.distanceFromUserLocation() {
                   
                    didMove = true
                    
                    let fromIndexPath = NSIndexPath(forRow: index+1, inSection: 0)
                    let toIndexPath = NSIndexPath(forRow: index, inSection: 0)
                    
                    self.gates!.removeAtIndex(index+1)
                    self.gates!.insert(seccondGate, atIndex: index)
                    tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
                    
                    if self.cellsCurrentlyEditing.containsObject(fromIndexPath){
                        self.cellsCurrentlyEditing.removeObject(fromIndexPath)
                        self.cellsCurrentlyEditing.addObject(toIndexPath)
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

    @IBAction func unwindeWithCancelButtonFromGateEditor(segue: UIStoryboardSegue) {
        print("canceked and back to gates table view controller")
    }

    @IBAction func toogleSleepMode() {
        //notifies the container that sleep mode button pressed

 //       reorderGates()
        let container = self.navigationController?.parentViewController as! MainContainerController
        container.toogleSleepMode()
    }
    
}
