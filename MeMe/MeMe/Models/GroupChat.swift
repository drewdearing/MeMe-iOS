//
//  GroupChat.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//

//a struct which stores GroupChat info for future use, such as a chat's name, id, etc.
import Foundation

class GroupChat {
    var groupChatName: String!
    var unreadMessages: Int!
    var groupId:String!
    
    init(id:String, groupChatName: String) {
        self.groupId = id
        self.groupChatName = groupChatName
        self.unreadMessages = 0
    }
}
