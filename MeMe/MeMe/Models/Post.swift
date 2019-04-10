//
//  MemePost.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 3/28/19.
//  Copyright © 2019 meme. All rights reserved.
//
import UIKit

import Foundation
import Firebase
import FirebaseFirestore

struct Post {
    var userID: String
    var photoURL: String
    var topText: String
    var bottomText: String
    var description: String
    var timeStamp: Firebase.Timestamp
    var upVotes: Int
    var downVotes: Int
    
    var dictionary:[String: Any] {
        return [
            "uid": userID,
            "photoURL": photoURL,
            "topText": topText,
            "bottomText": bottomText,
            "description": description,
            "timestamp": timeStamp,
            "upvotes": upVotes,
            "downvotes": downVotes]
    }
}

extension Post : DocumentSerializable {
    init?(dictionary:[String: Any]) {
        guard
            let userID = dictionary["uid"] as? String,
            let photoURL = dictionary["photoURL"] as? String,
            let topText = dictionary["topText"] as? String,
            let bottomText = dictionary["bottomText"] as? String,
            let description = dictionary["description"] as? String,
            let timeStamp = dictionary["timestamp"] as? Firebase.Timestamp,
            let upVotes = dictionary["upvotes"] as? Int,
            let downVotes = dictionary["downvotes"] as? Int
            else {
                return nil
        }
        
        self.init(userID: userID, photoURL: photoURL, topText: topText,
                  bottomText: bottomText, description: description,
                  timeStamp: timeStamp, upVotes: upVotes, downVotes: downVotes)
    }
}

extension Post: Equatable {
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.userID == rhs.userID &&
            lhs.photoURL == rhs.photoURL &&
            lhs.topText == rhs.topText &&
            lhs.bottomText == rhs.bottomText &&
            lhs.description == rhs.description &&
            lhs.timeStamp == rhs.timeStamp &&
            lhs.upVotes == rhs.upVotes &&
            lhs.downVotes == rhs.downVotes
    }
}

extension Post: Hashable {
    var hashValue: Int {
        return userID.hashValue ^ photoURL.hashValue ^ timeStamp.hashValue
    }
}

struct PostImage {
    var post: Post
    var image: UIImage
}

extension PostImage : DocumentSerializable {
    init?(dictionary:[String: Any]) {
        guard
            let post = dictionary["post"] as? Post,
            let image = dictionary["image"] as? UIImage
            else {
                return nil
        }
        
        self.init(post: post, image: image)
    }
}

extension PostImage: Equatable {
    static func == (lhs: PostImage, rhs: PostImage) -> Bool {
        return lhs.post.timeStamp == rhs.post.timeStamp
    }
}

extension PostImage: Comparable {
    static func < (lhs: PostImage, rhs: PostImage) -> Bool {
        
        if lhs.post.timeStamp.seconds != rhs.post.timeStamp.seconds {
            return lhs.post.timeStamp.seconds > rhs.post.timeStamp.seconds
        }
        
        return true
        
    }
}

extension PostImage: Hashable {
    var hashValue: Int {
        return post.hashValue ^ image.hashValue
    }
}
