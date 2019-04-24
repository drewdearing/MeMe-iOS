//
//  Profile+CoreDataProperties.swift
//  MeMe
//
//  Created by Drew Dearing on 4/23/19.
//  Copyright © 2019 meme. All rights reserved.
//
//

import Foundation
import CoreData


extension Profile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }

    @NSManaged public var numFollowers: Int32
    @NSManaged public var numFollowing: Int32
    @NSManaged public var profilePicURL: String
    @NSManaged public var username: String
    @NSManaged public var following: Bool
    @NSManaged public var id: String
    
}
