//
//  CloudKitManager.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/27/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit

class CloudKitManager {
    
    private let CreatorUserRecordIDKey = "creatorUserRecordID"
    private let LastModifiedUserRecordIDKey = "creatorUserRecordID"
    private let CreationDateKey = "creationDate"
    private let ModificationDateKey = "modificationDate"
    
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    let privateDatabase = CKContainer.defaultContainer().privateCloudDatabase
    
    init() {
        
        checkCloudKitAvailability()
    }
    
    // MARK: - User Info Discovery
    
    func fetchLoggedInUserRecord(completion: ((record: CKRecord?, error: NSError? ) -> Void)?) {
        
        CKContainer.defaultContainer().fetchUserRecordIDWithCompletionHandler { (recordID, error) in
            
            if let error = error,
                let completion = completion {
                completion(record: nil, error: error)
            }
            
            if let recordID = recordID,
                let completion = completion {
                
                self.fetchRecordWithID(recordID, completion: { (record, error) in
                    completion(record: record, error: error)
                })
            }
        }
    }
    
    func fetchUsernameFromRecordID(recordID: CKRecordID, completion: ((firstName: String?, lastName: String?) -> Void)?) {
        
        let operation = CKDiscoverUserInfosOperation(emailAddresses: nil, userRecordIDs: [recordID])
        
        operation.discoverUserInfosCompletionBlock = { (emailsToUserInfos, userRecordIDsToUserInfos, operationError) -> Void in
            
            if let userRecordIDsToUserInfos = userRecordIDsToUserInfos,
                let userInfo = userRecordIDsToUserInfos[recordID],
                let completion = completion {
                
                completion(firstName: userInfo.displayContact?.givenName, lastName: userInfo.displayContact?.familyName)
            } else if let completion = completion {
                completion(firstName: nil, lastName: nil)
            }
        }
        
        CKContainer.defaultContainer().addOperation(operation)
    }
    
    func fetchAllDiscoverableUsers(completion: ((userInfoRecords: [CKDiscoveredUserInfo]?) -> Void)?) {
        
        let operation = CKDiscoverAllContactsOperation()
        
        operation.discoverAllContactsCompletionBlock = { (discoveredUserInfos, error) -> Void in
            
            if let completion = completion {
                completion(userInfoRecords:  discoveredUserInfos)
            }
        }
        
        CKContainer.defaultContainer().addOperation(operation)
    }
    
    
    // MARK: - Fetch Records
    
    func fetchRecordWithID(recordID: CKRecordID, completion: ((record: CKRecord?, error: NSError?) -> Void)?) {
        
        publicDatabase.fetchRecordWithID(recordID) { (record, error) in
            
            if let completion = completion {
                completion(record: record, error: error)
            }
        }
    }
    
    func fetchRecordsWithType(type: String, predicate: NSPredicate = NSPredicate(value: true), recordFetchedBlock: ((record: CKRecord) -> Void)?, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        
        var fetchedRecords: [CKRecord] = []
        
        let predicate = predicate
        let query = CKQuery(recordType: type, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { (fetchedRecord) -> Void in
            
            fetchedRecords.append(fetchedRecord)
            
            if let recordFetchedBlock = recordFetchedBlock {
                recordFetchedBlock(record: fetchedRecord)
            }
        }
        
        queryOperation.queryCompletionBlock = { (queryCursor, error) -> Void in
            
            if let queryCursor = queryCursor {
                // there are more results, go fetch them
                
                let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                continuedQueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                continuedQueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                
                self.publicDatabase.addOperation(continuedQueryOperation)
            } else {
                if let completion = completion {
                    completion(records: fetchedRecords, error: error)
                }
            }
        }
        
        self.publicDatabase.addOperation(queryOperation)
    }
    
    func fetchCurrentUserRecords(type: String, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        
        fetchLoggedInUserRecord { (record, error) in
            
            if let record = record {
                
                let predicate = NSPredicate(format: "%K == %@", argumentArray: ["creatorUserRecordID", record.recordID])
                
                self.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: nil, completion: { (records, error) in
                    
                    if let completion = completion {
                        completion(records: records, error: error)
                    }
                })
            }
        }
    }
    
    func fetchRecordsNearLocation(type: String, location: CLLocation, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        
    }
    
