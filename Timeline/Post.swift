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
    
	init(photoData: Data?, timestamp: Date = Date(), comments: [Comment] = []) {
		self.timestamp = timestamp
        self.photoData = photoData
		self.comments = comments
    }
	
	let timestamp: Date
	let photoData: Data?
	var photo: UIImage? {
		guard let photoData = self.photoData else { return nil }
		return UIImage(data: photoData)
	}
	var comments: [Comment]

	// MARK: CloudKitSyncable
	
	convenience required init?(record: CKRecord) {
		
		guard let timestamp = record.creationDate,
			let photoAsset = record[Post.photoDataKey] as? CKAsset else { return nil }
		
		let photoData = try? Data(contentsOf: photoAsset.fileURL)
		self.init(photoData: photoData, timestamp: timestamp)
		cloudKitRecordID = record.recordID
	}
	
	fileprivate var temporaryPhotoURL: URL {
		
		// Must write to temporary directory to be able to pass image file path url to CKAsset
		
		let temporaryDirectory = NSTemporaryDirectory()
		let temporaryDirectoryURL = URL(fileURLWithPath: temporaryDirectory)
		let fileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
		
		try? photoData?.write(to: fileURL, options: [.atomic])
		
		return fileURL
	}

	var recordType: String { return Post.typeKey }
	var cloudKitRecordID: CKRecordID?
}

// MARK: -

extension Post: SearchableRecord {
	func matchesSearchTerm(_ searchTerm: String) -> Bool {
		let matchingComments = comments.filter { $0.matchesSearchTerm(searchTerm) }
		return !matchingComments.isEmpty
	}
}

// MARK: -

extension CKRecord {
	convenience init(_ post: Post) {
		let recordID = CKRecordID(recordName: UUID().uuidString)
		self.init(recordType: post.recordType, recordID: recordID)
		
		self[Post.timestampKey] = post.timestamp as CKRecordValue?
		self[Post.photoDataKey] = CKAsset(fileURL: post.temporaryPhotoURL)
	}
}
