//
//  FeedTableViewCell.swift
//  MeMe
//
//  Created by Drew Dearing on 3/25/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var memePic: UIImageView!
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var downVoteButton: UIButton!
    @IBOutlet weak var downVoteCounter: UILabel!
    @IBOutlet weak var upVoteCounter: UILabel!
    
    var memeURL:String?
    var profileURL:String?
    var uid:String?
    var postID:String?
    
    @IBAction func upVote(_ sender: Any) {
        print("hi")
    }
    
    @IBAction func downVote(_ sender: Any) {
        print("hi")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        profilePic.layer.cornerRadius = profilePic.frame.height/2
        profilePic.layer.borderWidth = 10
        profilePic.layer.borderColor = UIColor.white.cgColor
        profilePic.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
