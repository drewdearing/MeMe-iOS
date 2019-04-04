//
//  GroupChatViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

private let groupChatSettingsStoryIdentifier = "GroupChatSettingsVCID"

private let cellReuseIdentifier = "MessageTableViewCell"

class GroupChatViewController: UIViewController,
    UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet var messagesTableView: UITableView!
    
    var groupChat: GroupChat!
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let messageCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath as IndexPath) as! MessageTableViewCell
        
        let row = indexPath.row
        
        messageCell.disableReceiver()
//        messageCell.senderMessageLabel.text = message.message
//        messageCell.senderMemeImageView.isHidden = true
        
        return messageCell
        
    }
    
}