    func fetchRecordsFromDateRange(type: String, recordType: String, fromDate: NSDate, toDate: NSDate, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        
        let startDatePredicate = NSPredicate(format: "%K > %@", argumentArray: [CreationDateKey, fromDate])
        let endDatePredicate = NSPredicate(format: "%K < %@", argumentArray: [CreationDateKey, toDate])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [startDatePredicate, endDatePredicate])
        
        
        self.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: nil) { (records, error) in
            
            if let completion = completion {
                completion(records: records, error: error)
            }
        }
    }
    
    
    // MARK: - Delete
    
    func deleteRecordWithID(recordID: CKRecordID, completion: ((recordID: CKRecordID?, error: NSError?) -> Void)?) {
        
        publicDatabase.deleteRecordWithID(recordID) { (recordID, error) in
            
            if let completion = completion {
                completion(recordID: recordID, error: error)
            }
        }
    }
    
    func deleteRecordsWithID(recordIDs: [CKRecordID], completion: ((records: [CKRecord]?, recordIDs: [CKRecordID]?, error: NSError?) -> Void)?) {
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.savePolicy = .IfServerRecordUnchanged
        operation.queuePriority = .High
        
        operation.qualityOfService = .UserInitiated
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) -> Void in
            
            if let completion = completion {
                completion(records: records, recordIDs: recordIDs, error: error)
            }
        }
    }
    
    
    // MARK: - Save and Modify
    
    func saveRecords(records: [CKRecord], perRecordCompletion: ((record: CKRecord?, error: NSError?) -> Void)?, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        
        modifyRecords(records, perRecordCompletion: perRecordCompletion) { (records, error) in
            
            if let completion = completion {
                completion(records: records, error: error)
            }
        }
    }
    
    func saveRecord(record: CKRecord, completion: ((record: CKRecord?, error: NSError?) -> Void)?) {
        
        publicDatabase.saveRecord(record) { (record, error) in
            
            if let completion = completion {
                completion(record: record, error: error)
            }
        }
    }
    
    func modifyRecords(records: [CKRecord], perRecordCompletion: ((record: CKRecord?, error: NSError?) -> Void)?, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .ChangedKeys
        operation.queuePriority = .High
        operation.qualityOfService = .UserInteractive
        
        operation.perRecordCompletionBlock = { (record, error) -> Void in
            
            if let perRecordCompletion = perRecordCompletion {
                perRecordCompletion(record: record, error: error)
            }
        }
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) -> Void in
            
            if let completion = completion {
                completion(records: records, error: error)
            }
        }
        
        publicDatabase.addOperation(operation)
    }
    
    
    // MARK: - Subscriptions
    
    func subscribe(type: String, predicate: NSPredicate, subscriptionIdentifier: String, contentAvailable: Bool, alertBody: String? = nil, desiredKeys: [String]? = nil, options: CKSubscriptionOptions, completion: ((subscription: CKSubscription?, error: NSError?) -> Void)?) {
        
        let subscription = CKSubscription(recordType: type, predicate: predicate, subscriptionID: subscriptionIdentifier, options: options)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.alertBody = alertBody
        notificationInfo.shouldSendContentAvailable = contentAvailable
        notificationInfo.desiredKeys = desiredKeys
        
        subscription.notificationInfo = notificationInfo
        
        publicDatabase.saveSubscription(subscription) { (subscription, error) in
            
            if let completion = completion {
                completion(subscription: subscription, error: error)
            }
        }
    }
    
    func unsubscribe(subscription: CKSubscription, completion: ((subscriptionID: String?, error: NSError?) -> Void)?) {
        
        publicDatabase.deleteSubscriptionWithID(subscription.subscriptionID) { (subscriptionID, error) in
            
            if let completion = completion {
                completion(subscriptionID: subscriptionID, error: error)
            }
        }
    }
    
    func fetchSubscriptions(completion: ((subscriptions: [CKSubscription]?, error: NSError?) -> Void)?) {
        
        publicDatabase.fetchAllSubscriptionsWithCompletionHandler { (subscriptions, error) in
            
            if let completion = completion {
                completion(subscriptions: subscriptions, error: error)
            }
        }
    }
    
    
    // MARK: - CloudKit Availability
    
    func checkCloudKitAvailability() {
        
        CKContainer.defaultContainer().accountStatusWithCompletionHandler() {
            (accountStatus:CKAccountStatus, error:NSError?) -> Void in
            
            switch accountStatus {
            case .Available:
                print("CloudKit available. Initializing full sync.")
                return
            default:
                self.handleCloudKitUnavailable(accountStatus, error: error)
            }
        }
    }
    
    func handleCloudKitUnavailable(accountStatus: CKAccountStatus, error:NSError?) {
        
        var errorText = "Synchronization is disabled\n"
        if let error = error {
            print("handleCloudKitUnavailable ERROR: \(error)")
            print("An error occured: \(error.localizedDescription)")
            errorText += error.localizedDescription
        }
        
        switch accountStatus {
        case .Restricted:
            errorText += "iCloud is not available due to restrictions"
        case .NoAccount:
            errorText += "There is no CloudKit account setup.\nYou can setup iCloud in the Settings app."
        default:
            break
        }
        
        displayCloudKitNotAvailableError(errorText)
    }
    
    func displayCloudKitNotAvailableError(errorText: String) {
        
        dispatch_async(dispatch_get_main_queue(),{
            
            let alertController = UIAlertController(title: "iCloud Synchronization Error", message: errorText, preferredStyle: .Alert)
            
            let dismissAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil);
            
            alertController.addAction(dismissAction)
            
            if let appDelegate = UIApplication.sharedApplication().delegate,
                let appWindow = appDelegate.window!,
                let rootViewController = appWindow.rootViewController {
                rootViewController.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }
}