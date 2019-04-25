//
//  Cache.swift
//  MeMe
//
//  Created by Drew Dearing on 4/3/19.
//  Copyright © 2019 meme. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Firebase

class Cache {
    private var postData:[String:Post] = [:]
    private var profileData:[String:Profile] = [:]
    private var imageData:[String:UIImage] = [:]
    
    private var imageTasks:[String:DispatchGroup?] = [:]
    private var profileTasks:[String:DispatchGroup?] = [:]
    private var postTasks:[String:DispatchGroup?] = [:]
    
    private var postListeners:[String:ListenerRegistration?] = [:]
    private var profileListeners:[String:ListenerRegistration?] = [:]
    
    private static var cache:Cache? = nil
    
    private init(){
        print("starting cache")
        if let context = getContext() {
            let postRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
            let profileRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
            do{
                let posts = try context.fetch(postRequest) as! [Post]
                let profiles = try context.fetch(profileRequest) as! [Profile]
                for post in posts {
                    postData[post.id] = post
                    let postRef = Firestore.firestore().collection("post").document(post.id)
                    postListeners[post.id] = postRef.addSnapshotListener { (postDoc, postDocErr) in
                        self.handlePostDoc(postDoc: postDoc)
                    }
                }
                for profile in profiles {
                    profileData[profile.id] = profile
                }
            }
            catch{
                print("cant fetch")
            }
        }
        print("cache loaded")
    }
    
    static func get() -> Cache {
        if let cache = Cache.cache {
            return cache
        }
        else{
            let cache = Cache()
            Cache.cache = cache
            return cache
        }
    }
    
    func getPost(id:String, complete: @escaping (Post?) -> Void) {
        if let post = postData[id] {
            complete(post)
        }
        else{
            if let dispatchGroup = postTasks[id], let group = dispatchGroup {
                DispatchQueue.global(qos: .background).async {
                    group.wait()
                    DispatchQueue.main.async {
                        self.getPost(id: id, complete: complete)
                    }
                }
            }
            else{
                let group = DispatchGroup()
                postTasks[id] = group
                group.enter()
                let postRef = Firestore.firestore().collection("post").document(id)
                postListeners[id] = postRef.addSnapshotListener { (postDoc, postDocErr) in
                    self.handlePostDoc(postDoc: postDoc)
                }
                DispatchQueue.global(qos: .background).async {
                    group.wait()
                    DispatchQueue.main.async {
                        self.getPost(id: id, complete: complete)
                    }
                }
            }
        }
    }
    
    func getImage(imageURL:String, complete: @escaping (UIImage?) -> Void){
        if let image = imageData[imageURL] {
            complete(image)
        }
        else{
            if let dispatchGroup = imageTasks[imageURL], let group = dispatchGroup {
                DispatchQueue.global(qos: .background).async {
                    group.wait()
                    DispatchQueue.main.async {
                        self.getImage(imageURL: imageURL, complete: complete)
                    }
                }
            }
            else{
                let group = DispatchGroup()
                imageTasks[imageURL] = group
                DispatchQueue.global(qos: .background).async {
                    group.enter()
                    let url = URL(string: imageURL)
                    let data = try? Data(contentsOf: url!)
                    if let imgData = data {
                        let image = UIImage(data:imgData)
                        self.imageData[imageURL] = image
                        DispatchQueue.main.async {
                            complete(image)
                            self.imageTasks[imageURL] = nil
                            group.leave()
                        }
                    }
                    else{
                        DispatchQueue.main.async {
                            complete(nil)
                            self.imageTasks[imageURL] = nil
                            group.leave()
                        }
                    }
                }
            }
        }
    }
    
    func getProfile(uid:String, complete: @escaping (Profile?) -> Void){
        if let profile = profileData[uid]{
            complete(profile)
        }
        else{
            if let dispatchGroup = profileTasks[uid], let group = dispatchGroup {
                DispatchQueue.global(qos: .background).async {
                    group.wait()
                    DispatchQueue.main.async {
                        self.getProfile(uid: uid, complete: complete)
                    }
                }
            }
            else{
                let group = DispatchGroup()
                profileTasks[uid] = group
                group.enter()
                let profileRef = Firestore.firestore().collection("users").document(uid)
                profileListeners[uid] = profileRef.addSnapshotListener { (profileDoc, profileErr) in
                    self.handleProfileDoc(profileDoc: profileDoc)
                }
                DispatchQueue.global(qos: .background).async {
                    group.wait()
                    DispatchQueue.main.async {
                        self.getProfile(uid: uid, complete: complete)
                    }
                }
            }
        }
    }
    
    func updatePost(id: String, data:[String:Any], complete: @escaping (Post?) -> Void){
        let upvotes = data["upvotes"] as! Int32
        let downvotes = data["downvotes"] as! Int32
        let upvoted = data["upvoted"] as! Bool
        let downvoted = data["downvoted"] as! Bool
        if let post = postData[id] {
            post.upvotes = upvotes
            post.downvotes = downvotes
            post.upvoted = upvoted
            post.downvoted = downvoted
            updateCore()
            complete(post)
        }
        else{
            getPost(id: id, complete: complete)
        }
    }
    
    func updateProfile(uid: String, data:[String:Any], complete: @escaping (Profile?) -> Void){
        let numFollowers = data["numFollowers"] as! Int32
        let numFollowing = data["numFollowing"] as! Int32
        let profilePicURL = data["profilePicURL"] as! String
        let username = data["username"] as! String
        let following = data["following"] as! Bool
        if let profile = profileData[uid] {
            profile.numFollowers = numFollowers
            profile.numFollowing = numFollowing
            profile.profilePicURL = profilePicURL
            profile.username = username
            profile.following = following
            updateCore()
            complete(profile)
        }
        else{
            getProfile(uid: uid, complete: complete)
        }
    }
    
