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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cellsCurrentlyEditing = NSMutableSet()
        if gates == nil {
            gates = [Gate]()
        }

    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 88
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as SwipeableCellTableViewCell
        cell.indexPath = indexPath
        cell.delegate = self
        let gate = gates![indexPath.row] as Gate
        let title = gate.name
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
        return false
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let gate = gates![indexPath.row]
        let phoneNumber = gate.phoneNumber
        let dialer = PhoneDialer()
        dialer.callGate(phoneNumber)
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
    
    func buttonZeroAction(cell: SwipeableCellTableViewCell) {
        
        let indexPath = tableView.indexPathForCell(cell)!
        let gate = gates![indexPath.row]
        gates!.removeAtIndex(indexPath.row)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        Model.shared.deleteGate(gate)
        let container = self.navigationController?.parentViewController as MainContainerController
        container.noGatesMessageIfNeeded()
    }
    
    func buttonOneAction(cell: SwipeableCellTableViewCell){
        //present gate editor for editing
        let indexPath = tableView.indexPathForCell(cell)!
        self.selectedIndexPath = indexPath
        let gate = gates![indexPath.row]
        let gateEditorNavController = self.storyboard?.instantiateViewControllerWithIdentifier("gateEditorNavController") as UINavigationController
        gateEditorNavController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        let gateEditor = gateEditorNavController.viewControllers[0] as GateEditorVC
        gateEditor.gate = gate
        gateEditor.state = .EditGate
        self.navigationController?.presentViewController(gateEditorNavController, animated: true, completion: nil)
        
        self.cellsCurrentlyEditing.removeObject(indexPath)
        
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
        let gateEditorNavController = self.storyboard?.instantiateViewControllerWithIdentifier("gateEditorNavController") as UINavigationController
        gateEditorNavController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        let gateEditor = gateEditorNavController.viewControllers[0] as GateEditorVC
        gateEditor.state = .NewGate
        self.navigationController?.presentViewController(gateEditorNavController, animated: true, completion: nil)
    }
    
    @IBAction func unwindFromGateEditorVC(segue: UIStoryboardSegue) {
       
        let gateEditor = segue.sourceViewController as GateEditorVC
        let gate = gateEditor.gate
        var error: NSError? = nil
        gate.toString()
        
        //Save Gate
        //Model.shared.context?.insertObject(gate)
        if !Model.shared.context!.save(&error) {
            println(error)
        }
        
        //register notification if needed
        Model.shared.locationNotifications.registerGateForLocationNotification(gate)
        
        if gateEditor.state == GateEditorState.EditGate {
            if let selectedIndexPath = self.selectedIndexPath {
                tableView.reloadRowsAtIndexPaths([selectedIndexPath], withRowAnimation: .Automatic)
            }
            
            return
        }
        
        //notify container to remove no gates message
        let container = self.navigationController?.parentViewController as MainContainerController
        container.removeNoGatesMessageIfNeeded()
       
        tableView.beginUpdates()
        gates?.insert(gate, atIndex: 0)
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
        tableView.endUpdates()
    }
    
    @IBAction func unwindeWithCancelButtonFromGateEditor(segue: UIStoryboardSegue) {
        print("canceked and back to gates table view controller")
    }

    
}
