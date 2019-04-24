//
//  GroupChatsViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/4/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit
import Firebase

private let cellIdentifier = "GroupChatTableViewCell"

class GroupChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, addGroupsDelegate {

    @IBOutlet var groupChatsTableView: UITableView!
    private var groupChats: [GroupChat] = []
    var selectedChat:GroupChat?
    
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        groupChatsTableView.delegate = self
        groupChatsTableView.dataSource = self
        
        setUpGroups()
        
        let user = Auth.auth().currentUser
        let ref = Firestore.firestore().collection("users").document((user?.uid)!).collection("groups")
        listener = ref.addSnapshotListener{ query,error in
            guard let snapshot = query else {
                print("ERROR")
                return
            }
            snapshot.documentChanges.forEach{ change in
                self.updateGroups(change)
            }
        }
    }
    
    private func updateGroups(_ change: DocumentChange) {
        if change.document.exists {
            for group in groupChats {
                if group.groupId == change.document.documentID {
                    group.groupChatName = change.document.get("name") as? String
                }
            }
            groupChatsTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let groupChatCell = groupChatsTableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as? GroupChatTableViewCell
        
        let row = indexPath.row
        let groupChat = groupChats[row]
        
        groupChatCell?.groupNameLabel.text = groupChat.groupChatName
        groupChatCell?.unreadMessagesLabel.text = String(groupChat.unreadMessages)
        
        return groupChatCell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        groupChatsTableView.deselectRow(at: indexPath, animated: true)
        selectedChat = groupChats[indexPath.row]
        performSegue(withIdentifier: "ChatSelectSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChatSelectSegue" {
            let dest = segue.destination as! ChatViewController
            dest.chat = selectedChat
        } else if segue.identifier == "GroupSettingsSegue" {
            let dest = segue.destination as! GroupChatSettingsViewController
            dest.delegate = self
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func setUpGroups() {
        if let currentUser = Auth.auth().currentUser {
            let q = DispatchQueue(label:"LoadGroups")
            
            q.sync {
                let db = Firestore.firestore().collection("users").document(currentUser.uid).collection("groups")
                db.getDocuments() { (querySnapshot, err) in
                    if let err = err {
                        print("Error getting documents: \(err)")
                        return
                    } else {
                        for document in querySnapshot!.documents {
                            let name = document.get("name")
                            let id = document.documentID
                                self.groupChats.append(GroupChat(id: id, groupChatName: name as! String))
                        }
                    }
                    //SVProgressHUD.dismiss()
                    self.groupChatsTableView.reloadData()
                }
            }
        }
    }
    func addGroup(name: String, id: String) {
        groupChats.append(GroupChat(id: id, groupChatName: name))
        groupChatsTableView.reloadData()
    }
}
