//
//  PostController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

extension PostController {
    static let PostsChangedNotification = Notification.Name("PostsChangedNotification")
    static let PostCommentsChangedNotification = Notification.Name("PostCommentsChangedNotification")
}

class PostController {
    
    static let sharedController = PostController()
    
    init() {
        
        self.cloudKitManager = CloudKitManager()
        
        performFullSync()
        
        subscribeToNewPosts { (success, error) in
            
            if success {
                print("Successfully subscribed to new posts.")
            }
        }
    }
    
    func createPostWith(image: UIImage, caption: String, completion: ((Post) -> Void)?) {
        guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
        
        let post = Post(photoData: data)
        posts.append(post)
        let captionComment = addComment(toPost: post, commentText: caption)
        
        cloudKitManager.saveRecord(CKRecord(post)) { (record, error) in
            guard let record = record else {
                if let error = error {
                    NSLog("Error saving new post to CloudKit: \(error)")
                    return
                }
                completion?(post)
                return
            }
            post.cloudKitRecordID = record.recordID
            
            // Save comment record
            self.cloudKitManager.saveRecord(CKRecord(captionComment)) { (record, error) in
                if let error = error {
                    NSLog("Error saving new comment to CloudKit: \(error)")
                    return
                }
                captionComment.cloudKitRecordID = record?.recordID
                completion?(post)
            }
            
            self.addSubscriptionTo(commentsForPost: post, alertBody: "Someone commented on your post! 👍") { (success, error) in
                if let error = error {
                    NSLog("Unable to save comment subscription: \(error)")
                }
            }
        }
    }
    
    @discardableResult func addComment(toPost post: Post,
                                       commentText: String,
                                       completion: @escaping ((Comment) -> Void) = { _ in }) -> Comment {
        
        let comment = Comment(post: post, text: commentText)
        post.comments.append(comment)
        
        cloudKitManager.saveRecord(CKRecord(comment)) { (record, error) in
            if let error = error {
                NSLog("Error saving new comment to CloudKit: \(error)")
                return
            }
            comment.cloudKitRecordID = record?.recordID
            completion(comment)
        }
        
        DispatchQueue.main.async {
            let nc = NotificationCenter.default
            nc.post(name: PostController.PostCommentsChangedNotification, object: post)
        }
        
        return comment
    }
    
    
    // MARK: - Helper Fetches
    
    private func recordsOf(type: String) -> [CloudKitSyncable] {
        switch type {
        case "Post":
            return posts.flatMap { $0 as CloudKitSyncable }
        case "Comment":
            return comments.flatMap { $0 as CloudKitSyncable }
        default:
            return []
        }
    }
    
    func syncedRecordsOf(type: String) -> [CloudKitSyncable] {
        return recordsOf(type: type).filter { $0.isSynced }
    }
    
    func unsyncedRecordsOf(type: String) -> [CloudKitSyncable] {
        return recordsOf(type: type).filter { !$0.isSynced }
    }
    
    // MARK: - Sync
    
    func performFullSync(completion: @escaping (() -> Void) = { _ in }) {
        
        guard !isSyncing else {
            completion()
            return
        }
        
        isSyncing = true
        
        pushChangesToCloudKit { (success) in
            
            self.fetchNewRecordsOf(type: Post.typeKey) {
                
                self.fetchNewRecordsOf(type: Comment.typeKey) {
                    
                    self.isSyncing = false
                    
                    completion()
                }
            }
        }
        
    }
    
    func fetchNewRecordsOf(type: String, completion: @escaping (() -> Void) = { _ in }) {
        
        var referencesToExclude = [CKReference]()
        var predicate: NSPredicate!
        referencesToExclude = self.syncedRecordsOf(type: type).flatMap { $0.cloudKitReference }
        predicate = NSPredicate(format: "NOT(recordID IN %@)", argumentArray: [referencesToExclude])
        
        if referencesToExclude.isEmpty {
            predicate = NSPredicate(value: true)
        }

        let sortDescriptors: [NSSortDescriptor]?
        switch type {
        case Post.typeKey:
            let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
            sortDescriptors = [sortDescriptor]
        case Comment.typeKey:
            let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: true)
            sortDescriptors = [sortDescriptor]
        default:
            sortDescriptors = nil
        }
        