    private func handleProfileDoc(profileDoc:DocumentSnapshot?){
        let uid = profileDoc!.documentID
        if let profileDoc = profileDoc, let data = profileDoc.data() {
            let currentUser = Auth.auth().currentUser!
            let followRef = profileDoc.reference.collection("followers").document(currentUser.uid)
            let numFollowers = data["numFollowers"] as! Int32
            let numFollowing = data["numFollowing"] as! Int32
            let profilePicURL = data["profilePicURL"] as! String
            let username = data["username"] as! String
            followRef.getDocument { (followDoc, followErr) in
                if let followDoc = followDoc {
                    var following = false
                    if followDoc.exists {
                        following = true
                    }
                    if self.profileData[uid] != nil {
                        let data:[String:Any] = [
                            "numFollowers": numFollowers,
                            "numFollowing": numFollowing,
                            "profilePicURL": profilePicURL,
                            "username": username,
                            "following": following
                        ]
                        self.updateProfile(uid: uid, data: data, complete: { (profile) in
                            if let dispatchGroup = self.profileTasks[uid], let group = dispatchGroup {
                                self.profileTasks[uid] = nil
                                group.leave()
                            }
                        })
                    }
                    else if let context = self.getContext(){
                        let profile = Profile(context: context)
                        profile.following = following
                        profile.id = uid
                        profile.numFollowers = numFollowers
                        profile.numFollowing = numFollowing
                        profile.profilePicURL = profilePicURL
                        profile.username = username
                        self.profileData[uid] = profile
                        self.updateCore()
                        if let dispatchGroup = self.profileTasks[uid], let group = dispatchGroup {
                            self.profileTasks[uid] = nil
                            group.leave()
                        }
                    }
                    else{
                        if let dispatchGroup = self.profileTasks[uid], let group = dispatchGroup {
                            self.profileTasks[uid] = nil
                            group.leave()
                        }
                    }
                }
                else{
                    if let dispatchGroup = self.profileTasks[uid], let group = dispatchGroup {
                        self.profileTasks[uid] = nil
                        group.leave()
                    }
                }
            }
        }
        else{
            if let dispatchGroup = self.profileTasks[uid], let group = dispatchGroup {
                self.profileTasks[uid] = nil
                group.leave()
            }
        }
    }
    
    private func handlePostDoc(postDoc:DocumentSnapshot?){
        let id = postDoc!.documentID
        if let postDoc = postDoc {
            if postDoc.exists {
                let currentUser = Auth.auth().currentUser
                let voteRef = Firestore.firestore().collection("post").document(id).collection("votes").document(currentUser!.uid)
                let data = postDoc.data()!
                let color = data["color"] as! String
                let description = data["description"] as! String
                let downvotes = data["downvotes"] as! Int32
                let upvotes = data["upvotes"] as! Int32
                let photoURL = data["photoURL"] as! String
                let timestamp = data["timestamp"] as! Firebase.Timestamp
                let uid = data["uid"] as! String
                voteRef.getDocument(completion: { (voteDoc, voteDocErr) in
                    var upvoted = false
                    var downvoted = false
                    if let voteDoc = voteDoc {
                        if voteDoc.exists{
                            let up = voteDoc.data()!["up"] as! Bool
                            upvoted = up
                            downvoted = !up
                        }
                    }
                    if self.postData[id] != nil {
                        let data:[String:Any] = [
                            "upvotes": upvotes,
                            "downvotes": downvotes,
                            "upvoted": upvoted,
                            "downvoted":downvoted
                        ]
                        self.updatePost(id: id, data: data, complete: { (post) in
                            if let dispatchGroup = self.postTasks[id], let group = dispatchGroup {
                                self.postTasks[id] = nil
                                group.leave()
                            }
                        })
                    }
                    else if let context = self.getContext(){
                        let post = Post(context: context)
                        post.color = color
                        post.desc = description
                        post.downvoted = downvoted
                        post.downvotes = Int32(downvotes)
                        post.id = id
                        post.nanoseconds = timestamp.nanoseconds
                        post.photoURL = photoURL
                        post.seconds = timestamp.seconds
                        post.uid = uid
                        post.upvoted = upvoted
                        post.upvotes = Int32(upvotes)
                        self.postData[id] = post
                        self.updateCore()
                        if let dispatchGroup = self.postTasks[id], let group = dispatchGroup {
                            self.postTasks[id] = nil
                            group.leave()
                        }
                    }
                    else{
                        if let dispatchGroup = self.postTasks[id], let group = dispatchGroup {
                            self.postTasks[id] = nil
                            group.leave()
                        }
                    }
                })
            }
            else{
                if let dispatchGroup = self.postTasks[id], let group = dispatchGroup {
                    self.postTasks[id] = nil
                    group.leave()
                }
            }
        }
        else{
            if let dispatchGroup = self.postTasks[id], let group = dispatchGroup {
                self.postTasks[id] = nil
                group.leave()
            }
        }
    }
    
    private func updateCore() {
        if let context = getContext() {
            do{
                try context.save()
            }
            catch {
                print("could not save")
            }
        }
    }
    
    private func getContext() -> NSManagedObjectContext? {
        if Thread.isMainThread {
            return appDelegate?.persistentContainer.viewContext
        }
        else {
            return DispatchQueue.main.sync() {
                return appDelegate?.persistentContainer.viewContext
            }
        }
    }
    
}
