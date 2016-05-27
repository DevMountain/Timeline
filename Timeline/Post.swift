//
//  Post.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/27/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class Post: NSManagedObject {

//    @NSManaged var added: NSDate?
//    @NSManaged var photoData: NSData?
//    @NSManaged var comments: NSOrderedSet?

    convenience init(photo: NSData, caption: String, added: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let entity = NSEntityDescription.entityForName("Post", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoData = photo
        self.added = added
        
        if !caption.isEmpty {
            
            let comment = Comment(post: self, text: caption)
            comment.post = self
        }
    }
    
    var photo: UIImage? {
        
        guard let photoData = self.photoData else { return nil }
        
        return UIImage(data: photoData)
    }
    
    var hashtags: [String] {
        
        if let comments = self.comments?.array as? [Comment] {
            
            return comments.flatMap({$0.text}).joinWithSeparator(" ").componentsSeparatedByString(" ").filter({$0.characters.first == "#"})
        } else {
            return []
        }
    }
}

extension Post: SearchableRecord {
    
    func matchesSearchTerm(searchTerm: String) -> Bool {

        if let comments = self.comments?.array as? [Comment] {
            
            return comments.flatMap({ $0.text }).filter({ $0.containsString(searchTerm) }).count > 0
        } else {
            return false
        }
    }
}
