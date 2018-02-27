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


class Comment {

    static let typeKey = "Comment"
    static let textKey = "text"
    static let postKey = "post"
    static let timestampKey = "timestamp"
    
    init(post: Post?, text: String, timestamp: Date = Date()) {
        self.text = text
        self.timestamp = timestamp
        self.post = post
    }
    
    convenience required init?(record: CKRecord) {
        
        guard let timestamp = record.creationDate,
            let text = record[Comment.textKey] as? String else {
                return nil
        }
        
        self.init(post: nil, text: text, timestamp: timestamp)
        cloudKitRecordID = record.recordID
    }
	
    var cloudKitRecord: CKRecord {
    
        guard let post = post else { fatalError("Comment does not have a Post relationship") }
        
        let postRecordID = post.cloudKitRecordID ?? post.cloudKitRecord.recordID
        let recordID = cloudKitRecordID ?? CKRecordID(recordName: UUID().uuidString)
        
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[Comment.timestampKey] = timestamp as CKRecordValue?
        record[Comment.textKey] = text as CKRecordValue?
        record[Comment.postKey] = CKReference(recordID: postRecordID, action: .deleteSelf)
        
        return record
    }

    let timestamp: Date
    let text: String
    var post: Post?
    
	var cloudKitRecordID: CKRecordID?
	var recordType: String { return Comment.typeKey }
}

// MARK: - SearchableRecord

extension Comment: SearchableRecord {
	func matches(searchTerm: String) -> Bool {
		return text.lowercased().contains(searchTerm.lowercased())
	}
}

