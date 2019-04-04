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

class Cache {
    private var postData:[String:FeedCell] = [:]
    private var imageData:[String:UIImage] = [:]
    private var profilePicData:[String:UIImage] = [:]
    private static var cache:Cache? = nil
    
    private init(){
        print("starting cache")
        if let context = getContext() {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FeedCell")
            do{
                let posts = try context.fetch(request) as! [FeedCell]
                for post in posts {
                    postData[post.post] = post
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
    
    func getPost(id:String) -> FeedCell? {
        if let post = postData[id] {
            return post
        }
        return nil
    }
    
    func getImage(id:String) -> UIImage? {
        if let image = imageData[id] {
            return image
        }
        return nil
    }
    
    func getProfilePic(uid:String) -> UIImage? {
        if let profilePic = profilePicData[uid] {
            return profilePic
        }
        return nil
    }
    
    func addPosts(data:[FeedCellData], feed:Bool) -> [FeedCell] {
        var cells:[FeedCell] = []
        for post in data{
            if let cell = addPost(data: post, feed: feed){
                cells.append(cell)
            }
        }
        return cells
    }
    
    func addPost(data:FeedCellData, feed:Bool) -> FeedCell? {
        if let post = postData[data.post] {
            var dirty = false
            if post.downvotes != data.downvotes {
                post.downvotes = Int32(data.downvotes)
                dirty = true
            }
            if post.upvotes != data.upvotes {
                post.upvotes = Int32(data.upvotes)
                dirty = true
            }
            if post.username != data.username {
                post.username = data.username
                dirty = true
            }
            if post.profilePicURL != data.profilePicURL {
                post.profilePicURL = data.profilePicURL
                profilePicData[post.post] = nil
                dirty = true
            }
            if dirty {
                updateCore()
            }
            return post
        }
        else if let cell = cellFromData(post: data, feed: feed) {
            postData[cell.post] = cell
            updateCore()
            return cell
        }
        return nil
    }
    
    func getPosts(feed:Bool) -> [FeedCell]{
        if feed {
            return Array(postData.filter{ $0.value.feed }.values)
        }
        return Array(postData.values)
    }
    
    func addImage(id:String, image:UIImage?){
        if let i = image {
            imageData[id] = i
        }
    }
    
    func addProfilePic(id:String, image:UIImage?){
        if let i = image {
            profilePicData[id] = i
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
    
    private func cellFromData(post: FeedCellData, feed:Bool) -> FeedCell? {
        if let context = getContext() {
            let newCell = FeedCell(context: context)
            newCell.desc = post.description
            newCell.downvotes = Int32(post.downvotes)
            newCell.imageURL = post.imageURL
            newCell.post = post.post
            newCell.profilePicURL = post.profilePicURL
            newCell.uid = post.uid
            newCell.upvotes = Int32(post.upvotes)
            newCell.username = post.username
            newCell.feed = feed
            newCell.seconds = Int64(post.timestamp._seconds)
            return newCell
        }
        return nil
    }
    
}
