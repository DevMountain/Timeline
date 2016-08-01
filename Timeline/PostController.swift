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

class PostController {
	
	static let sharedController = PostController()
	
	static let PostsChangedNotification = "PostsChangedNotification"
	static let PostCommentsChangedNotification = "PostCommentsChangedNotification"
	
	init() {
		
		self.cloudKitManager = CloudKitManager()
		
		performFullSync()
		
		subscribeToNewPosts { (success, error) in
			
			if success {
				print("Successfully subscribed to new posts.")
			}
		}
	}
	
	func createPost(image: UIImage, caption: String, completion: ((Post) -> Void)?) {
		guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
		
		var post = Post(photoData: data)
		addCommentToPost(caption, post: post, completion: nil)
		posts.append(post)
		
		cloudKitManager.saveRecord(CKRecord(post)) { (record, error) in
			defer { completion?(post) }
			guard let record = record else { return }
			post.cloudKitRecordID = record.recordID
			
			self.addSubscriptionToPostComments(post, alertBody: "Someone commented on your post! 👍") { (success, error) in
				if let error = error {
					print("Unable to save comment subscription: \(error.localizedDescription)")
				}
			}
		}
	}
	
	func addCommentToPost(text: String, post: Post, completion: ((Comment) -> Void)?) {
		
		var comment = Comment(post: post, text: text)
		post.comments.append(comment)
		
		dispatch_async(dispatch_get_main_queue()) {
			let nc = NSNotificationCenter.defaultCenter()
			nc.postNotificationName(PostController.PostCommentsChangedNotification, object: post)
		}
		
		cloudKitManager.saveRecord(CKRecord(comment)) { (record, error) in
			defer { completion?(comment) }
			guard let record = record else { return }
			comment.cloudKitRecordID = record.recordID
		}
	}
	
	
	// MARK: - Helper Fetches
	
	private func recordsOfType(type: String) -> [CloudKitSyncable] {
		switch type {
		case "Post":
			return posts.flatMap { $0 as CloudKitSyncable }
		case "Comment":
			return comments.flatMap { $0 as CloudKitSyncable }
		default:
			return []
		}
	}
	
	func syncedRecords(type: String) -> [CloudKitSyncable] {
		return recordsOfType(type).filter { $0.isSynced }
	}
	
	func unsyncedRecords(type: String) -> [CloudKitSyncable] {
		return recordsOfType(type).filter { !$0.isSynced }
	}
	
	// MARK: - Sync
	
	func performFullSync(completion: (() -> Void)? = nil) {
		
		guard !isSyncing else {
			completion?()
			return
		}
		
		isSyncing = true
		
		pushChangesToCloudKit { (success) in
			
			self.fetchNewRecords(Post.typeKey) {
				
				self.fetchNewRecords(Comment.typeKey) {
					
					self.isSyncing = false
					
					completion?()
				}
			}
		}
		
	}
	
	func fetchNewRecords(type: String, completion: (() -> Void)?) {
		
		var referencesToExclude = [CKReference]()
		var predicate: NSPredicate!
		referencesToExclude = self.syncedRecords(type).flatMap({ $0.cloudKitReference })
		predicate = NSPredicate(format: "NOT(recordID IN %@)", argumentArray: [referencesToExclude])
		
		if referencesToExclude.isEmpty {
			predicate = NSPredicate(value: true)
		}
		
		cloudKitManager.fetchRecordsWithType(type, predicate: predicate, recordFetchedBlock: { (record) in
			
			switch type {
			case Post.typeKey:
				if let post = Post(record: record) {
					self.posts.append(post)
				}
			case Comment.typeKey:
				guard let postReference = record[Comment.postKey] as? CKReference,
					postIndex = self.posts.indexOf({ $0.cloudKitRecordID == postReference.recordID }),
					comment = Comment(record: record) else { return }
				self.posts[postIndex].comments.append(comment)
			default:
				return
			}
			
		}) { (records, error) in
			
			if let error = error {
				NSLog("Error fetching CloudKit records of type \(type): \(error)")
			}
			
			completion?()
		}
	}
	
