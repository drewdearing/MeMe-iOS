//
//  ChatMessage+CoreDataProperties.swift
//  MeMe
//
//  Created by Drew Dearing on 4/27/19.
//  Copyright © 2019 meme. All rights reserved.
//
//

import Foundation
import CoreData

extension ChatMessage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessage> {
        return NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
    }

    @NSManaged public var id: String
    @NSManaged public var group: String
    @NSManaged public var image: Bool
    @NSManaged public var content: String
    @NSManaged public var uid: String
    @NSManaged public var sent: NSDate
}
