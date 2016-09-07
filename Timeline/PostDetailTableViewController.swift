//
//  PostDetailTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 40
		
		if let post = post {
			updateWithPost(post)
		}
		
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(postCommentsChanged(_:)), name: PostController.PostCommentsChangedNotification, object: nil)
	}
	
	func updateWithPost(post: Post) {
		guard isViewLoaded() else { return }
		
		imageView.image = post.photo
		tableView.reloadData()
		PostController.sharedController.checkSubscriptionToPostComments(post) { (subscribed) in
			
			dispatch_async(dispatch_get_main_queue(), {
				self.followPostButton.title = subscribed ? "Unfollow Post" : "Follow Post"
			})
		}
	}
	
	// MARK: - Notifications
	
	func postCommentsChanged(notification: NSNotification) {
		guard let notificationPost = notification.object as? Post,
			post = post
			where notificationPost === post else { return } // Not our post
		updateWithPost(post)
	}
	
	// MARK: - Table view data source
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return post?.comments.count ?? 0
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCellWithIdentifier("commentCell", forIndexPath: indexPath)
		guard let post = post else { return cell }
		let comment = post.comments[indexPath.row]
		
		cell.textLabel?.text = comment.text
		cell.detailTextLabel?.text = comment.cloudKitRecordID?.recordName
		
		return cell
	}
	
	
	// MARK: - Post Actions
	
	@IBAction func commentButtonTapped(sender: AnyObject) {
		
		presentCommentAlert()
	}
	
	@IBAction func shareButtonTapped(sender: AnyObject) {
		
		presentActivityViewController()
	}
	
	@IBAction func followPostButtonTapped(sender: AnyObject) {
		
		guard let post = post else { return }
		PostController.sharedController.togglePostCommentSubscription(post) { (success, isSubscribed, error) in
			
			self.updateWithPost(post)
		}
	}
	
	func presentCommentAlert() {
		
		let alertController = UIAlertController(title: "Add Comment", message: nil, preferredStyle: .Alert)
		
		alertController.addTextFieldWithConfigurationHandler { (textField) in
			
			textField.placeholder = "Nice shot!"
		}
		
		let addCommentAction = UIAlertAction(title: "Add Comment", style: .Default) { (action) in
			
			guard let commentText = alertController.textFields?.first?.text,
				let post = self.post else { return }
			
			PostController.sharedController.addCommentToPost(commentText, post: post, completion:nil)
		}
		alertController.addAction(addCommentAction)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
		alertController.addAction(cancelAction)
		
		presentViewController(alertController, animated: true, completion: nil)
	}
	
	func presentActivityViewController() {
		
		guard let photo = post?.photo,
			comment = post?.comments.first else { return }
		
		let text = comment.text
		let activityViewController = UIActivityViewController(activityItems: [photo, text], applicationActivities: nil)
		
		presentViewController(activityViewController, animated: true, completion: nil)
	}
	
	// MARK: Properties
	
	var post: Post? {
		didSet {
			if let post = post { updateWithPost(post) }
		}
	}
	
	@IBOutlet weak var followPostButton: UIBarButtonItem!
	@IBOutlet weak var imageView: UIImageView!
}
