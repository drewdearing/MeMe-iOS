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

struct MyPost {
    var userID: String
    var photoURL: String
    var description: String
    var timeStamp: Firebase.Timestamp
    var upVotes: Int
    var downVotes: Int
    
    var dictionary:[String: Any] {
        return [
            "uid": userID,
            "photoURL": photoURL,
            "description": description,
            "timestamp": timeStamp,
            "upvotes": upVotes,
            "downvotes": downVotes]
    }
}

extension MyPost : DocumentSerializable {
    init?(dictionary:[String: Any]) {
        guard
            let userID = dictionary["uid"] as? String,
            let photoURL = dictionary["photoURL"] as? String,
            let description = dictionary["description"] as? String,
            let timeStamp = dictionary["timestamp"] as? Firebase.Timestamp,
            let upVotes = dictionary["upvotes"] as? Int,
            let downVotes = dictionary["downvotes"] as? Int
            else {
                return nil
        }
        
        self.init(userID: userID, photoURL: photoURL, description: description,
                  timeStamp: timeStamp, upVotes: upVotes, downVotes: downVotes)
    }
}

extension MyPost: Equatable {
    static func == (lhs: MyPost, rhs: MyPost) -> Bool {
        return lhs.userID == rhs.userID &&
            lhs.photoURL == rhs.photoURL &&
            lhs.description == rhs.description &&
            lhs.timeStamp == rhs.timeStamp &&
            lhs.upVotes == rhs.upVotes &&
            lhs.downVotes == rhs.downVotes
    }
}

extension MyPost: Hashable {
    var hashValue: Int {
        return userID.hashValue ^ photoURL.hashValue ^ timeStamp.hashValue
    }
}

struct PostImage {
    var post: MyPost
    var image: UIImage
}

extension PostImage : DocumentSerializable {
    init?(dictionary:[String: Any]) {
        guard
            let post = dictionary["post"] as? MyPost,
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
