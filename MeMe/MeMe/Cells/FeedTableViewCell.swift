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
    let upvotes:Int32
    let downvotes:Int32
}

protocol FeedCellDelegate {
    func tappedAction(uid: String)
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
    var color:String = ""
    var upvotes:Int32 = 0
    var downvotes:Int32 = 0
    var timestamp:Timestamp = Timestamp(s: 0)
    
    var downvoted:Bool = false
    var upvoted: Bool = false
    
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
    
    func fill(postData:PostData){
        memePic.image = nil
        profilePic.image = nil
        color = postData.color
        memePic.backgroundColor = UIColor(hex: postData.color)
        upvotes = Int32(postData.upvotes)
        timestamp = postData.timestamp
        downvotes = Int32(postData.downvotes)
        uid = postData.uid
        postID = postData.id
        cellTitle.text = ""
        descriptionLabel.text = ""
        setUpGesture()
        updateVoteCounter()
        
        cache.getPost(id: postID) { (post) in
            if let post = post {
                let imageURL = post.photoURL
                self.descriptionLabel.text = post.desc
                self.downvotes = post.downvotes
                self.upvotes = post.upvotes
                self.upvoted = post.upvoted
                self.downvoted = post.downvoted
                self.updateVoteCounter()
                cache.getImage(imageURL: imageURL, complete: { (postImage) in
                    self.memePic.image = postImage
                })
            }
        }
        
        cache.getProfile(uid: uid) { (profile) in
            if let profile = profile {
                self.cellTitle.text = profile.username
                let profilePicURL = profile.profilePicURL
                cache.getImage(imageURL: profilePicURL, complete: { (profilePic) in
                    self.profilePic.image = profilePic
                })
            }
        }
    }
    
    func setUpGesture() {
        let tapTitle = UITapGestureRecognizer(target: self, action: #selector(tappedAction(recognizer:)))
        let tapImage = UITapGestureRecognizer(target: self, action: #selector(tappedAction(recognizer:)))
        cellTitle.addGestureRecognizer(tapTitle)
        cellTitle.isUserInteractionEnabled = true
        profilePic.addGestureRecognizer(tapImage)
        profilePic.isUserInteractionEnabled = true
    }
    
    func updateVoteCounter(){
        if upvoted {
            upvoteButton.setImage(#imageLiteral(resourceName: "up-arrow-enabled"), for: .normal)
        }
        else{
            upvoteButton.setImage(#imageLiteral(resourceName: "up-arrow"), for: .normal)
        }
        if downvoted {
            downVoteButton.setImage(#imageLiteral(resourceName: "angle-arrow-down-enabled"), for: .normal)
        }
        else{
            downVoteButton.setImage(#imageLiteral(resourceName: "angle-arrow-down"), for: .normal)
        }
        upVoteCounter.text = String(upvotes)
        downVoteCounter.text = String(downvotes)
    }
    
    @IBAction func tappedAction(recognizer: AnyObject) {
        delegate?.tappedAction(uid: uid)
    }
    
    @IBAction func upVote(_ sender: Any) {
        downVoteButton.isUserInteractionEnabled = false
        upvoteButton.isUserInteractionEnabled = false
        if !upvoted {
            if downvoted {
                downvoted = false
                downvotes -= 1
            }
            upvoted = true
            upvotes += 1
        }
        updateVoteCounter()
        updateCache()
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
                        self.downVoteButton.isUserInteractionEnabled = true
                        self.upvoteButton.isUserInteractionEnabled = true
                        self.updateVoteCounter()
                        self.updateCache()
                    }
                } catch let jsonErr {
                    print("Error: \(jsonErr)")
                }
            }
            task.resume()
        }
    }
    
    @IBAction func downVote(_ sender: Any) {
        downVoteButton.isUserInteractionEnabled = false
        upvoteButton.isUserInteractionEnabled = false
        if !downvoted {
            if upvoted {
                upvoted = false
                upvotes -= 1
            }
            downvoted = true
            downvotes += 1
        }
        updateVoteCounter()
        updateCache()
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
                        self.downVoteButton.isUserInteractionEnabled = true
                        self.upvoteButton.isUserInteractionEnabled = true
                        self.updateVoteCounter()
                        self.updateCache()
                    }
                } catch let jsonErr {
                    print("Error: \(jsonErr)")
                }
            }
            task.resume()
        }
    }
    
    func updateCache(){
        let data:[String:Any] = [
            "upvotes": upvotes,
            "downvotes": downvotes,
            "upvoted": upvoted,
            "downvoted":downvoted
            ]
        cache.updatePost(id: postID, data: data) { (post) in
            if let post = post {
                self.downvotes = post.downvotes
                self.upvotes = post.upvotes
                self.upvoted = post.upvoted
                self.downvoted = post.downvoted
                self.updateVoteCounter()
            }
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
    
}
