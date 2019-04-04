//
//  FeedTableViewCell.swift
//  MeMe
//
//  Created by Drew Dearing on 3/25/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

struct VoteData: Codable {
    let upvotes:Int
    let downvotes:Int
}

class FeedTableViewCell: UITableViewCell {
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var memePic: UIImageView!
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var downVoteButton: UIButton!
    @IBOutlet weak var downVoteCounter: UILabel!
    @IBOutlet weak var upVoteCounter: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var memeURL:String?
    var profileURL:String?
    var uid:String?
    var postID:String?
    
    @IBAction func upVote(_ sender: Any) {
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = "https://us-central1-meme-d3805.cloudfunctions.net/upvote"
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&post=" + postID!)
            let request = NSMutableURLRequest()
            request.url = URL(string: urlPathBase)
            request.httpMethod = "PUT"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
                guard let data = data else { return }
                do {
                    let voteData = try JSONDecoder().decode(VoteData.self, from: data)
                    DispatchQueue.main.async {
                        self.upVoteCounter.text = String(voteData.upvotes)
                        self.downVoteCounter.text = String(voteData.downvotes)
                    }
                } catch let jsonErr {
                    print("Error: \(jsonErr)")
                }
            }
            task.resume()
        }
    }
    
    @IBAction func downVote(_ sender: Any) {
        
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
