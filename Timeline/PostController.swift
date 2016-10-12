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
	
	func createPost(_ image: UIImage, caption: String, completion: ((Post) -> Void)?) {
		guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
		
		let post = Post(photoData: data)
		posts.append(post)
		let captionComment = addCommentToPost(caption, post: post)
	
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

			self.addSubscriptionToPostComments(post, alertBody: "Someone commented on your post! 👍") { (success, error) in
				if let error = error {
					print("Unable to save comment subscription: \(error.localizedDescription)")
				}
			}
		}
	}
	
	@discardableResult func addCommentToPost(_ text: String, post: Post, completion: ((Comment) -> Void)? = nil) -> Comment {
		
		let comment = Comment(post: post, text: text)
		post.comments.append(comment)
		
		self.cloudKitManager.saveRecord(CKRecord(comment)) { (record, error) in
			if let error = error {
				NSLog("Error saving new comment to CloudKit: \(error)")
				return
			}
			comment.cloudKitRecordID = record?.recordID
			completion?(comment)
		}
		
		DispatchQueue.main.async {
			let nc = NotificationCenter.default
			nc.post(name: Notification.Name(rawValue: PostController.PostCommentsChangedNotification), object: post)
		}
		
		return comment
	}
	
	
	// MARK: - Helper Fetches
	
	fileprivate func recordsOfType(_ type: String) -> [CloudKitSyncable] {
		switch type {
		case "Post":
			return posts.flatMap { $0 as CloudKitSyncable }
		case "Comment":
			return comments.flatMap { $0 as CloudKitSyncable }
		default:
			return []
		}
	}
	
	func syncedRecords(_ type: String) -> [CloudKitSyncable] {
		return recordsOfType(type).filter { $0.isSynced }
	}
	
	func unsyncedRecords(_ type: String) -> [CloudKitSyncable] {
		return recordsOfType(type).filter { !$0.isSynced }
	}
	
	// MARK: - Sync
	
	func performFullSync(_ completion: (() -> Void)? = nil) {
		
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
	
	func fetchNewRecords(_ type: String, completion: (() -> Void)? = nil) {
		
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
					let postIndex = self.posts.index(where: { $0.cloudKitRecordID == postReference.recordID }),
					let comment = Comment(record: record) else { return }
				let post = self.posts[postIndex]
				post.comments.append(comment)
				comment.post = post
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
	
	func pushChangesToCloudKit(_ completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
		
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
		
		let unsavedRecords = Array(unsavedObjectsByRecord.keys)
		
		cloudKitManager.saveRecords(unsavedRecords, perRecordCompletion: { (record, error) in
			
			guard let record = record else { return }
			unsavedObjectsByRecord[record]?.cloudKitRecordID = record.recordID
			
		}) { (records, error) in
			
			let success = records != nil
			completion?(success, error)
		}
	}
	
	
	// MARK: - Subscriptions
	
	func subscribeToNewPosts(_ completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
		
		let predicate = NSPredicate(value: true)
		
		cloudKitManager.subscribe(Post.typeKey, predicate: predicate, subscriptionID: "allPosts", contentAvailable: true, options: .firesOnRecordCreation) { (subscription, error) in
			
			if let completion = completion {
				
				let success = subscription != nil
				completion(success, error)
			}
		}
	}
	
	func checkSubscriptionToPostComments(_ post: Post, completion: ((_ subscribed: Bool) -> Void)?) {
		
		guard let subscriptionID = post.cloudKitRecordID?.recordName else {
			completion?(false)
			return
		}
		
		cloudKitManager.fetchSubscription(subscriptionID) { (subscription, error) in
			let subscribed = subscription != nil
			completion?(subscribed)
		}
	}
	
	func addSubscriptionToPostComments(_ post: Post, alertBody: String?, completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
		
		guard let recordID = post.cloudKitRecordID else { fatalError("Unable to create CloudKit reference for subscription.") }
		
		let predicate = NSPredicate(format: "post == %@", argumentArray: [recordID])
		
		cloudKitManager.subscribe(Comment.typeKey, predicate: predicate, subscriptionID: recordID.recordName, contentAvailable: true, alertBody: alertBody, desiredKeys: [Comment.textKey, Comment.postKey], options: .firesOnRecordCreation) { (subscription, error) in
			
			if let completion = completion {
				
				let success = subscription != nil
				completion(success, error)
			}
		}
	}
	
	func removeSubscriptionToPostComments(_ post: Post, completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
		
		guard let subscriptionID = post.cloudKitRecordID?.recordName else {
			completion?(true, nil)
			return
		}
		
		cloudKitManager.unsubscribe(subscriptionID) { (subscriptionID, error) in
			
			if let completion = completion {
				
				let success = subscriptionID != nil && error == nil
				completion(success, error)
			}
		}
	}
	
	func togglePostCommentSubscription(_ post: Post, completion: ((_ success: Bool, _ isSubscribed: Bool, _ error: Error?) -> Void)?) {
		
		guard let subscriptionID = post.cloudKitRecordID?.recordName else {
			completion?(false, false, nil)
			return
		}
		
		cloudKitManager.fetchSubscription(subscriptionID) { (subscription, error) in
			
			if subscription != nil {
				self.removeSubscriptionToPostComments(post, completion: { (success, error) in
					
					if let completion = completion {
						completion(success, false, error)
					}
				})
			} else {
				self.addSubscriptionToPostComments(post, alertBody: "Someone commented on a post you follow! 👍", completion: { (success, error) in
					
					if let completion = completion {
						completion(true, true, error)
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
			DispatchQueue.main.async {
				let nc = NotificationCenter.default
				nc.post(name: Notification.Name(rawValue: PostController.PostsChangedNotification), object: self)
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