        cloudKitManager.fetchRecordsWithType(type, predicate: predicate, sortDescriptors: sortDescriptors) { (records, error) in
            
            defer { completion() }
            if let error = error {
                NSLog("Error fetching CloudKit records of type \(type): \(error)")
                return
            }
            guard let records = records else { return }
            
            switch type {
            case Post.typeKey:
                let posts = records.flatMap { Post(record: $0) }
                self.posts.append(contentsOf: posts)
            case Comment.typeKey:
                for record in records {
                    guard let postReference = record[Comment.postKey] as? CKReference,
                        let postIndex = self.posts.index(where: { $0.cloudKitRecordID == postReference.recordID }),
                        let comment = Comment(record: record) else { continue }
                    let post = self.posts[postIndex]
                    post.comments.append(comment)
                    comment.post = post
                }
            default:
                return
            }
        }
    }
    
    func pushChangesToCloudKit(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = { _,_ in }) {
        
        let unsavedPosts = unsyncedRecordsOf(type: Post.typeKey) as? [Post] ?? []
        let unsavedComments = unsyncedRecordsOf(type: Comment.typeKey) as? [Comment] ?? []
        var unsavedObjectsByRecord = [CKRecord: CloudKitSyncable]()
        for post in unsavedPosts {
            let record = CKRecord(post)
            unsavedObjectsByRecord[record] = post
        }
        for comment in unsavedComments {
            let record = CKRecord(comment)
            unsavedObjectsByRecord[record] = comment
        }
        
        let unsavedRecords = Array(unsavedObjectsByRecord.keys)
        
        cloudKitManager.saveRecords(unsavedRecords, perRecordCompletion: { (record, error) in
            
            guard let record = record else { return }
            unsavedObjectsByRecord[record]?.cloudKitRecordID = record.recordID
            
        }) { (records, error) in
            
            let success = records != nil
            completion(success, error)
        }
    }
    
    
    // MARK: - Subscriptions
    
    func subscribeToNewPosts(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = { _,_ in }) {
        
        let predicate = NSPredicate(value: true)
        
        cloudKitManager.subscribe(Post.typeKey, predicate: predicate, subscriptionID: "allPosts", contentAvailable: true, options: .firesOnRecordCreation) { (subscription, error) in
            
            let success = subscription != nil
            completion(success, error)
        }
    }
    
    func checkSubscriptionTo(commentsForPost post: Post, completion: @escaping ((_ subscribed: Bool) -> Void) = { _ in }) {
        
        guard let subscriptionID = post.cloudKitRecordID?.recordName else {
            completion(false)
            return
        }
        
        cloudKitManager.fetchSubscription(subscriptionID) { (subscription, error) in
            let subscribed = subscription != nil
            completion(subscribed)
        }
    }
    
    func addSubscriptionTo(commentsForPost post: Post,
                           alertBody: String?,
                           completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = { _,_ in }) {
        
        guard let recordID = post.cloudKitRecordID else { fatalError("Unable to create CloudKit reference for subscription.") }
        
        let predicate = NSPredicate(format: "post == %@", argumentArray: [recordID])
        
        cloudKitManager.subscribe(Comment.typeKey, predicate: predicate, subscriptionID: recordID.recordName, contentAvailable: true, alertBody: alertBody, desiredKeys: [Comment.textKey, Comment.postKey], options: .firesOnRecordCreation) { (subscription, error) in
            
            let success = subscription != nil
            completion(success, error)
        }
    }
    
    func removeSubscriptionTo(commentsForPost post: Post,
                              completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = { _,_ in }) {
        
        guard let subscriptionID = post.cloudKitRecordID?.recordName else {
            completion(true, nil)
            return
        }
        
        cloudKitManager.unsubscribe(subscriptionID) { (subscriptionID, error) in
            let success = subscriptionID != nil && error == nil
            completion(success, error)
        }
    }
    
    func toggleSubscriptionTo(commentsForPost post: Post,
                              completion: @escaping ((_ success: Bool, _ isSubscribed: Bool, _ error: Error?) -> Void) = { _,_,_ in }) {
        
        guard let subscriptionID = post.cloudKitRecordID?.recordName else {
            completion(false, false, nil)
            return
        }
        
        cloudKitManager.fetchSubscription(subscriptionID) { (subscription, error) in
            
            if subscription != nil {
                self.removeSubscriptionTo(commentsForPost: post) { (success, error) in
                    completion(success, false, error)
                }
            } else {
                self.addSubscriptionTo(commentsForPost: post, alertBody: "Someone commented on a post you follow! 👍") { (success, error) in
                    completion(success, true, error)
                }
            }
        }
    }
    
    // MARK: - Properties
    
    let cloudKitManager: CloudKitManager
    
    var isSyncing: Bool = false
    
    var posts = [Post]() {
        didSet {
            DispatchQueue.main.async {
                let nc = NotificationCenter.default
                nc.post(name: PostController.PostsChangedNotification, object: self)
            }
        }
    }
    var sortedPosts: [Post] {
        return posts.sorted { return $0.timestamp.compare($1.timestamp as Date) == .orderedAscending }
    }
    var comments: [Comment] {
        return posts.flatMap { $0.comments }
    }
    
}
