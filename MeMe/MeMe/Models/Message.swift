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
    
    init(url:String){
        self.url = URL(string: url)
        self.placeholderImage = MessageImage.placeholderImage
        self.size = placeholderImage.size
    }
    
    func get(completion: (UIImage) -> (Void)){
        if let img = image {
            completion(img)
        }
        else{
            let data = try? Data(contentsOf: url!)
            if let imgData = data {
                let image = UIImage(data:imgData)
                self.size = image!.size
                completion(image!)
            }
            else{
                completion(MessageImage.placeholderImage)
            }
        }
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
    
    var imageURL:String {
        if let image = image {
            return (image.url?.absoluteString)!
        }
        return ""
    }
    
    init(id:String, content:String = "", image:MessageImage? = nil, sender:Sender) {
        self.image = image
        self.content = content
        self.sender = sender
        self.messageId = id
        sentDate = NSDate() as Date
    }
    
    init(id:String, content:String = "", image:MessageImage? = nil, sender:Sender, date: Date) {
        self.image = image
        self.content = content
        self.sender = sender
        self.messageId = id
        sentDate = date
    }
}
