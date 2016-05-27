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
//    @NSManaged var caption: String?
//    @NSManaged var photoData: NSData?
//    @NSManaged var comments: NSOrderedSet?

    convenience init(photo: NSData, caption: String, added: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let entity = NSEntityDescription.entityForName("Post", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoData = photo
        self.caption = caption
        self.added = added
    }
    
    var photo: UIImage? {
        
        guard let photoData = self.photoData else { return nil }
        
        return UIImage(data: photoData)
    }
    

}
