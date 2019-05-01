//
//  Message.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/4/19.
//  Copyright © 2019 meme. All rights reserved.
//

import Foundation
import MessageKit

class MessageImage: MediaItem {
    var url: URL?
    var image: UIImage?
    static var placeholderImage:UIImage = #imageLiteral(resourceName: "user_male")
    var placeholderImage: UIImage
    var size: CGSize
    var postID: String
    
    init(image: UIImage, post:String){
        self.image = image
        self.size = image.size
        self.placeholderImage = MessageImage.placeholderImage
        self.postID = post
    }
}

struct Message: MessageType {
    var messageId: String
    let content: String
    let sentDate: Date
    let sender: Sender
    var image: MessageImage?
    
    var kind: MessageKind {
        if let image = image {
            return .photo(image)
        } else {
            return .text(content)
        }
    }
    
    var postID: String {
        if let image = image {
            return image.postID
        }
        return ""
    }
    
    init(id:String, content:String = "", image:MessageImage? = nil, sender:Sender, date: Date) {
        self.image = image
        self.content = content
        self.sender = sender
        self.messageId = id
        sentDate = date
    }
}
