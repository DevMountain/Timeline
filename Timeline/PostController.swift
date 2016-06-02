//
//  PostController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData

class PostController {
    
    static let sharedController = PostController()
    
    let fetchedResultsController: NSFetchedResultsController
    let cloudKitManager: CloudKitManager
    
    init() {
        
        let request = NSFetchRequest(entityName: "Post")
        request.returnsObjectsAsFaults = false
        let dateSortDescription = NSSortDescriptor(key: "added", ascending: false)
        request.sortDescriptors = [dateSortDescription]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: Stack.sharedStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Unable to perform fetch request: \(error.localizedDescription)")
        }
        
        self.cloudKitManager = CloudKitManager()
        
        fullSync()
    }
    
    func createPost(image: UIImage, caption: String, completion: (() -> Void)?) {
        
        guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
        
        let post = Post(photo: data, caption: caption)
        
        saveContext()
        
        if let postRecord = post.cloudKitRecord {
            
            if let completion = completion {
                completion()
            }
            
            cloudKitManager.saveRecord(postRecord) { (record, error) in
                
                if let record = record {
                    post.updateWithRecord(record)
                    
                    
                }
            }
        }
    }
    
    func addCommentToPost(text: String, post: Post, completion: ((success: Bool) -> Void)?) {
        
        let comment = Comment(post: post, text: text)
        
        saveContext()
        
        if let commentRecord = comment.cloudKitRecord {
            cloudKitManager.saveRecord(commentRecord, completion: { (record, error) in
                
                if let record = record {
                    comment.updateWithRecord(record)
                    
                    if let completion = completion {
                        completion(success: true)
                    }
                } else {
                    if let completion = completion {
                        completion(success: false)
                    }
                }
            })
        } else {
            
            if let completion = completion {
                completion(success: false)
            }
        }
    }
    
    // MARK: - Helper Fetches
    
    func postWithName(name: String) -> Post? {
        
        let fetchRequest = NSFetchRequest(entityName: "Post")
        let predicate = NSPredicate(format: "recordName == %@", argumentArray: [name])
        fetchRequest.predicate = predicate
        
        // TODO: Sometimes this works... sometimes it doesn't
        
        let result = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Post]) ?? nil
        
        return result?.first
    }
    
    // MARK: - Sync Code
    
    func syncedRecords(type: String) -> [CloudKitManagedObject] {
        
        let fetchRequest = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: "recordData != nil")
        
        fetchRequest.predicate = predicate
        
        let results = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        
        return results
    }
    
    func unsyncedRecords(type: String) -> [CloudKitManagedObject] {
        
        let fetchRequest = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: "recordData == nil")
        
        fetchRequest.predicate = predicate
        
        let results = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        
        return results
    }
    
    func fullSync() {
        
        pushChangesToCloudKit { (success) in
            
            self.fetchChangesFromCloudKit(nil)
        }
    }
    
    func fetchChangesFromCloudKit(completion: ((succes: Bool) -> Void)?) {
        
        let group = dispatch_group_create()
        
        // fetch recordids for all post objects
        // create predicate
        // fetch objects with predicate
        // save each object
        
        dispatch_group_enter(group)
        
        let postReferencesToExclude = syncedRecords("Post").flatMap({ $0.cloudKitReference })
        var postPredicate = NSPredicate(format: "NOT(recordID IN %@)", argumentArray: [postReferencesToExclude])
        // postReferencesToExclude must be sent in an array, otherwise predicate is looking for a token for each postReference
        
        if postReferencesToExclude.isEmpty {
            postPredicate = NSPredicate(value: true)
        }
        
        cloudKitManager.fetchRecordsWithType("Post", predicate: postPredicate, recordFetchedBlock: { (record) in
            
            let _ = Post(record: record)
            self.saveContext()
            
        }) { (records, error) in
            
            if error != nil {
                print("All Post records fetched and added.")
            }
            
            dispatch_group_leave(group)
        }
        
        
        // fetch recordids for all comment objects
        // create predicate
        // fetch objects with predicate
        // save each object
        
        dispatch_group_enter(group)
        
        let commentReferencesToExclude = syncedRecords("Comment").flatMap({ $0.cloudKitReference })
        var commentPredicate = NSPredicate(format: "NOT(recordID IN %@)", argumentArray: [commentReferencesToExclude])
        // commentReferencesToExclude must be sent in an array, otherwise predicate is looking for a token for each commentReference
        
        if commentReferencesToExclude.isEmpty {
            commentPredicate = NSPredicate(value: true)
        }
        
        cloudKitManager.fetchRecordsWithType("Comment", predicate: commentPredicate, recordFetchedBlock: { (record) in
            
            let _ = Comment(record: record)
            self.saveContext()
            
        }) { (records, error) in
            
            if error != nil {
                print("All Comment records fetched and added.")
            }
            
            dispatch_group_leave(group)
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            
            if let completion = completion {
                completion(succes: true)
            }
        }
        
    }
    
    func fetchNewRecordsFromCloudKit(type: String, completion: () -> Void) {
        
        
        let referencesToExclude = syncedRecords(type).flatMap({ $0.cloudKitReference })
        var predicate = NSPredicate(format: "NOT(recordID IN %@)", argumentArray: [referencesToExclude])
        // commentReferencesToExclude must be sent in an array, otherwise predicate is looking for a token for each commentReference
        
        if referencesToExclude.isEmpty {
            predicate = NSPredicate(value: true)
        }
        
        cloudKitManager.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: { (record) in
            
            switch type {
                
            case "Post":
                let _ = Post(record: record)
                
            case "Comment":
                let _ = Comment(record: record)
                
            default:
                return
            }
            
            self.saveContext()
            
        }) { (records, error) in
            
            if error != nil {
                print("All Comment records fetched and added.")
            }
        }
    }
    
    func pushChangesToCloudKit(completion: ((success: Bool) -> Void)?) {
        
        let group = dispatch_group_create()
        
        // fetch all local post objects
        // filter by isSynced = false
        // map records
        // save records
        
        for post in unsyncedRecords("Post") {
            
            dispatch_group_enter(group)
            
            guard let record = post.cloudKitRecord else { return }
            
            cloudKitManager.saveRecord(record, completion: { (record, error) in
                
                if let record = record {
                    post.updateWithRecord(record)
                }
                
                dispatch_group_leave(group)
            })
        }
        
        // fetch all local comment objects
        // filter by isSynced = false
        // map records
        // save records
        
        for comment in unsyncedRecords("Comment") {
            
            dispatch_group_enter(group)
            
            guard let record = comment.cloudKitRecord else { return }
            
            cloudKitManager.saveRecord(record, completion: { (record, error) in
                
                if let record = record {
                    comment.updateWithRecord(record)
                }
                
                dispatch_group_leave(group)
            })
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            
            if let completion = completion {
                completion(success: true)
            }
        }
        
    }
    
    func saveContext() {
        
        do {
            try Stack.sharedStack.managedObjectContext.save()
        } catch {
            print("Error saving Managed Object Context. Error: \(error)")
        }
    }
}