//
//  Post+CoreDataProperties.swift
//  MeMe
//
//  Created by Drew Dearing on 4/23/19.
//  Copyright © 2019 meme. All rights reserved.
//
//

import Foundation
import CoreData

extension Post {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Post> {
        return NSFetchRequest<Post>(entityName: "Post")
    }

    @NSManaged public var desc: String
    @NSManaged public var downvoted: Bool
    @NSManaged public var downvotes: Int32
    @NSManaged public var photoURL: String
    @NSManaged public var id: String
    @NSManaged public var seconds: Int64
    @NSManaged public var uid: String
    @NSManaged public var upvoted: Bool
    @NSManaged public var upvotes: Int32
    @NSManaged public var color: String
    @NSManaged public var nanoseconds: Int32

}
