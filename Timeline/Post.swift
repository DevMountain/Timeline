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


class Post: CloudKitSyncable {
    
    static let typeKey = "Post"
    static let photoDataKey = "photoData"
    static let timestampKey = "timestamp"
    
	init(photoData: NSData?, timestamp: NSDate = NSDate(), comments: [Comment] = []) {
		self.timestamp = timestamp
        self.photoData = photoData
		self.comments = comments
    }
	
	let timestamp: NSDate
	let photoData: NSData?
	var photo: UIImage? {
		guard let photoData = self.photoData else { return nil }
		return UIImage(data: photoData)
	}
	var comments: [Comment]

	// MARK: CloudKitSyncable
	
	convenience required init?(record: CKRecord) {
		
		guard let timestamp = record.creationDate,
			photoAsset = record[Post.photoDataKey] as? CKAsset else { return nil }
		
		let photoData = NSData(contentsOfURL: photoAsset.fileURL)
		self.init(photoData: photoData, timestamp: timestamp)
	}
	
	private var temporaryPhotoURL: NSURL {
		
		// Must write to temporary directory to be able to pass image file path url to CKAsset
		
		let temporaryDirectory = NSTemporaryDirectory()
		let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
		let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(NSUUID().UUIDString).URLByAppendingPathExtension("jpg")
		
		photoData?.writeToURL(fileURL, atomically: true)
		
		return fileURL
	}

	var recordType: String { return Post.typeKey }
	var cloudKitRecordID: CKRecordID?
}

// MARK: -

extension Post: SearchableRecord {
	func matchesSearchTerm(searchTerm: String) -> Bool {
		let matchingComments = comments.filter { $0.matchesSearchTerm(searchTerm) }
		return !matchingComments.isEmpty
	}
}

// MARK: -

extension CKRecord {
	convenience init(_ post: Post) {
		let recordID = CKRecordID(recordName: NSUUID().UUIDString)
		self.init(recordType: post.recordType, recordID: recordID)
		
		self[Post.timestampKey] = post.timestamp
		self[Post.photoDataKey] = CKAsset(fileURL: post.temporaryPhotoURL)
	}
}
