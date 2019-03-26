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
        getPosts()
    }
    
    private func getPosts(){
        if let currentUser = Auth.auth().currentUser {
            print(currentUser.uid)
            var posts:[String] = []
            let userRef = Firestore.firestore().collection("users").document(currentUser.uid)
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let data = document.data(){
                        if let userPosts = data["posts"] as? [String] {
                            for post in userPosts {
                                posts.append(post)
                            }
                        }
                    }
                } else {
                    print("User does not exist")
                }
            }
            for post in posts {
                //add posts
            }
        }
    }
    
}
