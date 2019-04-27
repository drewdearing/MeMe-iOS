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
    var postID:String?
    var photoURL:String?
    var data:[GroupChat] = []
    
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
                        let name = document.data()["name"] as! String
                        let id = document.documentID
                        self.data.append(GroupChat(id: id, groupChatName: name))
                    }
                    SVProgressHUD.dismiss()
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath as IndexPath)
        cell.textLabel?.text = data[indexPath.row].groupChatName
        return cell
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func done(_ sender: Any) {
        if let profile = getCurrentProfile() {
            if let currentUser = Auth.auth().currentUser {
                if let indexPaths = self.tableView.indexPathsForSelectedRows {
                    for indexPath in indexPaths {
                        let id = data[indexPath.row].groupId
                        let ref = Firestore.firestore().collection("groups").document(id!).collection("messages")
                        let image = MessageImage(url: photoURL!, post: postID!)
                        let message = Message(id: ref.document().documentID, content: "", image: image, sender: Sender(id: currentUser.uid, displayName: profile.username))
                        sendMessage(message: message, ref: ref)
                    }
                    dismiss(animated: true)
                }
            }
        }
    }
    
    func sendMessage(message:Message, ref:CollectionReference){
        var content = message.content
        if message.image != nil {
            content = message.postID
        }
        ref.document(message.messageId).setData([
            "sent": message.sentDate,
            "uid": message.sender.id,
            "image": message.image != nil,
            "content": content
        ]) { error in
            if error != nil {
                print("ERROR")
                return
            }
        }
    }
    
}
