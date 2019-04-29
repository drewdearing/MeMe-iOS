//
//  ProfilePreviewViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 4/10/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

class ProfilePreviewViewController: UIViewController {

    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var downvoteButton: UIButton!
    @IBOutlet var downvoteLabel: UILabel!
    @IBOutlet var upvoteLabel: UILabel!
    
    var post:String!
    var memeURL:String = ""
    var uid:String = ""
    var upvotes:Int32 = 0
    var downvotes:Int32 = 0
    var color:String = ""
    var timestamp:Timestamp = Timestamp(s: 0)
    var downvoted:Bool = false
    var upvoted: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navItem.title = "Meme"
        cache.getPost(id: post) { (post) in
            if let post = post {
                self.fill(post: post)
            }
        }
    }
    
    func fill(post:Post){
        image.image = nil
        image.backgroundColor = UIColor(hex: post.color)
        upvotes = post.upvotes
        downvotes = post.downvotes
        upvoted = post.upvoted
        color = post.color
        timestamp = Timestamp(s: post.seconds, n: post.nanoseconds)
        downvoted = post.downvoted
        memeURL = post.photoURL
        descriptionLabel.text = post.desc
        uid = post.uid
        updateVoteCounter()
        
        cache.getProfile(uid: uid) { (profile) in
            if let profile = profile {
                let username = profile.username
                self.usernameLabel.text = username
            }
        }
        
        cache.getImage(imageURL: memeURL) { (postImage) in
            self.image.image = postImage
        }
    }
    
    func updateVoteCounter(){
        if upvoted {
            upvoteButton.setImage(#imageLiteral(resourceName: "up-arrow-enabled"), for: .normal)
        }
        else{
            upvoteButton.setImage(#imageLiteral(resourceName: "up-arrow"), for: .normal)
        }
        if downvoted {
            downvoteButton.setImage(#imageLiteral(resourceName: "angle-arrow-down-enabled"), for: .normal)
        }
        else{
            downvoteButton.setImage(#imageLiteral(resourceName: "angle-arrow-down"), for: .normal)
        }
        
        upvoteLabel.text = String(upvotes)
        downvoteLabel.text = String(downvotes)
    }
    
    @IBAction func upVote(_ sender: Any) {
        downvoteButton.isUserInteractionEnabled = false
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
            urlPathBase = urlPathBase.appending("&post=" + post)
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
                        self.downvoteButton.isUserInteractionEnabled = true
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
        downvoteButton.isUserInteractionEnabled = false
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
            urlPathBase = urlPathBase.appending("&post=" + post)
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
                        self.downvoteButton.isUserInteractionEnabled = true
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
        cache.updatePost(id: post, data: data) { (post) in
            if let post = post {
                self.downvotes = post.downvotes
                self.upvotes = post.upvotes
                self.upvoted = post.upvoted
                self.downvoted = post.downvoted
                self.updateVoteCounter()
            }
        }
    }
}
