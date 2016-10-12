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
		
		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(postCommentsChanged(_:)), name: PostController.PostCommentsChangedNotification, object: nil)
	}
	
	func updateWithPost(_ post: Post) {
		guard isViewLoaded else { return }
		
		imageView.image = post.photo
		tableView.reloadData()
		PostController.sharedController.checkSubscriptionToPostComments(post) { (subscribed) in
			
			DispatchQueue.main.async(execute: {
				self.followPostButton.title = subscribed ? "Unfollow Post" : "Follow Post"
			})
		}
	}
	
	// MARK: - Notifications
	
	func postCommentsChanged(_ notification: Notification) {
		guard let notificationPost = notification.object as? Post,
			let post = post
			, notificationPost === post else { return } // Not our post
		updateWithPost(post)
	}
	
	// MARK: - Table view data source
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return post?.comments.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
		guard let post = post else { return cell }
		let comment = post.comments[indexPath.row]
		
		cell.textLabel?.text = comment.text
		cell.detailTextLabel?.text = comment.cloudKitRecordID?.recordName
		
		return cell
	}
	
	
	// MARK: - Post Actions
	
	@IBAction func commentButtonTapped(_ sender: AnyObject) {
		
		presentCommentAlert()
	}
	
	@IBAction func shareButtonTapped(_ sender: AnyObject) {
		
		presentActivityViewController()
	}
	
	@IBAction func followPostButtonTapped(_ sender: AnyObject) {
		
		guard let post = post else { return }
		PostController.sharedController.togglePostCommentSubscription(post) { (success, isSubscribed, error) in
			
			self.updateWithPost(post)
		}
	}
	
	func presentCommentAlert() {
		
		let alertController = UIAlertController(title: "Add Comment", message: nil, preferredStyle: .alert)
		
		alertController.addTextField { (textField) in
			
			textField.placeholder = "Nice shot!"
		}
		
		let addCommentAction = UIAlertAction(title: "Add Comment", style: .default) { (action) in
			
			guard let commentText = alertController.textFields?.first?.text,
				let post = self.post else { return }
			
			PostController.sharedController.addCommentToPost(commentText, post: post, completion:nil)
		}
		alertController.addAction(addCommentAction)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alertController.addAction(cancelAction)
		
		present(alertController, animated: true, completion: nil)
	}
	
	func presentActivityViewController() {
		
		guard let photo = post?.photo,
			let comment = post?.comments.first else { return }
		
		let text = comment.text
		let activityViewController = UIActivityViewController(activityItems: [photo, text], applicationActivities: nil)
		
		present(activityViewController, animated: true, completion: nil)
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
