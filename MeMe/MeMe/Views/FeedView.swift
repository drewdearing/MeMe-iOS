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
    let username: String
    let description: String
    let uid: String
    let post: String
    let imageURL: String
    let profilePicURL: String
    let upvotes: Int
    let downvotes: Int
    let timestamp: Timestamp
}

struct Timestamp: Codable {
    let _seconds:Int
    
    init(){
        let currentTime = NSDate()
        self._seconds = Int(currentTime.timeIntervalSince1970)
    }
}

let appDelegate = UIApplication.shared.delegate as? AppDelegate
let cache = Cache.get()

class FeedView: UIView, UITableViewDelegate, UITableViewDataSource {

    var postData:[String:FeedCell] = [:]
    var data:[FeedCell] = []
    var feed = false
    var currentPage = 1
    var urlPath = ""
    var loaded = false
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableCellId, for: indexPath as IndexPath) as! FeedTableViewCell
        let feedCell = data[indexPath.row]
        cell.memePic.image = nil
        cell.profilePic.image = nil
        cell.cellTitle.text = feedCell.username
        cell.downVoteCounter.text = String(feedCell.downvotes)
        cell.descriptionLabel.text = feedCell.desc
        cell.upVoteCounter.text = String(feedCell.upvotes)
        cell.memeURL = feedCell.imageURL
        cell.uid = feedCell.uid
        cell.postID = feedCell.post
        cell.profileURL = feedCell.profilePicURL
        cell.selectionStyle = .none
        
        DispatchQueue.global(qos: .background).async {
            if let memePic = cache.getImage(id: feedCell.post) {
                DispatchQueue.main.async {
                    cell.memePic.image = memePic
                }
            }
            else{
                if cell.memeURL != nil {
                    let url = URL(string: cell.memeURL!)
                    let data = try? Data(contentsOf: url!)
                    if let imgData = data {
                        let image = UIImage(data:imgData)
                        DispatchQueue.main.async {
                            cell.memePic.image = image
                        }
                        cache.addImage(id: feedCell.post, image: image)
                    }
                }
            }
            if let profilePic = cache.getImage(id: feedCell.uid) {
                DispatchQueue.main.async {
                    cell.profilePic.image = profilePic
                }
            }
            else{
                if cell.profileURL != nil {
                    let url = URL(string: cell.profileURL!)
                    let data = try? Data(contentsOf: url!)
                    if let imgData = data {
                        let image = UIImage(data:imgData)
                        DispatchQueue.main.async {
                            cell.profilePic.image = image
                        }
                        cache.addProfilePic(id: feedCell.uid, image: image)
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 352
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //deselect row when tapped
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func loadPosts(){
        print("loading posts")
        DispatchQueue.global(qos: .background).async {
            let data = cache.getPosts(feed: self.feed)
            for post in data {
                self.postData[post.post] = post
            }
            self.update()
            self.getPosts()
        }
    }
    
    func getPosts() {
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
    
    func addPost(post: FeedCellData) {
        if let cell = cache.addPost(data: post, feed: feed){
            postData[cell.post] = cell
            update()
        }
    }
    
    func update(){
        //override me
    }

}
