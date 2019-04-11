//
//  PostViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//
import UIKit
import Firebase

protocol IndividualPostDelegate {
    func addPost(post:FeedCellData, feed:Bool, update:Bool)
    func refreshCell(index:IndexPath)
}

class PostViewController: UIViewController {
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var upVoteButton: UIButton!
    @IBOutlet weak var downVoteButton: UIButton!
    @IBOutlet weak var upVoteCounter: UILabel!
    @IBOutlet weak var downVoteCounter: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var navItem: UINavigationItem!
    
    @IBOutlet weak var userButton: UIButton!
    var post: FeedCell!
    var index: IndexPath!
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
    var following:Bool = false
    var delegate:IndividualPostDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userProfileImageView.layer.cornerRadius = userProfileImageView.frame.height/2
        userProfileImageView.layer.borderWidth = 10
        userProfileImageView.layer.borderColor = UIColor.white.cgColor
        userProfileImageView.clipsToBounds = true
        fill(feedCell: post)
        navItem.title = post.username+"'s meme"
        followButton.isEnabled = false
    }
    
    func fill(feedCell:FeedCell){
        postImageView.image = nil
        userProfileImageView.image = nil
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
        userButton.setTitle(feedCell.username, for: .normal)
        descriptionLabel.text = feedCell.desc
        updateVoteCounter()
        
        if let currentUser = Auth.auth().currentUser{
            if uid != currentUser.uid {
                Firestore.firestore().collection("users").document(uid).collection("followers").document(currentUser.uid).getDocument { (followDoc, err) in
                    if let doc = followDoc {
                        if doc.exists {
                            self.followButton.isEnabled = true
                            self.following = true
                            self.followButton.setTitle("Unfollow", for: .normal)
                        }
                        else{
                            self.followButton.isEnabled = true
                        }
                    }
                }
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            if let memePic = cache.getImage(id: feedCell.post) {
                DispatchQueue.global(qos: .background).async {
                    let color = memePic.averageColor
                    DispatchQueue.main.async {
                        self.postImageView.backgroundColor = color
                    }
                }
                DispatchQueue.main.async {
                    self.postImageView.image = memePic
                }
            }
            else{
                let url = URL(string: self.memeURL)
                let data = try? Data(contentsOf: url!)
                if let imgData = data {
                    let image = UIImage(data:imgData)
                    DispatchQueue.global(qos: .background).async {
                        let color = image!.averageColor
                        DispatchQueue.main.async {
                            self.postImageView.backgroundColor = color
                        }
                    }
                    DispatchQueue.main.async {
                        self.postImageView.image = image
                    }
                    cache.addImage(id: self.postID, image: image)
                }
            }
        }
        DispatchQueue.global(qos: .background).async {
            if let profilePic = cache.getProfilePic(uid: feedCell.uid) {
                DispatchQueue.main.async {
                    self.userProfileImageView.image = profilePic
                }
            }
            else{
                let url = URL(string: self.profileURL)
                let data = try? Data(contentsOf: url!)
                if let imgData = data {
                    let image = UIImage(data:imgData)
                    DispatchQueue.main.async {
                        self.userProfileImageView.image = image
                    }
                    cache.addProfilePic(id: self.uid, image: image)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        followButton.isEnabled = false
        followButton.setTitle("Follow", for: .normal)
        if let currentUser = Auth.auth().currentUser{
            if uid != currentUser.uid {
                Firestore.firestore().collection("users").document(uid).collection("followers").document(currentUser.uid).getDocument { (followDoc, err) in
                    if let doc = followDoc {
                        if doc.exists {
                            self.followButton.isEnabled = true
                            self.following = true
                            self.followButton.setTitle("Unfollow", for: .normal)
                        }
                        else{
                            self.followButton.isEnabled = true
                        }
                    }
                }
            }
        }
    }
    
    func updateVoteCounter(){
        if upvoted {
            upVoteButton.setImage(#imageLiteral(resourceName: "up-arrow-enabled"), for: .normal)
        }
        else{
            upVoteButton.setImage(#imageLiteral(resourceName: "up-arrow"), for: .normal)
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
            print("hi")
            let data = FeedCellData(username: self.userButton.currentTitle!, description: self.description, uid: self.uid, post: self.postID, imageURL: self.memeURL, profilePicURL: self.profileURL, upvotes: self.upvotes, downvotes: self.downvotes, timestamp: Timestamp(s:self.seconds), upvoted:self.upvoted, downvoted: self.downvoted)
            delegate.addPost(post: data, feed:self.feed, update: false)
            delegate.refreshCell(index: self.index)
        }
    }
    
    @IBAction func follow(_ sender: Any) {
        if let currentUser = Auth.auth().currentUser {
            if !following {
                Firestore.firestore().collection("users").document(uid).collection("followers").document(currentUser.uid).setData([
                    "following":true
                    ])
                followButton.setTitle("Unfollow", for: .normal)
                following = true
            }
            else{
                Firestore.firestore().collection("users").document(uid).collection("followers").document(currentUser.uid).delete()
                followButton.setTitle("Follow", for: .normal)
                following = false
            }
            
        }
    }
    
    @IBAction func usernameButton(_ sender: Any) {
        let postStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        if let postVCDestination = postStoryBoard.instantiateViewController(withIdentifier: "profileView") as? ProfileViewController {
            postVCDestination.userID = uid
            postVCDestination.currentProfile = false
            self.navigationController?.pushViewController(postVCDestination, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShareSegue" {
            let dest = segue.destination as! ShareViewController
            dest.postID = postID
            dest.photoURL = memeURL
        }
    }
}
