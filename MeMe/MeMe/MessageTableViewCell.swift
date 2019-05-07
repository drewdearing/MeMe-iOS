//
//  MessageTableViewCell.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/4/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet var receiverProfileImageView: UIImageView!
    @IBOutlet var receiverContentView: UIView!
    @IBOutlet var receiverMessageLabel: UILabel!
    @IBOutlet var receiverMemeImageView: UIImageView!
    
    @IBOutlet var senderProfileImageView: UIImageView!
    @IBOutlet var senderContentView: UIView!
    @IBOutlet var senderMessageLabel: UILabel!
    @IBOutlet var senderMemeImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func disableReceiver() {
        receiverProfileImageView.isHidden = true
        receiverContentView.isHidden = true
        receiverMessageLabel.isHidden = true
        receiverMemeImageView.isHidden = true
    }
    
    func disableSender()  {
        senderProfileImageView.isHidden = true
        senderContentView.isHidden = true
        senderMessageLabel.isHidden = true
        senderMemeImageView.isHidden = true
    }

}
