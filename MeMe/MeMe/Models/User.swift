//
//  User.swift
//  MeMe
//
//  Created by Yair Sanchez Nieto on 3/28/19.
//  Copyright © 2019 meme. All rights reserved.
//


//a struct which stores User info for future use, such as a user's email, username, etc.
import Foundation
import FirebaseFirestore

protocol DocumentSerializable {
    init?(dictionary:[String: Any])
}

struct User {
    var email: String
    var followers: [String]
    var following: [String]
    var numFollowers: Int
    var numFollowing: Int
    var posts: [String]
    var profilePicture: String
    var username: String
    
    var dictionary:[String: Any] {
        return [
            "email": email,
            "followers": followers,
            "following": following,
            "numFollowers": numFollowers,
            "numFollowing": numFollowing,
            "posts": posts,
            "profilePicURL": profilePicture,
            "username": username]
    }
}

extension User : DocumentSerializable {
    init?(dictionary:[String: Any]) {
        guard
            let email = dictionary["email"] as? String,
            let followers = dictionary["followers"] as? [String],
            let following = dictionary["following"] as? [String],
            let numFollowers = dictionary["numFollowers"] as? Int,
            let numFollowing = dictionary["numFollowing"] as? Int,
            let posts = dictionary["posts"] as? [String],
            let profilePicture = dictionary["profilePicURL"] as? String,
            let username = dictionary["username"] as? String
            else {
                return nil
        }
        
        self.init(email: email, followers: followers, following: following, numFollowers: numFollowers,
                  numFollowing: numFollowing, posts: posts, profilePicture: profilePicture,
                  username: username)
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.email == rhs.email &&
            lhs.followers == rhs.followers &&
            lhs.following == rhs.following &&
            lhs.numFollowers == rhs.numFollowers &&
            lhs.numFollowing == rhs.numFollowing &&
            lhs.posts == rhs.posts &&
            lhs.profilePicture == rhs.profilePicture &&
            lhs.username == rhs.username
    }
}

extension User: Hashable {
    var hashValue: Int {
        return email.hashValue ^ followers.hashValue ^ following.hashValue ^ posts.hashValue ^ profilePicture.hashValue ^ username.hashValue
    }
}
