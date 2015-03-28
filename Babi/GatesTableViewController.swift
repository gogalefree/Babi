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
    
    
    var objects = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        self.cellsCurrentlyEditing = NSMutableSet()
        
        for  index in 0...9 {
            
            let object = "a longer string with Object \(index)"
            objects.append(object)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 88
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as SwipeableCellTableViewCell
        cell.delegate = self
        let title = objects[indexPath.row]
        cell.itemText = title
        
        
        if self.cellsCurrentlyEditing.containsObject(indexPath) {
            cell.openCell()
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
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

}
