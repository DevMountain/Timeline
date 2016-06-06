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


class Comment: NSManagedObject, SearchableRecord, CloudKitManagedObject {
    
//    @NSManaged var timestamp: NSDate?
//    @NSManaged var text: String?
//    @NSManaged var recordIDData: NSData?
//    @NSManaged var recordName: String?
//    @NSManaged var post: Post?

    private let textKey = "text"
    private let timestampKey = "timestamp"
    private let postKey = "post"
    
    convenience init(post: Post, text: String, timestamp: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let entity = NSEntityDescription.entityForName("Comment", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.text = text
        self.timestamp = timestamp
        self.post = post
        self.recordName = nameForManagedObject()
    }
    
    // MARK: - SearchableRecord
    
    func matchesSearchTerm(searchTerm: String) -> Bool {
        
        return text?.containsString(searchTerm) ?? false
    }
    
    // MARK: - CloudKitManagedObject
    
    var recordType: String = "Comment"
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[timestampKey] = timestamp
        record[textKey] = text
        
        guard let post = post,
            let postRecord = post.cloudKitRecord else { fatalError("Comment does not have a Post relationship") }
        
        record[postKey] = CKReference(record: postRecord, action: .DeleteSelf)
        
        return record
    }
    
    convenience init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let timestamp = record.creationDate,
            let text = record["text"] as? String,
            let postReference = record["post"] as? CKReference else { return nil }
        
        guard let entity = NSEntityDescription.entityForName("Comment", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.timestamp = timestamp
        self.text = text
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        self.recordName = record.recordID.recordName
        
        self.post = PostController.sharedController.postWithName(postReference.recordID.recordName)
    }
    
    func updateWithRecord(record: CKRecord) {
        
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
    }
}
