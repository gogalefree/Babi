//
//  InvitationsPOPCell.swift
//  Babi
//
//  Created by Guy Freedman on 27/03/2017.
//  Copyright © 2017 Guy Freeman. All rights reserved.
//

import UIKit
import Material

protocol  InvitationsPopCellDelegate: NSObjectProtocol {
    func didCancellGateshareAsOwner(share: GateShare, indexPath: IndexPath)
}

class InvitationsPOPCell: UITableViewCell {

    weak var delegate: InvitationsPopCellDelegate?
    var indexPath: IndexPath?
    var cancellButton: IconButton!
    var share: GateShare? {
        didSet{
            setup()
        }
    }
    
    func setup() {
    
        guard let share = share else {return}
        self.textLabel?.text = share.guestName
        let expirationDate = NSDate(timeIntervalSince1970: share.shareDate).addingTimeInterval(24*60*60)
        let formmater = DateFormatter()
        formmater.dateStyle = .long
        self.detailTextLabel?.text = "Expires: " + formmater.string(from: expirationDate as Date)
        
        if cancellButton == nil {
         
            cancellButton = IconButton(image: Icon.cm.clear)
            cancellButton.tintColor = .red
            cancellButton.frame = CGRect(x: contentView.bounds.width - 30 - 10,
                                         y: 10,
                                         width: 30,
                                         height: 30)
            contentView.addSubview(cancellButton)
            //self.contentView.layout(cancellButton).horizontally(left: contentView.bounds.width - 30 - 20, right: 20).center()
            cancellButton.addTarget(self, action: #selector(cancellShareAction), for: .touchUpInside)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    func cancellShareAction() {
        print("cancel action)")
        delegate?.didCancellGateshareAsOwner(share: share!, indexPath: indexPath!)
        FireBaseController.shared.currentUserPath.child(share!.shareId).removeValue()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
