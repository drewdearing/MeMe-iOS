//
//  FeedView.swift
//  MeMe
//
//  Created by Drew Dearing on 4/2/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import CoreData
import SVProgressHUD
import Firebase

struct FeedContainer:Codable {
    var posts: [PostData]
}

class PostData: Codable {
    var id:String
    var uid:String
    var color:String
    var timestamp:Timestamp
    var upvotes:Int32
    var downvotes:Int32
    
    init(id:String, uid:String, color:String, timestamp:Timestamp, upvotes:Int32, downvotes:Int32){
        self.id = id
        self.uid = uid
        self.color = color
        self.timestamp = timestamp
        self.upvotes = upvotes
        self.downvotes = downvotes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        uid = try container.decode(String.self, forKey: .uid)
        color = try container.decode(String.self, forKey: .color)
        timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
        
        if let upvotes = try container.decodeIfPresent(Int32.self, forKey: .upvotes) {
            self.upvotes = upvotes
        } else {
            self.upvotes = 0
        }
        
        if let downvotes = try container.decodeIfPresent(Int32.self, forKey: .downvotes) {
            self.downvotes = downvotes
        } else {
            self.downvotes = 0
        }
    }
}

let appDelegate = UIApplication.shared.delegate as? AppDelegate
let cache = Cache.get()

protocol FeedViewDelegate {
    func navigateToProfile(profileVC: ProfileViewController)
    func navigateToPost(postVC:PostViewController)
}

class FeedView: UIView, UITableViewDelegate, UIScrollViewDelegate, UITableViewDataSource, FeedCellDelegate, IndividualPostDelegate {
    var postData:[String:PostData] = [:]
    var data:[PostData] = []
    var delegate:FeedViewDelegate?
    var hitTop = false
    var hitBottom = false
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableCellId, for: indexPath as IndexPath) as! FeedTableViewCell
        let feedCellData = data[indexPath.row]
        cell.fill(postData: feedCellData)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 352
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let postStoryBoard: UIStoryboard = UIStoryboard(name: "Post", bundle: nil)
        if let postVC = postStoryBoard.instantiateViewController(withIdentifier: "individualPost") as? PostViewController {
            let postData = data[indexPath.row]
            postVC.post = postData.id
            postVC.index = indexPath
            postVC.delegate = self
            if let delegate = delegate {
                delegate.navigateToPost(postVC: postVC)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!hitBottom && scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
            hitBottom = true
            print("bottom")
        }
        if (!hitTop && scrollView.contentOffset.y < 0){
            hitTop = true
            print("top")
        }
        if (scrollView.contentOffset.y >= 0 && scrollView.contentOffset.y <= (scrollView.contentSize.height - scrollView.frame.size.height)){
            hitBottom = false
            hitTop = false
        }
    }
    
    func reloadPosts(){
        postData = [:]
        //data = []
        SVProgressHUD.show(withStatus: "loading...")
        getPosts { (feedContainer) in
            for post in feedContainer.posts {
                self.postData[post.id] = post
            }
            self.update()
            SVProgressHUD.dismiss()
        }
    }
    
    func tappedAction(uid: String) {
        let postStoryBoard: UIStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        if let profileVC = postStoryBoard.instantiateViewController(withIdentifier: "profileView") as? ProfileViewController {
            profileVC.userID = uid
            profileVC.currentProfile = false
            if let delegate = delegate {
                delegate.navigateToProfile(profileVC: profileVC)
            }
        }
    }
    
    func addPost(post: PostData) {
        //add post to feed
    }
    
    func refreshCell(index: IndexPath) {
        //override
    }
    
    func update(){
        //override me
    }
    
    func getPosts(complete: @escaping (FeedContainer) -> Void) {
        //override me
    }

}
