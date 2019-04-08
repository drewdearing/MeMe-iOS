//
//  PotentialUserTableViewCell.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

protocol addMembersDelegate {
    func addMember(name: String)
}

class PotentialUserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var usernameLable: UILabel!
    @IBOutlet weak var add: UIButton!
    var delegate: addMembersDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

    @IBAction func addButton(_ sender: Any) {
        add.setImage(#imageLiteral(resourceName: "checkmark"), for: .normal)
        if(delegate != nil) {
            delegate?.addMember(name: usernameLable.text!)
        }
    }
}
