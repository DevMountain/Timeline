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


class Comment: CloudKitSyncable {

    static let typeKey = "Comment"
    static let textKey = "text"
    static let postKey = "post"
    static let timestampKey = "timestamp"
    
    init(post: Post?, text: String, timestamp: Date = Date()) {
        self.text = text
        self.timestamp = timestamp
        self.post = post
    }
	
	let timestamp: Date
	let text: String
	var post: Post?

	// MARK: CloudKitSyncable
	
	convenience required init?(record: CKRecord) {
		
		guard let timestamp = record.creationDate,
			let text = record[Comment.textKey] as? String else {
                return nil
        }
		
		self.init(post: nil, text: text, timestamp: timestamp)
		cloudKitRecordID = record.recordID
	}

	var cloudKitRecordID: CKRecordID?
	var recordType: String { return Comment.typeKey }
}

// MARK: -

extension Comment: SearchableRecord {
	func matches(searchTerm: String) -> Bool {
		return text.contains(searchTerm)
	}
}

// MARK: -

extension CKRecord {
	convenience init(_ comment: Comment) {
		guard let post = comment.post else { fatalError("Comment does not have a Post relationship") }
		let postRecordID = post.cloudKitRecordID ?? CKRecord(post).recordID
		let recordID = CKRecordID(recordName: UUID().uuidString)
		
		self.init(recordType: comment.recordType, recordID: recordID)
		
		self[Comment.timestampKey] = comment.timestamp as CKRecordValue?
		self[Comment.textKey] = comment.text as CKRecordValue?
		self[Comment.postKey] = CKReference(recordID: postRecordID, action: .deleteSelf)
	}
}
