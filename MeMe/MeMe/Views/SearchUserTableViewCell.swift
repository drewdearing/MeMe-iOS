//
//  SearchUserTableViewCell.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/27/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class SearchUserTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
