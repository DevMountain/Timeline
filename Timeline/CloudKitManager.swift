//
//  CloudKitManager.swift
//  CloudKitManager
//
//  Created by Nicholas Laughter on 1/12/17.
//  Copyright © 2017 Nicholas Laughter. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

private let creatorUserRecordIDKey = "creatorUserRecordID"
private let lastModifiedUserRecordIDKey = "lastModifiedUserRecordID"
private let creationDateKey = "creationDate"
private let modificationDateKey = "modificationDate"

class CloudKitManager {
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    let privateDatabase = CKContainer.default().privateCloudDatabase
    let sharedDatabase = CKContainer.default().sharedCloudDatabase
    
    init() {
        checkCloudKitAvailability()
    }
    
    // MARK: - User Info Discovery
    
    func fetchLoggedInUserRecord(_ completion: ((_ record: CKRecord?, _ error: Error?) -> Void)? = nil) {
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            if let error = error,
                let completion = completion {
                completion(nil, error)
            }
            if let recordID = recordID,
                let completion = completion {
                self.fetchRecord(withID: recordID, completion: completion)
            }
        }
    }
    
    func fetchUsername(for recordID: CKRecordID, completion: @escaping (_ givenName: String?, _ familyName: String?) -> Void) {
        let recordInfo = CKUserIdentityLookupInfo(userRecordID: recordID)
        let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [recordInfo])
        var userIdentities = [CKUserIdentity]()
        operation.userIdentityDiscoveredBlock = { (userIdentity, _) in
            userIdentities.append(userIdentity)
        }
        operation.discoverUserIdentitiesCompletionBlock = { (error) in
            if let error = error {
                NSLog("Error getting username from recorID: \(error)")
                completion(nil, nil)
                return
            }
            let nameComponents = userIdentities.first?.nameComponents
            completion(nameComponents?.givenName, nameComponents?.familyName)
        }
        CKContainer.default().add(operation)
    }
    
    func fetchAllDiscoverableUsers(completion: @escaping (_ userInfoRecords: [CKUserIdentity]?) -> Void) {
        let operation = CKDiscoverAllUserIdentitiesOperation()
        var userIdentities = [CKUserIdentity]()
        operation.userIdentityDiscoveredBlock = { userIdentities.append($0) }
        operation.discoverAllUserIdentitiesCompletionBlock = { error in
            if let error = error {
                NSLog("Error discovering all user identities: \(error)")
                completion(nil)
                return
            }
            completion(userIdentities)
        }
        CKContainer.default().add(operation)
    }
    
    // MARK: - Fetch Records
    
    func fetchRecord(withID recordID: CKRecordID, completion: ((_ record: CKRecord?, _ error: Error?) -> Void)? = nil) {
        publicDatabase.fetch(withRecordID: recordID) { (record, error) in
            completion?(record, error)
        }
    }
    
    func fetchRecordsWithType(_ type: String,
                              predicate: NSPredicate = NSPredicate(value: true),
                              recordFetchedBlock: ((_ record: CKRecord) -> Void)? = nil,
                              completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)? = nil) {
        var fetchedRecords = [CKRecord]()
        let query = CKQuery(recordType: type, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        let perRecordBlock = { (fetchedRecord: CKRecord) -> Void in
            fetchedRecords.append(fetchedRecord)
            recordFetchedBlock?(fetchedRecord)
        }
        queryOperation.recordFetchedBlock = perRecordBlock
        var queryCompletionBlock: (CKQueryCursor?, Error?) -> Void = { (_, _) in }
        queryCompletionBlock = { (queryCursor: CKQueryCursor?, error: Error?) -> Void in
            if let queryCursor = queryCursor {
                // This means there are more results to go get
                let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                continuedQueryOperation.recordFetchedBlock = perRecordBlock
                continuedQueryOperation.queryCompletionBlock = queryCompletionBlock
                self.publicDatabase.add(continuedQueryOperation)
            } else {
                completion?(fetchedRecords, error)
            }
        }
        queryOperation.queryCompletionBlock = queryCompletionBlock
        self.publicDatabase.add(queryOperation)
    }
    
    func fetchCurrentUserRecords(_ type: String, completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)? = nil) {
        fetchLoggedInUserRecord { (record, error) in
            if let record = record {
                let predicate = NSPredicate(format: "%K == %@", argumentArray: [creatorUserRecordIDKey, record.recordID])
                self.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: nil, completion: completion)
            }
        }
    }
    
    func fetchRecordsFromDateRange(_ type: String, fromDate: Date, toDate: Date, completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)? = nil) {
        let startDatePredicate = NSPredicate(format: "%K > %@", argumentArray: [creationDateKey, fromDate])
        let endDatePredicate = NSPredicate(format: "%K < %@", argumentArray: [creationDateKey, toDate])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [startDatePredicate, endDatePredicate])
        fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: nil) { (records, error) in
            completion?(records, error)
        }
    }
    
    // MARK: - Delete
    
    func deleteRecordWithID(_ recordID: CKRecordID, completion: ((_ recordID: CKRecordID?, _ error: Error?) -> Void)? = nil) {
        publicDatabase.delete(withRecordID: recordID) { (recordID, error) in
            completion?(recordID, error)
        }
    }
    
    func deleteRecordswithID(_ recordIDs: [CKRecordID], completion: ((_ records: [CKRecord]?, _ recordIDs: [CKRecordID]?, _ error: Error?) -> Void)? = nil) {
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.savePolicy = .ifServerRecordUnchanged
        operation.modifyRecordsCompletionBlock = completion
        publicDatabase.add(operation)
    }
    
    // MARK: - Save and Modify
    
    func saveRecords(_ records: [CKRecord], perRecordCompletion: ((_ record: CKRecord?, _ error: Error?) -> Void)? = nil, completion: ((_ record: [CKRecord]?, _ error: Error?) -> Void)? = nil) {
        modifyRecords(records, perRecordCompletion: perRecordCompletion, completion: completion)
    }
    
    func saveRecord(_ record: CKRecord, completion: ((_ record: CKRecord?, _ error: Error?) -> Void)? = nil) {
        publicDatabase.save(record) { (record, error) in
            completion?(record, error)
        }
    }
    
    func modifyRecords(_ records: [CKRecord], perRecordCompletion: ((_ record: CKRecord?, _ error: Error?) -> Void)? = nil, completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)? = nil) {
        let opertaion = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        opertaion.savePolicy = .changedKeys
        opertaion.queuePriority = .high
        opertaion.qualityOfService = .userInteractive
        opertaion.perRecordCompletionBlock = perRecordCompletion
        opertaion.modifyRecordsCompletionBlock = { (records, recordIDs, error) -> Void in
            (completion?(records, error))
        }
        publicDatabase.add(opertaion)
    }
    
    // MARK: - Subscriptions
    
    func subscribe(_ type: String,
                   predicate: NSPredicate,
                   subscriptionID: String,
                   contentAvailable: Bool,
                   alertBody: String? = nil,
                   desiredKeys: [String]? = nil,
                   options: CKQuerySubscriptionOptions,
                   completion: ((_ subscription: CKSubscription?, _ error: Error?) -> Void)? = nil) {
        let subscription = CKQuerySubscription(recordType: type, predicate: predicate, subscriptionID: subscriptionID, options: options)
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertBody = alertBody
        notificationInfo.shouldSendContentAvailable = contentAvailable
        notificationInfo.desiredKeys = desiredKeys
        subscription.notificationInfo = notificationInfo
        publicDatabase.save(subscription) { (subscription, error) in
            completion?(subscription, error)
        }
    }
    
    func unsubscribe(_ subscriptionID: String, completion: (( _ subscriptionID: String?, _ error: Error?) -> Void)? = nil) {
        publicDatabase.delete(withSubscriptionID: subscriptionID) { (subscriptionID, error) in
            completion?(subscriptionID, error)
        }
    }
    
    func fetchSubscriptions(_ completion: ((_ subscriptions: [CKSubscription]?, _ error: Error?) -> Void)? = nil) {
        publicDatabase.fetchAllSubscriptions { (subscriptions, error) in
            completion?(subscriptions, error)
        }
    }
    
    func fetchSubscription(_ subscriptionID: String, completion: ((_ subscription: CKSubscription?, _ error: Error?) -> Void)? = nil) {
        publicDatabase.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
            completion?(subscription, error)
        }
    }
    
    // MARK: - Permissions
    
    func checkCloudKitAvailability() {
        CKContainer.default().accountStatus { (accountStatus, error) in
            switch accountStatus {
            case .available: print("CloudKit available. Initializing full sync.")
            default: self.handleCloudKitUnavailable(accountStatus, error: error)
            }
        }
    }
    
    func handleCloudKitUnavailable(_ accountStatus: CKAccountStatus, error: Error?) {
        var errorText = "Sync is disabled\n"
        if let error = error {
            print("handldCloudKitUnavaiable ERROR: \(error)")
            print("An error occurred: \(error.localizedDescription)")
            errorText += error.localizedDescription
        }
        
        switch accountStatus {
        case .restricted: errorText += "iCloud is not available due to restrictions"
        case .noAccount: errorText += "There is no iCloud account set up.\nSet up iCloud in the Settings app."
        default: break
        }
        displayCloudKitNotAvailableError(errorText)
    }
    
    func displayCloudKitNotAvailableError(_ errorText: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "iCloud Sync Error!", message: errorText, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            alertController.addAction(dismissAction)
            if let appDelegate = UIApplication.shared.delegate,
                let appWindow = appDelegate.window!,
                let rootViewController = appWindow.rootViewController {
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
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
    
    func handleCloudKitPermissionStatus(_ permissionStatus: CKApplicationPermissionStatus, error: Error?) {
        if permissionStatus == .granted {
            print("User discoverability permission granted. User has full access.")
        } else {
            var errorText = "Sync is disabled\n"
            if let error = error {
                print("handleCloudKitUnavailable ERROR: \(error)")
                print("An error occurred: \(error.localizedDescription)")
                errorText += error.localizedDescription
            }
            
            switch permissionStatus {
            case .denied:
                errorText += "You have denied User Discoverability permissions. You may be unable to use certain features that require User Discoverability."
            case .couldNotComplete:
                errorText += "Unable to verify User Discoverability permissions. You may have a connectivity issue. Please try again"
            default: break
            }
            displayCloudKitNotAvailableError(errorText)
        }
    }
    
    func displayCloudKitPermissionsNotGrantedError(_ errorText: String) {
        let alertController = UIAlertController(title: "CloudKit Permissions Error", message: errorText, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alertController.addAction(dismissAction)
        if let appDelegate = UIApplication.shared.delegate,
            let appWindow = appDelegate.window!,
            let rootViewController = appWindow.rootViewController {
            rootViewController.present(alertController, animated: true, completion: nil)
        }
    }
}
