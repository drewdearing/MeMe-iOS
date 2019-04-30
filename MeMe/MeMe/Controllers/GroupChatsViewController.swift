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

class GroupChatsViewController: TabViewController, UITableViewDelegate, UITableViewDataSource, addGroupsDelegate {
    
    @IBOutlet var groupChatsTableView: UITableView!
    private var groups: [String:Bool] = [:]
    private var groupChats:[String] = []
    var selectedChat:String?

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
        
        let groupChatCell = groupChatsTableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath as IndexPath) as! GroupChatTableViewCell
        
        cache.getGroup(id: groupChats[indexPath.row]) { (group) in
            if let group = group {
                groupChatCell.groupNameLabel.text = group.name
                groupChatCell.unreadMessagesLabel.text = String(group.unreadMessages)
            }
        }
        
        return groupChatCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        groupChatsTableView.deselectRow(at: indexPath, animated: true)
        selectedChat = groupChats[indexPath.row]
        performSegue(withIdentifier: "ChatSelectSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChatSelectSegue" {
            let dest = segue.destination as! ChatViewController
            dest.chatID = selectedChat
        } else if segue.identifier == "GroupSettingsSegue" {
            let dest = segue.destination as! GroupChatSettingsViewController
            dest.delegate = self
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func setUpGroups() {
        let currentUser = Auth.auth().currentUser!
        let groupsRef = Firestore.firestore().collection("users").document(currentUser.uid).collection("groups")
        groupsRef.addSnapshotListener { (query, err) in
            if let query = query {
                query.documentChanges.forEach { change in
                    if change.type == .added {
                        let groupId = change.document.documentID
                        self.groups[groupId] = true
                        self.updateData()
                        cache.addGroupUpdateListener(id: groupId) { (group) in
                            if let group = group, let inGroup = self.groups[group.id], inGroup {
                                self.updateData()
                            }
                        }
                    }
                    if change.type == .removed {
                        self.groups[change.document.documentID] = false
                        self.updateData()
                    }
                }
            }
        }
    }
    
    func updateData(){
        var newGroupChats:[String] = []
        for group in groups {
            let id = group.key
            let inGroup = group.value
            if inGroup {
                newGroupChats.append(id)
            }
        }
        groupChats = newGroupChats
        groupChatsTableView.reloadData()
    }
    
    func addGroup(name:String, id: String) {
        //cache.getGroup(id:  , complete: <#T##(Group?) -> Void#>)
        //groupChatsTableView.reloadData()
    }
    
    override func update() {
        
    }
}
