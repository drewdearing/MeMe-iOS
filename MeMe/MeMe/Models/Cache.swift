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
    private var groupData:[String:Group] = [:]
    private var messageData:[String:[String:ChatMessage]] = [:]
    
    private var imageTasks:[String:DispatchGroup?] = [:]
    private var profileTasks:[String:DispatchGroup?] = [:]
    private var postTasks:[String:DispatchGroup?] = [:]
    private var groupTasks:[String:DispatchGroup?] = [:]
    private var messageTasks:[String:[String:DispatchGroup?]?] = [:]
    
    private var postListeners:[String:ListenerRegistration?] = [:]
    private var profileListeners:[String:ListenerRegistration?] = [:]
    private var groupListeners:[String:ListenerRegistration?] = [:]
    private var chatListeners:[String:ListenerRegistration?] = [:]
    
    private var groupUpdateListeners:[String:[(Group?) -> Void]?] = [:]
    
    private static var cache:Cache? = nil
    
    private init(){
        print("starting cache")
        if let context = getContext() {
            let postRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
            let profileRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Profile")
            let groupRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Group")
            let messageRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatMessage")
            do{
                let posts = try context.fetch(postRequest) as! [Post]
                let profiles = try context.fetch(profileRequest) as! [Profile]
                let groups = try context.fetch(groupRequest) as! [Group]
                let messages = try context.fetch(messageRequest) as! [ChatMessage]
                for post in posts {
                    postData[post.id] = post
                    let postRef = Firestore.firestore().collection("post").document(post.id)
                    postListeners[post.id] = postRef.addSnapshotListener { (postDoc, postDocErr) in
                        self.handlePostDoc(postDoc: postDoc)
                    }
                }
                for profile in profiles {
                    profileData[profile.id] = profile
                    let profileRef = Firestore.firestore().collection("users").document(profile.id)
                    profileListeners[profile.id] = profileRef.addSnapshotListener { (profileDoc, profileDocErr) in
                        self.handleProfileDoc(profileDoc: profileDoc)
                    }
                }
                for message in messages {
                    self.addMessageToData(message: message)
                }
                for group in groups {
                    groupData[group.id] = group
                    let groupRef = Firestore.firestore().collection("groups").document(group.id)
                    let messageRef = groupRef.collection("messages")
                    groupListeners[group.id] = groupRef.addSnapshotListener { (groupDoc, groupDocErr) in
                        self.handleGroupDoc(groupDoc: groupDoc)
                    }
                    chatListeners[group.id] = messageRef.addSnapshotListener { (query, error) in
                        if let query = query {
                            query.documentChanges.forEach { change in
                                if change.type == .added {
                                    self.handleMessageDoc(messageDoc: change.document)
                                }
                            }
                        }
                    }
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
                        complete(self.postData[id])
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
                        complete(self.postData[id])
                    }
                }
            }
        }
    }
    
    func getGroup(id: String, complete: @escaping (Group?) -> Void) {
        if let group = groupData[id] {
            complete(group)
        }
        else {
            if let dispatchGroup = groupTasks[id], let group = dispatchGroup {
                DispatchQueue.global(qos: .background).async {
                    group.wait()
                    DispatchQueue.main.async {
                        complete(self.groupData[id])
                    }
                }
            }
            else{
                let group = DispatchGroup()
                groupTasks[id] = group
                group.enter()
                let groupRef = Firestore.firestore().collection("groups").document(id)
                let messageRef = groupRef.collection("messages")
                groupListeners[id] = groupRef.addSnapshotListener { (groupDoc, groupDocErr) in
                    self.handleGroupDoc(groupDoc: groupDoc)
                }
                DispatchQueue.global(qos: .background).async {
                    group.wait()
                    self.chatListeners[id] = messageRef.addSnapshotListener { (query, error) in
                        if let query = query {
                            query.documentChanges.forEach { change in
                                if change.type == .added {
                                    self.handleMessageDoc(messageDoc: change.document)
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        complete(self.groupData[id])
                    }
                }
            }
        }
    }
    
    func getChatMessage(groupId:String, id:String, complete: @escaping (ChatMessage?) -> Void){
        if let groupMessages = self.messageData[groupId], let message = groupMessages[id] {
            complete(message)
        }
        else{
            if let messageTasks = self.messageTasks[groupId], let tasks = messageTasks {
                if let dispatchGroup = tasks[id], let group = dispatchGroup {
                    DispatchQueue.global(qos: .background).async {
                        group.wait()
                        DispatchQueue.main.async {
                            if let groupMessages = self.messageData[groupId], let message = groupMessages[id] {
                                complete(message)
                            }
                            else{
                                complete(nil)
                            }
                        }
                    }
                }
            }
            else{
                let group = DispatchGroup()
                if let messageTasks = self.messageTasks[groupId], var tasks = messageTasks {
                    tasks[id] = group
                }
                else{
                    var tasks:[String:DispatchGroup?] = [:]
                    tasks[id] = group
                    self.messageTasks[groupId] = tasks
                }
                group.enter()
                let messageRef = Firestore.firestore().collection("groups").document(groupId).collection("messages").document(id)
                messageRef.getDocument { (messageDoc, error) in
                    self.handleMessageDoc(messageDoc: messageDoc)
                }
                DispatchQueue.global(qos: .background).async {
                    group.wait()
                    DispatchQueue.main.async {
                        if let groupMessages = self.messageData[groupId], let message = groupMessages[id] {
                            complete(message)
                        }
                        else{
                            complete(nil)
                        }
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
                        complete(self.imageData[imageURL])
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
                        complete(self.profileData[uid])
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
                        complete(self.profileData[uid])
                    }
                }
            }
        }
    }
    
    func addGroupUpdateListener(id:String, listener: @escaping (Group?) -> Void){
        if let groupListeners = groupUpdateListeners[id], var listeners = groupListeners {
            listeners.append(listener)
        }
        else{
            let groupListeners:[(Group?) -> Void] = [listener]
            groupUpdateListeners[id] = groupListeners
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
    
    func updateGroup(id: String, data:[String:Any], complete: @escaping (Group?) -> Void){
        let name = data["name"] as! String
        let numMembers = data["numMembers"] as! Int32
        let lastActive = data["lastActive"] as! NSDate
        let active = data["active"] as! Bool
        let unreadMessages = data["unreadMessages"] as! Int32
        if let group = groupData[id] {
            group.name = name
            group.numMembers = numMembers
            group.lastActive = lastActive
            group.active = active
            group.unreadMessages = unreadMessages
            updateCore()
            callGroupUpdateListeners(id: id, group: group)
            complete(group)
        }
        else {
            getGroup(id: id, complete: complete)
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
    
    private func callGroupUpdateListeners(id:String, group:Group?){
        if let groupListeners = self.groupUpdateListeners[id], let listeners = groupListeners {
            for listener in listeners {
                listener(group)
            }
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
    
    private func handleMessageDoc(messageDoc: DocumentSnapshot?) {
        let id = messageDoc!.documentID
        let groupID = messageDoc!.reference.parent.parent!.documentID
        if let messageDoc = messageDoc {
            if messageDoc.exists {
                let data = messageDoc.data()!
                let content = data["content"] as! String
                let image = data["image"] as! Bool
                let sent = data["sent"] as! Firebase.Timestamp
                let uid = data["uid"] as! String
                getGroup(id: groupID) { (group) in
                    if let group = group, !group.active {
                        let lastActive = group.lastActive as Date
                        let currentUID = Auth.auth().currentUser!.uid
                        if lastActive < sent.dateValue() && currentUID != uid {
                            let data:[String:Any] = [
                                "name": group.name,
                                "numMembers": group.numMembers,
                                "lastActive": group.lastActive,
                                "unreadMessages": group.unreadMessages + 1,
                                "active": group.active
                            ]
                            self.updateGroup(id: groupID, data: data, complete: {_ in })
                        }
                    }
                }
                if let context = self.getContext(), self.messageData[id] == nil {
                    let message = ChatMessage(context: context)
                    message.id = id
                    message.content = content
                    message.group = groupID
                    message.image = image
                    message.sent = sent.dateValue() as NSDate
                    message.uid = uid
                    self.addMessageToData(message: message)
                    self.updateCore()
                    if let messageTasks = self.messageTasks[groupID], let tasks = messageTasks {
                        if let dispatchGroup = tasks[id], let group = dispatchGroup {
                            self.messageTasks[id] = nil
                            group.leave()
                        }
                    }
                }
                else{
                    if let messageTasks = self.messageTasks[groupID], let tasks = messageTasks {
                        if let dispatchGroup = tasks[id], let group = dispatchGroup {
                            self.messageTasks[id] = nil
                            group.leave()
                        }
                    }
                }
            }
            else{
                if let messageTasks = self.messageTasks[groupID], let tasks = messageTasks {
                    if let dispatchGroup = tasks[id], let group = dispatchGroup {
                        self.messageTasks[id] = nil
                        group.leave()
                    }
                }
            }
        }
        else{
            if let messageTasks = self.messageTasks[groupID], let tasks = messageTasks {
                if let dispatchGroup = tasks[id], let group = dispatchGroup {
                    self.messageTasks[id] = nil
                    group.leave()
                }
            }
        }
    }
    
    private func addMessageToData(message:ChatMessage){
        if var groupMessages = messageData[message.group] {
            groupMessages[message.id] = message
        }
        else{
            var groupMessages:[String:ChatMessage] = [:]
            groupMessages[message.id] = message
            messageData[message.group] = groupMessages
        }
    }
    
    private func handleGroupDoc(groupDoc: DocumentSnapshot?) {
        let id = groupDoc!.documentID
        if let groupDoc = groupDoc {
            if groupDoc.exists {
                let currentUser = Auth.auth().currentUser!
                let data = groupDoc.data()!
                let name = data["name"] as! String
                let numMembers = data["numMembers"] as! Int32
                let userRef = groupDoc.reference.collection("usersInGroup").document(currentUser.uid)
                userRef.getDocument(completion:  { (userDoc, error) in
                    var lastActive = Date()
                    if let userDoc = userDoc {
                        if userDoc.exists {
                            let userActive = userDoc.data()!["lastActive"] as! Firebase.Timestamp
                            lastActive = userActive.dateValue()
                        }
                    }
                    if self.groupData[id] != nil {
                        let data:[String:Any] = [
                            "name": name,
                            "numMembers": numMembers,
                            "lastActive": lastActive,
                            "unreadMessages": Int32(0),
                            "active": false
                        ]
                        self.updateGroup(id: id, data: data, complete: { (userGroup) in
                            if let dispatchGroup = self.groupTasks[id], let group = dispatchGroup {
                                self.groupTasks[id] = nil
                                group.leave()
                            }
                        })
                    }
                    else if let context = self.getContext(){
                        let group = Group(context: context)
                        group.id = id
                        group.active = false
                        group.name = name
                        group.numMembers = numMembers
                        group.unreadMessages = Int32(0)
                        group.lastActive = lastActive as NSDate
                        self.groupData[id] = group
                        self.updateCore()
                        if let dispatchGroup = self.groupTasks[id], let g = dispatchGroup {
                            self.groupTasks[id] = nil
                            g.leave()
                        }
                    }
                    else{
                        if let dispatchGroup = self.groupTasks[id], let g = dispatchGroup {
                            self.groupTasks[id] = nil
                            g.leave()
                        }
                    }
                })
            }
            else{
                if let dispatchGroup = self.groupTasks[id], let g = dispatchGroup {
                    self.groupTasks[id] = nil
                    g.leave()
                }
            }
        }
        else{
            if let dispatchGroup = self.groupTasks[id], let g = dispatchGroup {
                self.groupTasks[id] = nil
                g.leave()
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
