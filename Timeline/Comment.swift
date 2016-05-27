//
//  Comment.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/27/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData


class Comment: NSManagedObject {
    
//    @NSManaged var added: NSDate?
//    @NSManaged var text: String?
//    @NSManaged var post: Post?

    convenience init(post: Post, text: String, added: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let entity = NSEntityDescription.entityForName("Comment", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.post = post
        self.text = text
        self.added = added
    }

}
