//
//  messageView.swift
//  MeMe
//
//  Created by Gia Bao Than on 3/13/19.
//  Copyright © 2019 meme. All rights reserved.
//

import UIKit

private let cellIdentifier = "GroupChatTableViewCell"

class MessageView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var contentView: UIView!
    
    private var groupChats: [GroupChat] = []
    @IBOutlet weak var groupChatsTableView: UITableView!
    
    override init(frame: CGRect){
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func push(view:NavigationView){
        addSubview(view)
        view.frame = self.bounds
    }
    
    func pop(){
        if subviews.count > 1 {
            let view = subviews[subviews.count - 1]
            view.removeFromSuperview()
        }
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("MessageView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        groupChatsTableView.register(UINib.init(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, widthForRowAt indexPath: IndexPath) -> CGFloat {
        return self.bounds.width
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        groupChatsTableView.deselectRow(at: indexPath, animated: true)
    }
    
}
