//
//  ShareViewController.swift
//  MeMe
//
//  Created by Drew Dearing on 4/10/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import MessageKit

class ShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    var postID:String!
    var groups:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.allowsMultipleSelection = true
        self.tableView.allowsMultipleSelectionDuringEditing = true
        SVProgressHUD.show(withStatus: "loading...")
        if let currentUser = Auth.auth().currentUser {
            let uid = currentUser.uid
            Firestore.firestore().collection("users").document(uid).collection("groups").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        let id = document.documentID
                        self.groups.append(id)
                    }
                    SVProgressHUD.dismiss()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath as IndexPath)
        cache.getGroup(id: groups[indexPath.row]) { (group) in
            if let group = group {
                cell.textLabel?.text = group.name
            }
        }
        return cell
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func done(_ sender: Any) {
        let uid = Auth.auth().currentUser!.uid
        Timestamp.getServerTime { (serverTime) in
            if let sent = serverTime {
                if let indexPaths = self.tableView.indexPathsForSelectedRows {
                    for indexPath in indexPaths {
                        let id = self.groups[indexPath.row]
                        let ref = Firestore.firestore().collection("groups").document(id).collection("messages")
                        ref.document().setData([
                            "sent": sent.dateValue(),
                            "uid": uid,
                            "image": true,
                            "content": self.postID
                        ]) { error in
                            if error != nil {
                                print("ERROR")
                                return
                            }
                        }
                    }
                    self.dismiss(animated: true)
                }
            }
        }
    }
}
