//
//  GroupChat.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//

import Foundation

class GroupChat {
    var groupChatName: String!
    var unreadMessages: Int!
    
    init(groupChatName: String, unreadMessages: Int) {
        self.groupChatName = groupChatName
        self.unreadMessages = unreadMessages
    }
}
