//
//  GroupChatViewController.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

private let groupChatSettingsStoryIdentifier = "GroupChatSettingsVCID"

class GroupChatViewController: UIViewController {
    
    
    var groupChat: GroupChat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setNavigationBar()
    }
    
    private func setNavigationBar() {
        self.navigationItem.title = groupChat.groupChatName
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(GroupChatViewController.editGroupChat))
        
    }
    
    @objc func editGroupChat() {
        let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let groupChatSettingsVCDestination = mainStoryBoard.instantiateViewController(withIdentifier: groupChatSettingsStoryIdentifier) as? GroupChatSettingsViewController {
            groupChatSettingsVCDestination.groupChat = groupChat
            self.navigationController?.pushViewController(groupChatSettingsVCDestination, animated: true)
        }
    }
    
}
