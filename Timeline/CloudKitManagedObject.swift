//
//  CloudKitManagedObject.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/28/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

@objc protocol CloudKitRecordIDObject {
    
    var recordID: NSData? { get set }
}

extension CloudKitRecordIDObject {
    
    func cloudKitRecordID() -> CKRecordID? {
        
        guard let recordID = recordID else { return nil }
        
        return NSKeyedUnarchiver.unarchiveObjectWithData(recordID) as? CKRecordID
    }
}

@objc protocol CloudKitManagedObject: CloudKitRecordIDObject {
    
    var added: NSDate? { get set }
    var lastUpdate: NSDate? { get set }
    var recordName: String? { get set }
    var recordType: String { get }
    func managedObjectToRecord(record: CKRecord?) -> CKRecord
    func updateWithRecord(record: CKRecord)
}

extension CloudKitManagedObject {
    
    func cloudKitRecord(record: CKRecord?) -> CKRecord {
        
        if let record = record {
            return record
        }
        
        let uuid = NSUUID()
        let recordName = recordType + "." + uuid.UUIDString
        let recordID = CKRecordID(recordName: recordName)
        
        return CKRecord(recordType: recordType, recordID: recordID)
    }
}