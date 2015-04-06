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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cellsCurrentlyEditing = NSMutableSet()        

    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 88
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as SwipeableCellTableViewCell
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
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            gates!.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
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
    
    func buttonOneAction(itemText: String?){
        println("button one clicked")
    }
    
    func buttonTwoAction(itemText: String?) {
        println("button two clicked")
        
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
        gate.toString()
        
        //notify container to remove message
        let container = self.navigationController?.parentViewController as MainContainerController
        container.removeNoGatesMessageIfNeeded()
       
        /*
        //Save Gate
        let context = Model.shared.context
        context?.save(nil)
        
        //add gate to data source
        gates?.insert(gate, atIndex: 0)
        
        //add cell
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
        */
    
        println("unwind")
    }

    
}
