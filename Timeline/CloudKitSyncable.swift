//
//  CloudKitSyncable.swift
//  Timeline
//
//  Created by Andrew Madsen on 8/1/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import CloudKit

protocol CloudKitSyncable {
	
	init?(record: CKRecord)

	var cloudKitRecordID: CKRecordID? { get set }
	var recordType: String { get }
}

extension CloudKitSyncable {
	var isSynced: Bool {
		return cloudKitRecordID != nil
	}
	
	var cloudKitReference: CKReference? {
		
		guard let recordID = cloudKitRecordID else { return nil }
		
		return CKReference(recordID: recordID, action: .None)
	}
}
