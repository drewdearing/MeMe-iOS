//
//  Group+CoreDataProperties.swift
//  MeMe
//
//  Created by Gia Bao Than on 4/26/19.
//  Copyright © 2019 meme. All rights reserved.
//
//

import Foundation
import CoreData


extension Group {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Group> {
        return NSFetchRequest<Group>(entityName: "Group")
    }

    @NSManaged public var name: String
    @NSManaged public var id: String
    @NSManaged public var unreadMessages: Int32
    @NSManaged public var lastActive: NSDate
    @NSManaged public var numMembers: Int32
    @NSManaged public var active: Bool

}
