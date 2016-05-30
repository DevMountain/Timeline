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
import CloudKit


class Post: NSManagedObject, CloudKitManagedObject {

//    @NSManaged var added: NSDate?
//    @NSManaged var photoData: NSData?
//    @NSManaged var recordData: NSData?
//    @NSManaged var comments: NSOrderedSet?
    
    private let addedKey = "added"
    private let photoDataKey = "photoData"
    
    convenience init(photo: NSData, caption: String, added: NSDate = NSDate(), context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let entity = NSEntityDescription.entityForName("Post", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.photoData = photo
        self.added = added
        self.recordName = self.nameForManagedObject()
        
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
    
    lazy var temporaryPhotoURL: NSURL = {
        
        // must write to temporary directory to be able to pass image url to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(NSUUID().UUIDString).URLByAppendingPathExtension("jpg")
        
        self.photoData?.writeToURL(fileURL, atomically: true)
        
        return fileURL
    }()
    
    // MARK: - CloudKitManagedObject
    
    var recordType: String = "Post"
    
    var cloudKitRecord: CKRecord? {
        
        if let recordData = recordData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(recordData) as? CKRecord
        } else {
            
            let recordID = CKRecordID(recordName: self.recordName)
            
            let record = CKRecord(recordType: recordType, recordID: recordID)
            record[addedKey] = added
            record[photoDataKey] = CKAsset(fileURL: self.temporaryPhotoURL)
            
            return record
        }
    }
    
    convenience init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let added = record.creationDate,
            let photoData = record["photoData"] as? CKAsset else { return nil }
        
        guard let entity = NSEntityDescription.entityForName("Post", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)

        self.added = added
        self.photoData = NSData(contentsOfURL: photoData.fileURL)
        self.recordData = NSKeyedArchiver.archivedDataWithRootObject(record)
        self.recordName = record.recordID.recordName
    }
    
    func updateWithRecord(record: CKRecord) {
        
        guard let added = record.creationDate,
            let photoData = record[photoDataKey] as? CKAsset else { fatalError("Unable to update CloudKitManagedObject \(self.cloudKitRecordName) with CKRecord") }
        
        self.added = added
        self.photoData = NSData(contentsOfURL: photoData.fileURL)
        self.recordData = NSKeyedArchiver.archivedDataWithRootObject(record)
        self.recordName = record.recordID.recordName
    }
}

extension Post: SearchableRecord {
    
    func matchesSearchTerm(searchTerm: String) -> Bool {

        if let comments = self.comments?.array as? [Comment] {
            
            let matchingCommentTerms = comments.flatMap({ $0.text?.lowercaseString }).filter({ $0.containsString(searchTerm) })
            
            return matchingCommentTerms.count > 0
        } else {
            return false
        }
    }
}
