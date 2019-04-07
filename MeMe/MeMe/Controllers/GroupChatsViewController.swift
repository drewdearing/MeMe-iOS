//
//  GroupChatsViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/4/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

private let cellIdentifier = "GroupChatTableViewCell"

class GroupChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var groupChatsTableView: UITableView!
    private var groupChats: [GroupChat] = [GroupChat(id: "1sF1dOFQTu3xSYQsWl4Y", groupChatName: "sup")]
    var selectedChat:GroupChat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        groupChatsTableView.delegate = self
        groupChatsTableView.dataSource = self
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
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
