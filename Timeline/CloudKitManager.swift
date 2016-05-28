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
    
    enum RecordTypes: String {
        case post = "Post"
        case comment = "Comment"
    }
    
    private let CreatorUserRecordIDKey = "creatorUserRecordID"
    private let LastModifiedUserRecordIDKey = "creatorUserRecordID"
    private let CreationDate = "creationDate"
    private let modificationDate = "modificationDate"
    
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    init() {
        
        // call accountStatusWithCompletionHandler
        
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
    
    func fetchMyRecords(completion: ((records: [CKRecord], error: NSError?) -> Void)?) {
        
        fetchLoggedInUserRecord { (record, error) in
            
            if let record = record {
                
                var fetchedRecords: [CKRecord] = []
                
                let predicate = NSPredicate(format: "%K == %@", argumentArray: ["creatorUserRecordID", record.recordID])
                let recordType = RecordTypes.post.rawValue // Fetch only posts, we do not need comments
                let query = CKQuery(recordType: recordType, predicate: predicate)
                let queryOperation = CKQueryOperation(query: query)
                
                queryOperation.recordFetchedBlock = { (fetchedRecord) -> Void in
                    
                    fetchedRecords.append(fetchedRecord)
                }
                
                queryOperation.queryCompletionBlock = { (queryCursor, error) -> Void in
                    
                    if let queryCursor = queryCursor {
                        // there are more results, go fetch them
                        
                        let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                        continuedQueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                        continuedQueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                        
                        self.publicDatabase.addOperation(continuedQueryOperation)
                    }
                    
                    if let completion = completion {
                        
                        completion(records: fetchedRecords, error: error)
                    }
                }
                
                self.publicDatabase.addOperation(queryOperation)
            }
        }
    }
    
    func fetchRecordsWithType(type: String, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        
        var fetchedRecords: [CKRecord] = []
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: type, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { (fetchedRecord) -> Void in
            
            fetchedRecords.append(fetchedRecord)
        }
        
        queryOperation.queryCompletionBlock = { (queryCursor, error) -> Void in
            
            if let queryCursor = queryCursor {
                // there are more results, go fetch them
                
                let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                continuedQueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                continuedQueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                
                self.publicDatabase.addOperation(continuedQueryOperation)
            }
            
            if let completion = completion {
                
                completion(records: fetchedRecords, error: error)
            }
        }
        
        self.publicDatabase.addOperation(queryOperation)
    }
    
    func fetchRecordWithID(recordID: CKRecordID, completion: ((record: CKRecord?, error: NSError?) -> Void)?) {
        
        publicDatabase.fetchRecordWithID(recordID) { (record, error) in
            
            if let completion = completion {
                
                completion(record: record, error: error)
            }
        }
    }
    
    //    func fetchRecordsNearLocation(location: CLLocation, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
    //
    //    }
    
    func fetchRecentRecords(recordType: String, fromDate: NSDate, toDate: NSDate, completion: ((records: [CKRecord]?, error: NSError?) -> Void)?) {
        
        var fetchedRecords: [CKRecord] = []
        
        let startDatePredicate = NSPredicate(format: "%K >= %@", argumentArray: [CreationDate, fromDate])
        let endDatePredicate = NSPredicate(format: "%K =< %@", argumentArray: [CreationDate, toDate])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [startDatePredicate, endDatePredicate])
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { (fetchedRecord) -> Void in
            
            fetchedRecords.append(fetchedRecord)
        }
        
        queryOperation.queryCompletionBlock = { (queryCursor, error) -> Void in
            
            if let queryCursor = queryCursor {
                // there are more results, go fetch them
                
                let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                continuedQueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                continuedQueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                
                self.publicDatabase.addOperation(continuedQueryOperation)
            }
            
            if let completion = completion {
                
                completion(records: fetchedRecords, error: error)
            }
        }
        
        self.publicDatabase.addOperation(queryOperation)
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
    
    func saveAllChanges(insertedObjects: [NSManagedObject], completion: ((records: [CKRecord]?) -> Void)?) {
        
        // create records for new objects
        
        var savedRecords: [CKRecord] = []

        let group = dispatch_group_create()
        
        for object in insertedObjects {
            
            dispatch_group_enter(group)
            
            guard let cloudKitManagedObject = object as? CloudKitManagedObject,
                let record = cloudKitManagedObject.cloudKitRecord else { fatalError("Unable to access record to save CloudKitManagedObject") }
            
            saveRecord(record, completion: { (savedRecord, error) in
                
                if let error = error {
                    print("Error saving object. Error: \(error.description)")
                }
                
                if let savedRecord = savedRecord {
                    savedRecords.append(savedRecord)
                }
                
                dispatch_group_leave(group)
            })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { 
            
            if let completion = completion {
                completion(records: savedRecords)
            }
        }
        
        // modify records from managed objects
        
        // delete records
    }
    
    func saveRecord(record: CKRecord, completion: ((record: CKRecord?, error: NSError?) -> Void)?) {
        
        publicDatabase.saveRecord(record) { (record, error) in
            
            if let completion = completion {
                completion(record: record, error: error)
            }
        }
    }
    
    func modifyRecord(record: CKRecord, completion: ((record: CKRecord?, error: NSError?) -> Void)?) {
        
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.savePolicy = .IfServerRecordUnchanged
        operation.queuePriority = .High
        operation.qualityOfService = .UserInitiated
        
        operation.perRecordProgressBlock = { (record, progress) -> Void in
            
            print("modified record: \(record) \n percent: \(progress)")
        }
        
        operation.perRecordCompletionBlock = { (record, error) -> Void in
            
            if error != nil {
                
                if error?.code == CKErrorCode.ServerRecordChanged.rawValue {
                    // conflict
                    
                    let fetchedOriginalRecord = error?.userInfo[CKRecordChangedErrorAncestorRecordKey] // the record last time client pulled it
                    let fetchedServerRecord = error?.userInfo[CKRecordChangedErrorServerRecordKey] // the current record on the server
                    let fetchedClientRecord = error?.userInfo[CKRecordChangedErrorClientRecordKey] // the original record, with the changes you attempted to save
                    
                    guard let _ = fetchedOriginalRecord as? CKRecord,
                        let serverRecord = fetchedServerRecord as? CKRecord,
                        let clientRecord = fetchedClientRecord as? CKRecord else { fatalError("Error CKModifyRecordsOperation, can't obtain ancestor, server, or client record to resolve server conflict") }
                    
                    for key in clientRecord.allKeys() {
                        
                        serverRecord[key] = clientRecord[key]
                    }
                    
                    self.publicDatabase.saveRecord(serverRecord, completionHandler: { (savedRecord, error) in
                        
                        if let completion = completion {
                            completion(record: savedRecord, error: error)
                        }
                    })
                } else {
                    
                    if let completion = completion {
                        completion(record: record, error: error)
                    }
                }
            } else {
                
                if let completion = completion {
                    completion(record: record, error: error)
                }
            }
        }
    }
    
    
    // MARK: - Owned Records
    
    //    func isMyRecord(recordID: CKRecordID) -> Bool {
    //
    //    }
    
    
    // MARK: - Subscriptions
    
    func subscribe(type: String, predicate: NSPredicate, completion: ((subscription: CKSubscription?, error: NSError?) -> Void)?) {
        
    }
    
    func unsubscribe(subscription: CKSubscription, completion: (subscription: CKSubscription?, error: NSError?) -> Void) {
        
    }
    
    func fetchSubscriptions(completion: ((subscriptions: [CKSubscription]?, error: NSError?) -> Void)?) {
        
    }
    
    // MARK: - CloudKit Availability
    
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