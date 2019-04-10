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

protocol FeedCellDelegate {
    func addPost(post:FeedCellData, feed:Bool)
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
    
    var memeURL:String = ""
    var profileURL:String = ""
    var uid:String = ""
    var postID:String = ""
    var upvotes:Int = 0
    var downvotes:Int = 0
    var seconds:Int = 0
    var downvoted:Bool = false
    var upvoted: Bool = false
    var feed:Bool = false
    var delegate:FeedCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style:style, reuseIdentifier:reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit(){
        
    }
    
    func fill(feedCell:FeedCell){
        memePic.image = nil
        profilePic.image = nil
        feed = feedCell.feed
        upvotes = Int(feedCell.upvotes)
        downvotes = Int(feedCell.downvotes)
        upvoted = feedCell.upvoted
        downvoted = feedCell.downvoted
        memeURL = feedCell.imageURL
        seconds = Int(feedCell.seconds)
        uid = feedCell.uid
        postID = feedCell.post
        profileURL = feedCell.profilePicURL
        cellTitle.text = feedCell.username
        descriptionLabel.text = feedCell.desc
        updateVoteCounter()
        selectionStyle = .none
        
        DispatchQueue.global(qos: .background).async {
            if let memePic = cache.getImage(id: feedCell.post) {
                DispatchQueue.main.async {
                    self.memePic.image = memePic
                }
            }
            else{
                let url = URL(string: self.memeURL)
                let data = try? Data(contentsOf: url!)
                if let imgData = data {
                    let image = UIImage(data:imgData)
                    DispatchQueue.main.async {
                        self.memePic.image = image
                    }
                    cache.addImage(id: self.postID, image: image)
                }
            }
            if let profilePic = cache.getProfilePic(uid: feedCell.uid) {
                DispatchQueue.main.async {
                    self.profilePic.image = profilePic
                }
            }
            else{
                let url = URL(string: self.profileURL)
                let data = try? Data(contentsOf: url!)
                if let imgData = data {
                    let image = UIImage(data:imgData)
                    DispatchQueue.main.async {
                        self.profilePic.image = image
                    }
                    cache.addProfilePic(id: self.uid, image: image)
                }
            }
        }
    }
    
    func updateVoteCounter(){
        if upvoted {
            upvoteButton.imageView?.image = upvoteButton.imageView!.image?.withRenderingMode(.alwaysTemplate)
            upvoteButton.imageView?.tintColor = .blue
        }
        else{
            upvoteButton.imageView?.image = upvoteButton.imageView!.image?.withRenderingMode(.alwaysTemplate)
            upvoteButton.imageView?.tintColor = .gray
        }
        if downvoted {
            downVoteButton.imageView?.image = downVoteButton.imageView!.image?.withRenderingMode(.alwaysTemplate)
            downVoteButton.imageView?.tintColor = .blue
        }
        else{
            downVoteButton.imageView?.image = downVoteButton.imageView!.image?.withRenderingMode(.alwaysTemplate)
            downVoteButton.imageView?.tintColor = .gray
        }
        upVoteCounter.text = String(upvotes)
        downVoteCounter.text = String(downvotes)
    }
    
    @IBAction func upVote(_ sender: Any) {
        if !upvoted {
            if downvoted {
                downvoted = false
                downvotes -= 1
            }
            upvoted = true
            upvotes += 1
        }
        updateVoteCounter()
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = "https://us-central1-meme-d3805.cloudfunctions.net/upvote"
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&post=" + postID)
            let request = NSMutableURLRequest()
            request.url = URL(string: urlPathBase)
            request.httpMethod = "PUT"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
                guard let data = data else { return }
                do {
                    let voteData = try JSONDecoder().decode(VoteData.self, from: data)
                    DispatchQueue.main.async {
                        self.upvotes = voteData.upvotes
                        self.downvotes = voteData.downvotes
                        self.updateVoteCounter()
                        self.updateDelegate()
                    }
                } catch let jsonErr {
                    print("Error: \(jsonErr)")
                }
            }
            task.resume()
        }
    }
    
    @IBAction func downVote(_ sender: Any) {
        if !downvoted {
            if upvoted {
                upvoted = false
                upvotes -= 1
            }
            downvoted = true
            downvotes += 1
        }
        updateVoteCounter()
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = "https://us-central1-meme-d3805.cloudfunctions.net/downvote"
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&post=" + postID)
            let request = NSMutableURLRequest()
            request.url = URL(string: urlPathBase)
            request.httpMethod = "PUT"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
                guard let data = data else { return }
                do {
                    let voteData = try JSONDecoder().decode(VoteData.self, from: data)
                    DispatchQueue.main.async {
                        self.upvotes = voteData.upvotes
                        self.downvotes = voteData.downvotes
                        self.updateVoteCounter()
                        self.updateDelegate()
                    }
                } catch let jsonErr {
                    print("Error: \(jsonErr)")
                }
            }
            task.resume()
        }
    }
    
    func updateDelegate(){
        if let delegate = self.delegate {
            let data = FeedCellData(username: self.cellTitle.text!, description: self.description, uid: self.uid, post: self.postID, imageURL: self.memeURL, profilePicURL: self.profileURL, upvotes: self.upvotes, downvotes: self.downvotes, timestamp: Timestamp(s:self.seconds), upvoted:self.upvoted, downvoted: self.downvoted)
            print("calling del")
            delegate.addPost(post: data, feed:self.feed)
        }
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
