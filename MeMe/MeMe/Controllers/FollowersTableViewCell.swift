//
//  FollowersTableViewCell.swift
//  MeMe
//
//  Created by Drew Dearing on 5/8/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class FollowersTableViewCell: UITableViewCell {
    @IBOutlet var profilePicImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
