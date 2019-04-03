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

var imageData:[String:UIImage] = [:]
var profilePicData:[String:UIImage] = [:]
var taskGroup:DispatchGroup?
var taskQueue:[[FeedCellData]] = []

let appDelegate = UIApplication.shared.delegate as? AppDelegate

class FeedView: UIView, UITableViewDelegate, UITableViewDataSource, editMemeVCDelegate {

    var postData:[FeedCell] = []
    var currentPage = 1
    var urlPath = ""
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableCellId, for: indexPath as IndexPath) as! FeedTableViewCell
        cell.memePic.image = nil
        cell.profilePic.image = nil
        cell.cellTitle.text = postData[indexPath.row].username
        cell.downVoteCounter.text = String(postData[indexPath.row].downvotes)
        cell.descriptionLabel.text = postData[indexPath.row].desc
        cell.upVoteCounter.text = String(postData[indexPath.row].upvotes)
        cell.memeURL = postData[indexPath.row].imageURL
        cell.uid = postData[indexPath.row].uid
        cell.postID = postData[indexPath.row].post
        cell.profileURL = postData[indexPath.row].profilePicURL
        DispatchQueue.global(qos: .background).async {
            if let memePic = imageData[self.postData[indexPath.row].post] {
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
                        imageData[self.postData[indexPath.row].post] = image
                    }
                }
            }
            let profilePic = profilePicData[self.postData[indexPath.row].uid]
            if profilePic != nil && !self.postData[indexPath.row].dirty {
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
                        profilePicData[self.postData[indexPath.row].uid] = image
                    }
                }
            }
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 352
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //deselect row when tapped
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func loadPosts(predicate:NSPredicate? = nil){
        print("loading posts")
        if let context = appDelegate?.persistentContainer.viewContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"FeedCell")
            if predicate != nil {
                fetchRequest.predicate = predicate
            }
            fetchRequest.includesPropertyValues = true
            let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { results in
                if let cache = results.finalResult {
                    self.postData = cache as! [FeedCell]
                    self.update()
                    self.getPosts()
                }
            }
            
            do {
                let privateManagedObjectContext: NSManagedObjectContext = {
                    let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                    moc.parent = context
                    return moc
                }()
                try privateManagedObjectContext.execute(asyncRequest)
            } catch let error {
                print("NSAsynchronousFetchRequest error: \(error)")
            }
        }
    }
    
    func getPosts() {
        if let currentUser = Auth.auth().currentUser {
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
                        self.addPostsToCache(data:postContainer.posts)
                    }
                } catch let jsonErr {
                    print("Error: \(jsonErr)")
                }
            }
            task.resume()
        }
    }
    
    func cellFromData(post: FeedCellData, context:NSManagedObjectContext) -> FeedCell? {
        let newCell = FeedCell(context: context)
        newCell.desc = post.description
        newCell.downvotes = Int32(post.downvotes)
        newCell.imageURL = post.imageURL
        newCell.post = post.post
        newCell.profilePicURL = post.profilePicURL
        newCell.uid = post.uid
        newCell.upvotes = Int32(post.upvotes)
        newCell.username = post.username
        newCell.feed = false
        newCell.dirty = false
        newCell.seconds = Int64(post.timestamp._seconds)
        return newCell
    }
    
    func addMeme(post: FeedCellData) {
        if let context = appDelegate?.persistentContainer.viewContext {
            if let cell = cellFromData(post: post, context: context) {
                self.addCell(newPost: cell)
                do {
                    try context.save()
                    update()
                }
                catch{
                    print("error saving")
                }
            }
        }
    }
    
    func addCell(newPost: FeedCell) {
        postData.append(newPost)
    }
    
    func update(){
        //override me
    }
    
    func addPostsToCache(data:[FeedCellData]){
        let useHUD = postData.count <= 0
        if(useHUD){
            SVProgressHUD.show(withStatus: "Loading...")
        }
        if let context = appDelegate?.persistentContainer.viewContext {
            taskQueue.append(data)
            updateCache(context: context, useHUD: useHUD)
        }
    }
    
    func updateCache(context:NSManagedObjectContext, useHUD:Bool){
        if taskGroup == nil && taskQueue.count > 0 {
            taskGroup = DispatchGroup()
            let taskData = taskQueue[0]
            for post in taskData {
                taskGroup!.enter()
                let cache = self.postData.filter { $0.post == post.post }
                if cache.count > 0 {
                    for cachedPost in cache {
                        cachedPost.downvotes = Int32(post.downvotes)
                        cachedPost.upvotes = Int32(post.upvotes)
                        cachedPost.username = post.username
                        if cachedPost.profilePicURL != post.profilePicURL {
                            cachedPost.profilePicURL = post.profilePicURL
                            cachedPost.dirty = true
                        }
                    }
                }
                else{
                    if let newCell = cellFromData(post: post, context: context) {
                        self.addCell(newPost: newCell)
                    }
                }
                taskGroup!.leave()
            }
            
            taskGroup!.notify(queue: .main) {
                do {
                    try context.save()
                    taskQueue.removeFirst()
                    taskGroup = nil
                    if taskQueue.count > 0 {
                        self.updateCache(context: context, useHUD: useHUD)
                    }
                    else{
                        self.update()
                        if(useHUD){
                            SVProgressHUD.dismiss()
                        }
                    }
                }
                catch{
                    print("cant save")
                }
            }
        }
    }

}
