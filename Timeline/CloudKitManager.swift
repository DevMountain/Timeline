//
//  CloudKitManager.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/27/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

private let CreatorUserRecordIDKey = "creatorUserRecordID"
private let LastModifiedUserRecordIDKey = "creatorUserRecordID"
private let CreationDateKey = "creationDate"
private let ModificationDateKey = "modificationDate"

class CloudKitManager {
	
    static let shared = CloudKitManager()
    
	let publicDatabase = CKContainer.default().publicCloudDatabase
	let privateDatabase = CKContainer.default().privateCloudDatabase
	
	init() {
		checkCloudKitAvailability()
	}
	
	// MARK: - User Info Discovery
	
	func fetchLoggedInUserRecord(_ completion: ((_ record: CKRecord?, _ error: Error? ) -> Void)?) {
		
		CKContainer.default().fetchUserRecordID { (recordID, error) in
			
			if let error = error,
				let completion = completion {
				completion(nil, error)
			}
			
			if let recordID = recordID,
				let completion = completion {
                
				// Apple `Users` records can only exist on the Public Database
				self.fetchRecord(withID: recordID, database: self.publicDatabase, completion: completion)
			}
		}
	}
	
	func fetchUsername(for recordID: CKRecordID,
	                   completion: @escaping ((_ givenName: String?, _ familyName: String?) -> Void) = { _,_ in }) {
		
		let recordInfo = CKUserIdentityLookupInfo(userRecordID: recordID)
		let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [recordInfo])
		
		var userIdenties = [CKUserIdentity]()
		operation.userIdentityDiscoveredBlock = { (userIdentity, _) in
			userIdenties.append(userIdentity)
		}
		operation.discoverUserIdentitiesCompletionBlock = { (error) in
			if let error = error {
				NSLog("Error getting username from record ID: \(error)")
				completion(nil, nil)
				return
			}
			
			let nameComponents = userIdenties.first?.nameComponents
			completion(nameComponents?.givenName, nameComponents?.familyName)
		}
		
