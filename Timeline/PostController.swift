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
        
        subscribeToNewPosts { (success, error) in
            
            if success {
                print("Successfully subscribed to new posts.")
            }
        }
    }
    
    func createPostWith(image: UIImage, caption: String, completion: ((Post) -> Void)?) {
        guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
        
        let post = Post(photoData: data)
        
        posts.insert(post, at: 0)
        
        let captionComment = addComment(toPost: post, commentText: caption)
        
        CloudKitManager.shared.saveRecord(post.cloudKitRecord, database: publicDatabase) { (record, error) in
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
            CloudKitManager.shared.saveRecord(captionComment.cloudKitRecord, database: self.publicDatabase) { (record, error) in
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
        
        CloudKitManager.shared.saveRecord(comment.cloudKitRecord, database: publicDatabase) { (record, error) in
            if let error = error {
                NSLog("Error saving new comment to CloudKit: \(error)")
                return
            }
            
            comment.cloudKitRecordID = record?.recordID
            post.comments.insert(comment, at: 0)
            
            completion(comment)
        }
        
        
        return comment
    }
    
    func fetchPosts(completion: @escaping (() -> Void) = { }) {
        
        let sortDescriptor = NSSortDescriptor(key: Post.timestampKey, ascending: false)
        
        CloudKitManager.shared.fetchRecordsOfType(Post.typeKey, database: publicDatabase, sortDescriptors: [sortDescriptor]) { (records, error) in
            
            if let error = error {
                NSLog("Error fetching Post records: \(error)")
                return
            }
            
            guard let records = records else { return }
            
            let posts = records.flatMap { Post(record: $0) }
            
            let group = DispatchGroup()
            
            for post in posts {
                group.enter()
                self.fetchCommentsFor(post: post, completion: {
                    group.leave()
                })
            }
            
            
            group.notify(queue: DispatchQueue.main, execute: {
                self.posts = posts
                completion()
            })
            
        }
        
    }
    
    func fetchCommentsFor(post: Post, completion: @escaping (() -> Void) = { }) {
        let sortDescriptor = NSSortDescriptor(key: Comment.timestampKey, ascending: false)
        
        let postReference = CKReference(record: post.cloudKitRecord, action: .deleteSelf)
        
        let predicate = NSPredicate(format: "%K == %@", Comment.postKey, postReference)
        
        CloudKitManager.shared.fetchRecordsOfType(Comment.typeKey, predicate: predicate, database: publicDatabase, sortDescriptors: [sortDescriptor]) { (records, error) in
            
            if let error = error {
                NSLog("Error fetching Post records: \(error)")
                return
            }
            
            guard let records = records else { return }
            
            let comments = records.flatMap { Comment(record: $0) }
            post.comments = comments
            
            completion()
        }
    }

    // MARK: - Subscriptions
    
    func subscribeToNewPosts(completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = { _,_ in }) {
        
        let predicate = NSPredicate(value: true)
        
        CloudKitManager.shared.subscribe(Post.typeKey, predicate: predicate, database: publicDatabase, subscriptionID: "allPosts", contentAvailable: true, options: .firesOnRecordCreation) { (subscription, error) in
            
            let success = subscription != nil
            completion(success, error)
        }
    }
    
    func checkSubscriptionTo(commentsForPost post: Post, completion: @escaping ((_ subscribed: Bool) -> Void) = { _ in }) {
        
        guard let subscriptionID = post.cloudKitRecordID?.recordName else {
            completion(false)
            return
        }
        
        CloudKitManager.shared.fetchSubscription(subscriptionID, database: publicDatabase) { (subscription, error) in
            let subscribed = subscription != nil
            completion(subscribed)
        }
    }
    
    func addSubscriptionTo(commentsForPost post: Post,
                           alertBody: String?,
                           completion: @escaping ((_ success: Bool, _ error: Error?) -> Void) = { _,_ in }) {
        
        guard let recordID = post.cloudKitRecordID else { fatalError("Unable to create CloudKit reference for subscription.") }
        
        let predicate = NSPredicate(format: "post == %@", argumentArray: [recordID])
        
        CloudKitManager.shared.subscribe(Comment.typeKey, predicate: predicate, database: publicDatabase, subscriptionID: recordID.recordName, contentAvailable: true, alertBody: alertBody, desiredKeys: [Comment.textKey, Comment.postKey], options: .firesOnRecordCreation) { (subscription, error) in
            
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
        
        CloudKitManager.shared.unsubscribe(subscriptionID, database: publicDatabase) { (subscriptionID, error) in
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
        
        CloudKitManager.shared.fetchSubscription(subscriptionID, database: publicDatabase) { (subscription, error) in
            
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
    
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
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
}
