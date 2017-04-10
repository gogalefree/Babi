//
//  GatesTableViewController+TableviewSetup.swift
//  Babi
//
//  Created by Guy Freedman on 08/04/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import Foundation
import UIKit

//MARK: table view setup

extension GatesTableViewController {

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
}

//MARK: Location updates

extension GatesTableViewController {
    
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
        
        guard let count = gates?.count else {return}
       
        var didMove = false
        shouldUpdateLocation = false
        if self.gates != nil && count > 1{
            
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
}