		CKContainer.default().add(operation)
	}
	
	func fetchAllDiscoverableUsers(completion: @escaping ((_ userInfoRecords: [CKUserIdentity]?) -> Void) = { _ in }) {
		
		let operation = CKDiscoverAllUserIdentitiesOperation()
		
		var userIdenties = [CKUserIdentity]()
		operation.userIdentityDiscoveredBlock = { userIdenties.append($0) }
		operation.discoverAllUserIdentitiesCompletionBlock = { error in
			if let error = error {
				NSLog("Error discovering all user identies: \(error)")
				completion(nil)
				return
			}
			
			completion(userIdenties)
		}
		
		CKContainer.default().add(operation)
	}
	
	
	// MARK: - Fetch Records
	
	func fetchRecord(withID recordID: CKRecordID, database: CKDatabase, completion: ((_ record: CKRecord?, _ error: Error?) -> Void)?) {
		
		database.fetch(withRecordID: recordID) { (record, error) in
			
			completion?(record, error)
		}
	}
	
	func fetchRecordsOfType(_ type: String,
	                          predicate: NSPredicate = NSPredicate(value: true),
                              database: CKDatabase,
	                          sortDescriptors: [NSSortDescriptor]? = nil,
	                          recordFetchedBlock: @escaping (_ record: CKRecord) -> Void = { _ in },
	                          completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)?) {
		
		var fetchedRecords: [CKRecord] = []
		
		let query = CKQuery(recordType: type, predicate: predicate)
        query.sortDescriptors = sortDescriptors
		let queryOperation = CKQueryOperation(query: query)
		
		let perRecordBlock = { (fetchedRecord: CKRecord) -> Void in
			fetchedRecords.append(fetchedRecord)
			recordFetchedBlock(fetchedRecord)
		}
		queryOperation.recordFetchedBlock = perRecordBlock
		
		var queryCompletionBlock: (CKQueryCursor?, Error?) -> Void = { (_, _) in }
		
		queryCompletionBlock = { (queryCursor: CKQueryCursor?, error: Error?) -> Void in
			
			if let queryCursor = queryCursor {
				// there are more results, go fetch them
				
				let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
				continuedQueryOperation.recordFetchedBlock = perRecordBlock
				continuedQueryOperation.queryCompletionBlock = queryCompletionBlock
				
				database.add(continuedQueryOperation)
				
			} else {
				completion?(fetchedRecords, error)
			}
		}
		queryOperation.queryCompletionBlock = queryCompletionBlock
		
		database.add(queryOperation)
	}
	
    func fetchCurrentUserRecords(_ type: String, database: CKDatabase, completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)?) {
		
		fetchLoggedInUserRecord { (record, error) in
			
			if let record = record {
				
				let predicate = NSPredicate(format: "%K == %@", argumentArray: [CreatorUserRecordIDKey, record.recordID])
				
                self.fetchRecordsOfType(type, predicate: predicate, database: database, completion: completion)
			}
		}
	}
	
    func fetchRecordsFromDateRange(_ type: String, database: CKDatabase, fromDate: Date, toDate: Date, completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)?) {
		
		let startDatePredicate = NSPredicate(format: "%K > %@", argumentArray: [CreationDateKey, fromDate])
		let endDatePredicate = NSPredicate(format: "%K < %@", argumentArray: [CreationDateKey, toDate])
		let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [startDatePredicate, endDatePredicate])
		
		
        self.fetchRecordsOfType(type, predicate: predicate, database: database) { (records, error) in
			
			completion?(records, error)
		}
	}
	
	
	// MARK: - Delete
	
    func deleteRecordWithID(_ recordID: CKRecordID, database: CKDatabase, completion: ((_ recordID: CKRecordID?, _ error: Error?) -> Void)?) {
		
		database.delete(withRecordID: recordID) { (recordID, error) in
			completion?(recordID, error)
		}
	}
	
	func deleteRecordsWithID(_ recordIDs: [CKRecordID], database: CKDatabase, completion: ((_ records: [CKRecord]?, _ recordIDs: [CKRecordID]?, _ error: Error?) -> Void)?) {
		
		let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
		operation.savePolicy = .ifServerRecordUnchanged
		
		operation.modifyRecordsCompletionBlock = completion
		
		database.add(operation)
	}
	
	
	// MARK: - Save and Modify
	
    func saveRecords(_ records: [CKRecord], database: CKDatabase, perRecordCompletion: ((_ record: CKRecord?, _ error: Error?) -> Void)?, completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)?) {
		
        modifyRecords(records, database: database, perRecordCompletion: perRecordCompletion, completion: completion)
	}
	
    func saveRecord(_ record: CKRecord, database: CKDatabase, completion: ((_ record: CKRecord?, _ error: Error?) -> Void)?) {
		
		modifyRecords([record], database: database, perRecordCompletion: completion, completion: nil)
	}
	
    func modifyRecords(_ records: [CKRecord], database: CKDatabase, perRecordCompletion: ((_ record: CKRecord?, _ error: Error?) -> Void)?, completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)?) {
		
		let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
		operation.savePolicy = .changedKeys
		operation.queuePriority = .high
		operation.qualityOfService = .userInteractive
		
		operation.perRecordCompletionBlock = perRecordCompletion
		
		operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) -> Void in
			completion?(records, error)
		}
		
		database.add(operation)
	}
	
	
	// MARK: - Subscriptions
	
	func subscribe(_ type: String,
	               predicate: NSPredicate,
                   database: CKDatabase,
	               subscriptionID: String,
	               contentAvailable: Bool,
	               alertBody: String? = nil,
	               desiredKeys: [String]? = nil,
	               options: CKQuerySubscriptionOptions,
	               completion: ((_ subscription: CKSubscription?, _ error: Error?) -> Void)?) {
		
		let subscription = CKQuerySubscription(recordType: type, predicate: predicate, subscriptionID: subscriptionID, options: options)
		
		let notificationInfo = CKNotificationInfo()
		notificationInfo.alertBody = alertBody
		notificationInfo.shouldSendContentAvailable = contentAvailable
		notificationInfo.desiredKeys = desiredKeys
		
		subscription.notificationInfo = notificationInfo
		
		database.save(subscription, completionHandler: { (subscription, error) in
			
			completion?(subscription, error)
		})
	}
	
	func unsubscribe(_ subscriptionID: String, database: CKDatabase, completion: ((_ subscriptionID: String?, _ error: Error?) -> Void)?) {
		
		database.delete(withSubscriptionID: subscriptionID) { (subscriptionID, error) in
			
			completion?(subscriptionID, error)
		}
	}
	
	func fetchSubscriptions(database: CKDatabase, completion: ((_ subscriptions: [CKSubscription]?, _ error: Error?) -> Void)?) {
		
		database.fetchAllSubscriptions { (subscriptions, error) in
			
			completion?(subscriptions, error)
		}
	}
	
	func fetchSubscription(_ subscriptionID: String, database: CKDatabase, completion: ((_ subscription: CKSubscription?, _ error: Error?) -> Void)?) {
		
		database.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
			
			completion?(subscription, error)
		}
	}
	
	
	// MARK: - CloudKit Permissions
	
	func checkCloudKitAvailability() {
		
		CKContainer.default().accountStatus() {
			(accountStatus:CKAccountStatus, error:Error?) -> Void in
			
			switch accountStatus {
			case .available:
				print("CloudKit available. Initializing full sync.")
				return
			default:
				self.handleCloudKitUnavailable(accountStatus, error: error)
			}
		}
	}
	
	func handleCloudKitUnavailable(_ accountStatus: CKAccountStatus, error:Error?) {
		
		var errorText = "Synchronization is disabled\n"
		if let error = error {
			print("handleCloudKitUnavailable ERROR: \(error)")
			print("An error occured: \(error.localizedDescription)")
			errorText += error.localizedDescription
		}
		
		switch accountStatus {
		case .restricted:
			errorText += "iCloud is not available due to restrictions"
		case .noAccount:
			errorText += "There is no CloudKit account setup.\nYou can setup iCloud in the Settings app."
		default:
			break
		}
		
		displayCloudKitNotAvailableError(errorText)
	}
	
	func displayCloudKitNotAvailableError(_ errorText: String) {
		
		DispatchQueue.main.async(execute: {
			
			let alertController = UIAlertController(title: "iCloud Synchronization Error", message: errorText, preferredStyle: .alert)
			
			let dismissAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil);
			
			alertController.addAction(dismissAction)
			
			if let appDelegate = UIApplication.shared.delegate,
				let appWindow = appDelegate.window!,
				let rootViewController = appWindow.rootViewController {
				rootViewController.present(alertController, animated: true, completion: nil)
			}
		})
	}
	
	
	// MARK: - CloudKit Discoverability
	
	func requestDiscoverabilityPermission() {
		
		CKContainer.default().status(forApplicationPermission: .userDiscoverability) { (permissionStatus, error) in
			
			if permissionStatus == .initialState {
				CKContainer.default().requestApplicationPermission(.userDiscoverability, completionHandler: { (permissionStatus, error) in
					
					self.handleCloudKitPermissionStatus(permissionStatus, error: error)
				})
			} else {
				
				self.handleCloudKitPermissionStatus(permissionStatus, error: error)
			}
		}
	}
	
	func handleCloudKitPermissionStatus(_ permissionStatus: CKApplicationPermissionStatus, error:Error?) {
		
		if permissionStatus == .granted {
			print("User Discoverability permission granted. User may proceed with full access.")
		} else {
			var errorText = "Synchronization is disabled\n"
			if let error = error {
				print("handleCloudKitUnavailable ERROR: \(error)")
				print("An error occured: \(error.localizedDescription)")
				errorText += error.localizedDescription
			}
			
			switch permissionStatus {
			case .denied:
				errorText += "You have denied User Discoverability permissions. You may be unable to use certain features that require User Discoverability."
			case .couldNotComplete:
				errorText += "Unable to verify User Discoverability permissions. You may have a connectivity issue. Please try again."
			default:
				break
			}
			
			displayCloudKitPermissionsNotGrantedError(errorText)
		}
	}
	
	func displayCloudKitPermissionsNotGrantedError(_ errorText: String) {
		
		DispatchQueue.main.async(execute: {
			
			let alertController = UIAlertController(title: "CloudKit Permissions Error", message: errorText, preferredStyle: .alert)
			
			let dismissAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil);
			
			alertController.addAction(dismissAction)
			
			if let appDelegate = UIApplication.shared.delegate,
				let appWindow = appDelegate.window!,
				let rootViewController = appWindow.rootViewController {
				rootViewController.present(alertController, animated: true, completion: nil)
			}
		})
	}
}
