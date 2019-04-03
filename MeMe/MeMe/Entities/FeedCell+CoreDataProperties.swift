//
//  FeedCell+CoreDataProperties.swift
//  MeMe
//
//  Created by Drew Dearing on 4/1/19.
//  Copyright © 2019 meme. All rights reserved.
//
//

import Foundation
import CoreData


extension FeedCell {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FeedCell> {
        return NSFetchRequest<FeedCell>(entityName: "FeedCell")
    }

    @NSManaged public var username: String
    @NSManaged public var desc: String
    @NSManaged public var uid: String
    @NSManaged public var post: String
    @NSManaged public var imageURL: String
    @NSManaged public var profilePicURL: String
    @NSManaged public var upvotes: Int32
    @NSManaged public var downvotes: Int32
    @NSManaged public var feed: Bool
    @NSManaged public var seconds: Int64
    
}
