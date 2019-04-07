//
//  Message.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 4/4/19.
//  Copyright © 2019 meme. All rights reserved.
//

import Foundation
import MessageKit

class Img : MediaItem {
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
    
}

struct Message: MessageType {
    var sender: Sender
    var messageId: String
    var sentDate: Date
    var content: String
    var image: Bool
    var kind: MessageKind {
        if image {
            return .photo(UIImage())
        } else {
        return .text(content)
        }
    }
    
    init(id:String, kind:MessageKind, sender:Sender) {
        self.kind = kind
        self.sender = sender
        self.messageId = id
        sentDate = NSDate() as Date
    }
}
