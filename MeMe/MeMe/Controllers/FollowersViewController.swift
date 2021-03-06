//
//  FollowersViewController.swift
//  MeMe
//
//  Created by Gia Bao Than on 5/6/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

class FollowersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var titleLabel: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    
    var uid = String()
    var vcTitle = String()
    var members: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.title = vcTitle
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        
        if vcTitle == "Followers" {
            let q = DispatchQueue(label:"followers")
            q.sync {
                let db = Firestore.firestore().collection("users").document(uid).collection("followers")
                db.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        return
                    } else {
                        for document in querySnapshot!.documents {
                            let userID = document.documentID
                            cache.getProfile(uid: userID) { (profile) in
                                if let profile = profile {
                                    self.members.append(profile.id)
                                }
                            }
                        }
                        self.tableView.reloadData()
                    }
                }
            }
        } else if vcTitle == "Following" {
            let q = DispatchQueue(label:"following")
            q.sync {
                let db = Firestore.firestore().collection("users").document(uid).collection("following")
                db.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        return
                    } else {
                        for document in querySnapshot!.documents {
                            let userID = document.documentID
                            cache.getProfile(uid: userID) { (profile) in
                                if let profile = profile {
                                    self.members.append(profile.id)
                                }
                            }
                        }
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "followersCell", for: indexPath as IndexPath)
        let currentUser = members[indexPath.row]
        
        cache.getProfile(uid: currentUser) { (profile) in
            if let profile = profile {
                cell.textLabel?.text = profile.username
            }
        }
        return cell
    }

}
