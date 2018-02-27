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


class Post {
    
    static let typeKey = "Post"
    static let photoDataKey = "photoData"
    static let timestampKey = "timestamp"
    
    init(photoData: Data?, timestamp: Date = Date(), comments: [Comment] = []) {
        self.timestamp = timestamp
        self.photoData = photoData
        self.comments = comments
    }
    
    convenience required init?(record: CKRecord) {
        
        guard let timestamp = record.creationDate,
            let photoAsset = record[Post.photoDataKey] as? CKAsset else { return nil }
        
        let photoData = try? Data(contentsOf: photoAsset.fileURL)
        self.init(photoData: photoData, timestamp: timestamp)
        cloudKitRecordID = record.recordID
    }
    
    var cloudKitRecord: CKRecord {
        let recordID = cloudKitRecordID ?? CKRecordID(recordName: UUID().uuidString)
        
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[Post.timestampKey] = timestamp as CKRecordValue?
        record[Post.photoDataKey] = CKAsset(fileURL: temporaryPhotoURL)
        
        return record
    }
    
    
    fileprivate var temporaryPhotoURL: URL {
        
        // Must write to temporary directory to be able to pass image file path url to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryDirectoryURL = URL(fileURLWithPath: temporaryDirectory)
        let fileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        
        try? photoData?.write(to: fileURL, options: [.atomic])
        
        return fileURL
    }
    
    let timestamp: Date
    let photoData: Data?
    
    var comments: [Comment] {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: PostController.PostCommentsChangedNotification, object: self)
            }
        }
    }
    
    var photo: UIImage? {
        guard let photoData = self.photoData else { return nil }
        return UIImage(data: photoData)
    }
    
    var recordType: String { return Post.typeKey }
    var cloudKitRecordID: CKRecordID?
}

// MARK: - SearchableRecord

extension Post: SearchableRecord {
    func matches(searchTerm: String) -> Bool {
        let matchingComments = comments.filter { $0.matches(searchTerm: searchTerm) }
        return !matchingComments.isEmpty
    }
}
