//
//  PostViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//
import UIKit
import Firebase
import FirebaseFirestore

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
    
    var database: Firestore!
    var authentication: Auth!

    var post: String?
    var index: IndexPath!
    var memeURL:String = ""
    var profileURL:String = ""
    var uid:String!
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
        
        database = Firestore.firestore()
        authentication = Auth.auth()

        // Needs to be tested...
//        NotificationCenter.default.addObserver(self, selector: #selector(screenshotTaken), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    @objc func screenshotTaken() {
        // check to see if a scheenshot has been taken
        if let id = Auth.auth().currentUser?.uid {
            DispatchQueue.global(qos: .userInteractive).async {

                self.database.collection("users").document(id).collection("screenshot").getDocuments { (screenshotQuerySnapshot, screenshotError) in
                    
                    if let screenshotError = screenshotError {
                        print("error:", screenshotError)
                        // none, so make one
                        // if the screenshot has been taken for the first time, set a warning
                        DispatchQueue.main.async {
                            DispatchQueue.global(qos: .userInteractive).async {
                                self.database.collection("users").document(id).collection("screenshot").addDocument(data: ["Strike" : true])
                            }
                            
                            let alert = UIAlertController(title: "WARNING!!!", message: "Do not screenshot! Next screenshot will result in an account termination.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "I Understand", style: .cancel, handler: nil))
                            self.present(alert, animated: true)
                        }
                    } else {
                        // else terminate the login and log them out...
                        DispatchQueue.main.async {
                            DispatchQueue.global(qos: .userInteractive).async {
                                let user = Auth.auth().currentUser
                                
                                user?.delete { error in
                                    if let error = error {
                                        // An error happened.
                                        print("Error deleting user: \(error)")
                                    } else {
                                        // Account deleted.
                                        print("deleted User successfully!")
                                    }
                                }
                            }
                            
                            cache.clearCache()
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let controller = storyboard.instantiateViewController(withIdentifier: "loginVC")
                            self.present(controller, animated: true, completion: nil)
                        }
                    }
                }
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
        
        cache.getProfile(uid: post.uid) { (profile) in
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
        if let post = post {
            cache.getPost(id: post) { (post) in
                if let post = post {
                    self.fill(post: post)
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
                followMember()
                followButton.setTitle("Unfollow", for: .normal)
                following = true
            }
            else{
                unfollowMember()
                followButton.setTitle("Follow", for: .normal)
                following = false
            }
        }
    }
        
    func followMember() {
        let urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/follow"
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = urlPath
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&following=" + uid)
            let request = NSMutableURLRequest()
            request.url = URL(string: urlPathBase)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in 	}
            task.resume()
        }
    }
    
    func unfollowMember() {
        let urlPath = "https://us-central1-meme-d3805.cloudfunctions.net/unfollow"
        if let currentUser = Auth.auth().currentUser {
            var urlPathBase = urlPath
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&following=" + uid)
            let request = NSMutableURLRequest()
            request.url = URL(string: urlPathBase)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in     }
            task.resume()
        }
    }
    
    @IBAction func usernameButton(_ sender: Any) {
        let postStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        if let postVCDestination = postStoryBoard.instantiateViewController(withIdentifier: "profileView") as? ProfileViewController {
            postVCDestination.uid = uid
            self.navigationController?.pushViewController(postVCDestination, animated: true)
        }
    }
    
    @IBAction func tappedImage(recognizer: AnyObject) {
        let postStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        if let postVCDestination = postStoryBoard.instantiateViewController(withIdentifier: "profileView") as? ProfileViewController {
            postVCDestination.uid = uid
            self.navigationController?.pushViewController(postVCDestination, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShareSegue" {
            let dest = segue.destination as! ShareViewController
            dest.postID = postID
        }
    }
}
