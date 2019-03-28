//
//  HomeView.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

struct FeedCellData {
    var username: String
    var uid: String
    var post: String
    var imageURL: String
    var profilePicURL: String
    var upvotes: Int
    var downvotes: Int
}

let HomeTableCellId = "FeedTableViewCell"
class HomeView: UIView, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var data:[FeedCellData] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableCellId, for: indexPath as IndexPath) as! FeedTableViewCell
        cell.cellTitle.text = data[indexPath.row].username
        cell.downVoteCounter.text = String(data[indexPath.row].downvotes)
        cell.upVoteCounter.text = String(data[indexPath.row].upvotes)
        cell.memeURL = data[indexPath.row].imageURL
        cell.uid = data[indexPath.row].uid
        cell.postID = data[indexPath.row].post
        cell.profileURL = data[indexPath.row].profilePicURL
        
        if cell.memeURL != nil {
            let url = URL(string: cell.memeURL!)
            let data = try? Data(contentsOf: url!)
            if let imageData = data {
                cell.memePic.image = UIImage(data:imageData)
            }
        }
        
        if cell.profileURL != nil {
            let url = URL(string: cell.profileURL!)
            let data = try? Data(contentsOf: url!)
            if let imageData = data {
                cell.profilePic.image = UIImage(data:imageData)
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
    
    override init(frame: CGRect){
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("HomeView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        tableView.register(UINib.init(nibName: HomeTableCellId, bundle: nil), forCellReuseIdentifier: HomeTableCellId)
        tableView.delegate = self
        tableView.dataSource = self
        getUserIDs()
    }
    
    private func getData(uid: String, page: Int) {
        
        
    }
    
    
    
    private func getUserIDs(){
        if let currentUser = Auth.auth().currentUser {
            var users:[String] = [currentUser.uid]
            let userRef = Firestore.firestore().collection("users").document(currentUser.uid)
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let data = document.data(){
                        if let following = data["following"] as? [String] {
                            for user in following {
                                users.append(user)
                            }
                            self.getUsernames(users: users)
                        }
                    }
                } else {
                    print("User does not exist")
                }
            }
        }
    }
    
    private func getUsernames(users:[String]){
        for user in users {
            let userRef = Firestore.firestore().collection("users").document(user)
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let data = document.data(){
                        if let username = data["username"] as? String {
                            if let profilePicURL = data["profilePicURL"] as? String {
                                self.addUserPosts(username: username, profilePicURL: profilePicURL, user: user)
                            }
                        }
                    }
                } else {
                    print("User does not exist")
                }
            }
        }
    }
    
    private func addUserPosts(username:String, profilePicURL:String, user:String){
        Firestore.firestore().collection("post").whereField("uid", isEqualTo: String(describing: user)).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    if let photoURL = data["photoURL"] as? String {
                        if let upvotes = data["upvotes"] as? Int {
                            if let downvotes = data["downvotes"] as? Int {
                                let newPostCellData = FeedCellData(username: username, uid: user, post: document.documentID, imageURL: photoURL, profilePicURL: profilePicURL, upvotes: upvotes, downvotes: downvotes)
                                self.data.append(newPostCellData)
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
}
