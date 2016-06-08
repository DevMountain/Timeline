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
    
    let cloudKitManager: CloudKitManager
    
    var posts: [Post] {
        
        let fetchRequest = NSFetchRequest(entityName: "Post")
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let results = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [Post] ?? []
        
        return results
    }
    
    init() {
        
        self.cloudKitManager = CloudKitManager()
        
        fullSync()
        
        subscribeToNewPosts { (success, error) in
            
            if success {
                print("Successfully subscribed to new posts.")
            }
        }
    }
    
    func createPost(image: UIImage, caption: String, completion: (() -> Void)?) {
        guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
        
        let post = Post(photo: data)
        
        addCommentToPost(caption, post: post, completion: nil)
        
        saveContext()
        
        if let completion = completion {
            completion()
        }
        
        if let postRecord = post.cloudKitRecord {
            
            cloudKitManager.saveRecord(postRecord, completion: { (record, error) in
                
                if let record = record {
                    post.update(record)
                    
                    self.addSubscriptionToPostComments(post, alertBody: "Someone commented on your post! 👍", completion: { (success, error) in
                        
                        if let error = error {
                            print("Unable to save comment subscription: \(error.localizedDescription)")
                        }
                    })
                }
            })
        }
    }
    
    func addCommentToPost(text: String, post: Post, completion: ((success: Bool) -> Void)?) {
        
        let comment = Comment(post: post, text: text)
        
        saveContext()
        
        if let completion = completion {
            completion(success: true)
        }
        
        if let commentRecord = comment.cloudKitRecord {
            
            cloudKitManager.saveRecord(commentRecord, completion: { (record, error) in
                
                if let record = record {
                    comment.update(record)
                }
            })
        }
    }
    
    // MARK: - Helper Fetches
    
    func postWithName(name: String) -> Post? {
        
        if name.isEmpty { return nil }
        
        let fetchRequest = NSFetchRequest(entityName: "Post")
        let predicate = NSPredicate(format: "recordName == %@", argumentArray: [name])
        fetchRequest.predicate = predicate
        
        let result = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Post]) ?? nil
        
        return result?.first
    }
    
    // MARK: - Sync
    
    func fullSync(completion: (() -> Void)? = nil) {
        
        pushChangesToCloudKit { (success) in
            
            self.fetchNewRecords("Post") {
                
                self.fetchNewRecords("Comment", completion: nil)
                
                if let completion = completion {
                    
                    completion()
                }
            }
        }
    }
    
    func syncedRecords(type: String) -> [CloudKitManagedObject] {
        
        let fetchRequest = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: "recordIDData != nil")
        
        fetchRequest.predicate = predicate
        
        let results = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        
        return results
    }
    
    func unsyncedRecords(type: String) -> [CloudKitManagedObject] {
        
        let fetchRequest = NSFetchRequest(entityName: type)
        let predicate = NSPredicate(format: "recordIDData == nil")
        
        fetchRequest.predicate = predicate
        
        let results = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest)) as? [CloudKitManagedObject] ?? []
        
        return results
    }
    
    func fetchNewRecords(type: String, completion: (() -> Void)?) {
        
        let referencesToExclude = syncedRecords(type).flatMap({ $0.cloudKitReference })
        var predicate = NSPredicate(format: "NOT(recordID IN %@)", argumentArray: [referencesToExclude])
        
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
                print("😱")
            }
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    func pushChangesToCloudKit(completion: ((success: Bool, error: NSError?) -> Void)?) {
        
        let unsavedManagedObjects = unsyncedRecords("Post") + unsyncedRecords("Comment")
        let unsavedRecords = unsavedManagedObjects.flatMap({ $0.cloudKitRecord })
        
        cloudKitManager.saveRecords(unsavedRecords, perRecordCompletion: { (record, error) in
            
            guard let record = record else { return }
            
            if let matchingRecord = unsavedManagedObjects.filter({ $0.recordName == record.recordID.recordName }).first {
                
                matchingRecord.update(record)
            }
            
        }) { (records, error) in
            
            if let completion = completion {
                
                let success = records != nil
                completion(success: success, error: error)
            }
        }
    }
    
    // MARK: - Subscriptions
    
    func subscribeToNewPosts(completion: ((success: Bool, error: NSError?) -> Void)?) {
        
        let predicate = NSPredicate(value: true)
        
        cloudKitManager.subscribe("Post", predicate: predicate, subscriptionID: "allPosts", contentAvailable: true, options: .FiresOnRecordCreation) { (subscription, error) in
            
            if let completion = completion {
                
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
    
    func checkSubscriptionToPostComments(post: Post, completion: ((subscribed: Bool) -> Void)?) {
        
        cloudKitManager.fetchSubscription(post.recordName) { (subscription, error) in
            
            if let completion = completion {
                
                let subscribed = subscription != nil
                completion(subscribed: subscribed)
            }
        }
    }
    
    func addSubscriptionToPostComments(post: Post, alertBody: String?, completion: ((success: Bool, error: NSError?) -> Void)?) {
        
        guard let recordID = post.cloudKitRecordID else { fatalError("Unable to create CloudKit reference for subscription.") }
        
        let predicate = NSPredicate(format: "post == %@", argumentArray: [recordID])
        
        cloudKitManager.subscribe("Comment", predicate: predicate, subscriptionID: post.recordName, contentAvailable: true, alertBody: alertBody, desiredKeys: ["text", "post"], options: .FiresOnRecordCreation) { (subscription, error) in
            
            if let completion = completion {
                
                let success = subscription != nil
                completion(success: success, error: error)
            }
        }
    }
    
    func removeSubscriptionToPostComments(post: Post, completion: ((success: Bool, error: NSError?) -> Void)?) {
        
        let subscriptionID = post.recordName
        
        cloudKitManager.unsubscribe(subscriptionID) { (subscriptionID, error) in
            
            if let completion = completion {
                
                let success = subscriptionID != nil && error == nil
                completion(success: success, error: error)
            }
        }
    }
    
    func togglePostCommentSubscription(post: Post, completion: ((success: Bool, isSubscribed: Bool, error: NSError?) -> Void)?) {
        
        cloudKitManager.fetchSubscriptions { (subscriptions, error) in
            
            if subscriptions?.filter({ $0.subscriptionID == post.recordName }).first != nil {
                
                self.removeSubscriptionToPostComments(post, completion: { (success, error) in
                    
                    if let completion = completion {
                        completion(success: success, isSubscribed: false, error: error)
                    }
                })
            } else {
                
                self.addSubscriptionToPostComments(post, alertBody: "Someone commented on a post you follow! 👍", completion: { (success, error) in
                    
                    if let completion = completion {
                        completion(success: true, isSubscribed: true, error: error)
                    }
                })
            }
        }
    }
    
    func saveContext() {
        
        do {
            try Stack.sharedStack.managedObjectContext.save()
        } catch {
            print("Unable to save context: \(error)")
        }
    }
}