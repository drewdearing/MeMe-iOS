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
    var posts: [FeedCellData]
}

struct FeedCellData: Codable {
    var username: String
    var description: String
    var uid: String
    var post: String
    var imageURL: String
    var profilePicURL: String
    var upvotes: Int
    var downvotes: Int
    var timestamp: Timestamp
    var upvoted: Bool
    var downvoted: Bool
}

struct Timestamp: Codable {
    let _seconds:Int
    
    init(){
        let currentTime = NSDate()
        self._seconds = Int(currentTime.timeIntervalSince1970)
    }
    
    init(s:Int){
        self._seconds = s
    }
}

let appDelegate = UIApplication.shared.delegate as? AppDelegate
let cache = Cache.get()

protocol PostNavigationDelegate {
    func navigateToPost(postVC:PostViewController)
}

class FeedView: UIView, UITableViewDelegate, UITableViewDataSource, FeedCellDelegate, IndividualPostDelegate {
    var postData:[String:FeedCell] = [:]
    var data:[FeedCell] = []
    var feed = false
    var currentPage = 1
    var urlPath = ""
    var loaded = false
    var delegate:PostNavigationDelegate?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableCellId, for: indexPath as IndexPath) as! FeedTableViewCell
        let feedCell = data[indexPath.row]
        cell.fill(feedCell: feedCell)
        cell.delegate = self
        return cell
    }
    
    func reload() {
        if loaded {
            loadPosts()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 352
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let postStoryBoard: UIStoryboard = UIStoryboard(name: "Post", bundle: nil)
        if let postVC = postStoryBoard.instantiateViewController(withIdentifier: "individualPost") as? PostViewController {
            let feedCell = data[indexPath.row]
            postVC.post = feedCell
            postVC.index = indexPath
            postVC.delegate = self
            if let delegate = delegate {
                delegate.navigateToPost(postVC: postVC)
            }
        }
    }
    
    func loadPosts(){
        print("loading posts")
        DispatchQueue.global(qos: .background).async {
            let data = cache.getPosts(feed: self.feed)
            /*for post in data {
                self.postData[post.post] = post
            }*/
            self.update()
            self.getPosts()
        }
    }
    
    private func getPosts() {
        if let currentUser = Auth.auth().currentUser {
            let useHUD = self.postData.count <= 0
            if useHUD {
                DispatchQueue.main.async {
                    SVProgressHUD.show(withStatus: "loading...")
                }
            }
            var urlPathBase = self.urlPath
            urlPathBase = urlPathBase.appending("?uid=" + currentUser.uid)
            urlPathBase = urlPathBase.appending("&page="+String(self.currentPage))
            let request = NSMutableURLRequest()
            request.url = URL(string: urlPathBase)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
                guard let data = data else { return }
                do {
                    let postContainer = try JSONDecoder().decode(FeedContainer.self, from: data)
                    DispatchQueue.main.async {
                        let cells = cache.addPosts(data: postContainer.posts, feed: self.feed)
                        for cell in cells {
                            self.postData[cell.post] = cell
                        }
                        if useHUD {
                            DispatchQueue.main.async {
                                SVProgressHUD.dismiss()
                            }
                        }
                        self.loaded = true
                        self.update()
                    }
                } catch let jsonErr {
                    print("Error: \(jsonErr)")
                }
            }
            task.resume()
        }
    }
    
    func addPost(post: FeedCellData, feed:Bool, update:Bool) {
        if let cell = cache.addPost(data: post, feed: feed){
            if !self.feed || feed {
                postData[cell.post] = cell
                if update {
                    self.update()
                }
            }
        }
    }
    
    func refreshCell(index: IndexPath) {
        //override
    }
    
    func update(){
        //override me
    }

}