	func pushChangesToCloudKit(completion: ((success: Bool, error: NSError?) -> Void)?) {
		
		let unsavedPosts = unsyncedRecords(Post.typeKey) as? [Post] ?? []
		let unsavedComments = unsyncedRecords(Comment.typeKey) as? [Comment] ?? []
		var unsavedObjectsByRecord = [CKRecord: CloudKitSyncable]()
		for post in unsavedPosts {
			let record = CKRecord(post)
			unsavedObjectsByRecord[record] = post
		}
		for comment in unsavedComments {
			let record = CKRecord(comment)
			unsavedObjectsByRecord[record] = comment
		}
		
		let unsavedRecords = unsavedPosts.map { CKRecord($0) } + unsavedComments.map { CKRecord($0) }
		
		cloudKitManager.saveRecords(unsavedRecords, perRecordCompletion: { (record, error) in
			
			guard let record = record else { return }
			unsavedObjectsByRecord[record]?.cloudKitRecordID = record.recordID
			
		}) { (records, error) in
			
			let success = records != nil
			completion?(success: success, error: error)
		}
	}
	
	
	// MARK: - Subscriptions
	
	func subscribeToNewPosts(completion: ((success: Bool, error: NSError?) -> Void)?) {
		
		let predicate = NSPredicate(value: true)
		
		cloudKitManager.subscribe(Post.typeKey, predicate: predicate, subscriptionID: "allPosts", contentAvailable: true, options: .FiresOnRecordCreation) { (subscription, error) in
			
			if let completion = completion {
				
				let success = subscription != nil
				completion(success: success, error: error)
			}
		}
	}
	
	func checkSubscriptionToPostComments(post: Post, completion: ((subscribed: Bool) -> Void)?) {
		
		guard let subscriptionID = post.cloudKitRecordID?.recordName else {
			completion?(subscribed: false)
			return
		}
		
		cloudKitManager.fetchSubscription(subscriptionID) { (subscription, error) in
			let subscribed = subscription != nil
			completion?(subscribed: subscribed)
		}
	}
	
	func addSubscriptionToPostComments(post: Post, alertBody: String?, completion: ((success: Bool, error: NSError?) -> Void)?) {
		
		guard let recordID = post.cloudKitRecordID else { fatalError("Unable to create CloudKit reference for subscription.") }
		
		let predicate = NSPredicate(format: "post == %@", argumentArray: [recordID])
		
		cloudKitManager.subscribe(Comment.typeKey, predicate: predicate, subscriptionID: recordID.recordName, contentAvailable: true, alertBody: alertBody, desiredKeys: [Comment.textKey, Comment.postKey], options: .FiresOnRecordCreation) { (subscription, error) in
			
			if let completion = completion {
				
				let success = subscription != nil
				completion(success: success, error: error)
			}
		}
	}
	
	func removeSubscriptionToPostComments(post: Post, completion: ((success: Bool, error: NSError?) -> Void)?) {
		
		guard let subscriptionID = post.cloudKitRecordID?.recordName else {
			completion?(success: true, error: nil)
			return
		}
		
		cloudKitManager.unsubscribe(subscriptionID) { (subscriptionID, error) in
			
			if let completion = completion {
				
				let success = subscriptionID != nil && error == nil
				completion(success: success, error: error)
			}
		}
	}
	
	func togglePostCommentSubscription(post: Post, completion: ((success: Bool, isSubscribed: Bool, error: NSError?) -> Void)?) {
		
		guard let subscriptionID = post.cloudKitRecordID?.recordName else {
			completion?(success: false, isSubscribed: false, error: nil)
			return
		}
		
		cloudKitManager.fetchSubscription(subscriptionID) { (subscription, error) in
			
			if subscription != nil {
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
	
	// MARK: - Properties
	
	let cloudKitManager: CloudKitManager
	
	var isSyncing: Bool = false
	
	var posts = [Post]() {
		didSet {
			dispatch_async(dispatch_get_main_queue()) {
				let nc = NSNotificationCenter.defaultCenter()
				nc.postNotificationName(PostController.PostsChangedNotification, object: self)
			}
		}
	}
	var sortedPosts: [Post] {
		return posts.sort { return $0.timestamp.compare($1.timestamp) == .OrderedAscending }
	}
	var comments: [Comment] {
		return posts.flatMap { $0.comments }
	}
	
}