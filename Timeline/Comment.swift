//
//  Comment.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/27/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData
import CloudKit


class Comment: NSManagedObject, CloudKitManagedObject {
    
//    @NSManaged var added: NSDate?
//    @NSManaged var text: String?
//    @NSManaged var recordData: NSData?
//    @NSManaged var recordName: String?
//    @NSManaged var post: Post?

    private let addedKey = "added"
    private let textKey = "text"
    private let postKey = "post"
    
    convenience init(post: Post, text: String, added: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let entity = NSEntityDescription.entityForName("Comment", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.post = post
        self.text = text
        self.added = added
        self.recordName = self.nameForManagedObject()
    }
    
    // MARK: - CloudKitManagedObject
    
    var recordType: String = "Comment"
    
    var cloudKitRecord: CKRecord? {
        
        if let recordData = recordData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(recordData) as? CKRecord
        } else {
            
            let recordID = CKRecordID(recordName: self.recordName)
            
            let record = CKRecord(recordType: recordType, recordID: recordID)
            record[addedKey] = added
            record[textKey] = text
            
            guard let post = post,
                let postRecord = post.cloudKitRecord else { fatalError("Post relation does not exist.") }
            
            let reference = CKReference(record: postRecord, action: .DeleteSelf)
            
            record[postKey] = reference
            
            return record
        }
    }
    
    convenience init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let added = record.creationDate,
            let text = record["text"] as? String,
            let reference = record["post"] as? CKReference else { return nil }
        
        guard let entity = NSEntityDescription.entityForName("Comment", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.added = added
        self.text = text
        self.recordData = NSKeyedArchiver.archivedDataWithRootObject(record)
        self.recordName = record.recordID.recordName
        
        if let post = PostController.sharedController.postWithName(reference.recordID.recordName) {
            
            self.post = post
        }
    }
    
    func updateWithRecord(record: CKRecord) {
        
        self.recordData = NSKeyedArchiver.archivedDataWithRootObject(record)
    }

}
