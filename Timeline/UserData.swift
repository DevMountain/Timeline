//
//  UserData.swift
//  Timeline
//
//  Created by Caleb Hicks on 6/7/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData
import CloudKit


class UserData: SyncableObject, CloudKitManagedObject {

    private let displayNameKey = "displayName"
    private let profileImageKey = "profileImage"
    private let timestampKey = "timestamp"
    
    lazy var temporaryPhotoURL: NSURL = {
        
        // must write to temporary directory to be able to pass image url to CKAsset
        
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryDirectoryURL = NSURL(fileURLWithPath: temporaryDirectory)
        let fileURL = temporaryDirectoryURL.URLByAppendingPathComponent(NSUUID().UUIDString).URLByAppendingPathExtension("jpg")
        
        self.profileImageData?.writeToURL(fileURL, atomically: true)
        
        return fileURL
    }()
    
    // MARK: - CloudKitManagedObject
    
    var recordType: String = "UserData"
    
    var cloudKitRecord: CKRecord? {
        
        let recordID = CKRecordID(recordName: recordName)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        
        record[displayNameKey] = displayName
        record[profileImageKey] = CKAsset(fileURL: temporaryPhotoURL)
        record[timestampKey] = timestamp
        
        return record
    }
    
    convenience init?(record: CKRecord, context: NSManagedObjectContext = Stack.sharedStack.managedObjectContext) {
        
        guard let timestamp = record.creationDate,
            let displayName = record["displayName"] as? String,
            let photoData = record["profileImage"] as? CKAsset else { return nil }
        
        guard let entity = NSEntityDescription.entityForName("UserData", inManagedObjectContext: context) else { fatalError("Error: Core Data failed to create entity from entity description.") }
        
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.timestamp = timestamp
        self.displayName = displayName
        self.profileImageData = NSData(contentsOfURL: photoData.fileURL)
        self.recordIDData = NSKeyedArchiver.archivedDataWithRootObject(record.recordID)
        self.recordName = record.recordID.recordName
    }
}
