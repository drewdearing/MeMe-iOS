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
    var post: String!
    var index: IndexPath!
    var memeURL:String = ""
    var profileURL:String = ""
    var uid:String = ""
    var postID:String = ""
    var upvotes:Int32 = 0
    var downvotes:Int32 = 0
    var seconds:Int = 0
    var color:String = ""
    var timestamp:Timestamp = Timestamp(s: 0)
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

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedImage(recognizer:)))
        userProfileImageView.addGestureRecognizer(tapGesture)
        userProfileImageView.isUserInteractionEnabled = true
        navItem.title = "Meme"
        followButton.isEnabled = false
        cache.getPost(id: post) { (post) in
            if let post = post {
                self.fill(post: post)
            }
        }
    }
    
    func fill(post:Post){
        postImageView.image = nil
        userProfileImageView.image = nil
        postImageView.backgroundColor = UIColor(hex: post.color)
        upvotes = post.upvotes
        downvotes = post.downvotes
        upvoted = post.upvoted
        color = post.color
        timestamp = Timestamp(s: post.seconds, n: post.nanoseconds)
        downvoted = post.downvoted
        memeURL = post.photoURL
        seconds = Int(post.seconds)
        descriptionLabel.text = post.desc
        uid = post.uid
        postID = post.id
        updateVoteCounter()
        
        cache.getProfile(uid: uid) { (profile) in
            if let profile = profile {
                let username = profile.username
                let profilePicURL = profile.profilePicURL
                self.userButton.setTitle(username, for: .normal)
                self.following = profile.following
                if let currentUser = Auth.auth().currentUser {
                    if self.uid != currentUser.uid {
                        self.followButton.isEnabled = true
                        if profile.following {
                            self.followButton.setTitle("Unfollow", for: .normal)
                        }
                    }
                }
                cache.getImage(imageURL: profilePicURL, complete: { (profilePic) in
                    self.userProfileImageView.image = profilePic
                })
            }
        }
        
        cache.getImage(imageURL: memeURL) { (postImage) in
            self.postImageView.image = postImage
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
        
        if let delegate = self.delegate {
            delegate.refreshCell(index: self.index)
        }
    }
    
    @IBAction func upVote(_ sender: Any) {
        downVoteButton.isUserInteractionEnabled = false
        upVoteButton.isUserInteractionEnabled = false
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
                        self.upVoteButton.isUserInteractionEnabled = true
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
        upVoteButton.isUserInteractionEnabled = false
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
                        self.upVoteButton.isUserInteractionEnabled = true
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
    
    @IBAction func tappedImage(recognizer: AnyObject) {
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
