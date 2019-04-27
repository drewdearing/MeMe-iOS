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

    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        groupChatsTableView.delegate = self
        groupChatsTableView.dataSource = self
        
        setUpGroups()
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
            dest.chatID = selectedChat?.groupId
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
                    }
                    else {
                          for document in querySnapshot!.documents {
                            cache.getGroup(id: document.documentID, complete: { (group) in
                                if let group = group {
                                    let name = group.name
                                    let groupID = group.id
                                    self.groupChats.append(GroupChat(id: groupID, groupChatName: name))
                                    self.groupChatsTableView.reloadData()
                                }
                            })
                          }
                    }
                }
            }
        }
    }
    func addGroup(name: String, id: String) {
        groupChats.append(GroupChat(id: id, groupChatName: name))
        groupChatsTableView.reloadData()
    }
}
