//
//  PostListTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController, UISearchResultsUpdating, PostActionHandler {
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		setupAppearance()
		setUpSearchController()
		requestFullSync()
		
		// hides search bar
		if tableView.numberOfRows(inSection: 0) > 0 {
			tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
		}
		
		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(postsChanged(_:)), name: PostController.PostsChangedNotification, object: nil)
	}
	
	// MARK: Actions
	
	@IBAction func refreshControlActivated(_ sender: UIRefreshControl) {
		
		requestFullSync {
			DispatchQueue.main.async {
				self.refreshControl?.endRefreshing()
			}
		}
	}
	
	@IBAction func toggleFavorite(_ sender: Any) {
		guard let button = sender as? UIButton,
			let (post, indexPath) = post(forTableSubview: button) else { return }
		
		let controller = PostController.sharedController
		controller.checkSubscriptionTo(commentsForPost: post) { (subscribed) in
			let reloadRow = {
				DispatchQueue.main.async {
					self.tableView.reloadRows(at: [indexPath], with: .none)
				}
			}
			if subscribed {
				reloadRow()
				controller.removeSubscriptionTo(commentsForPost: post) { (_, _) in
					reloadRow()
				}
			} else {
				reloadRow()
				controller.addSubscriptionTo(commentsForPost: post, alertBody: "Someone commented on your post! 👍") { (_, _) in
					reloadRow()
				}
			}
		}
	}
	
	@IBAction func addComment(_ sender: Any) {
		guard let button = sender as? UIButton,
			let _ = post(forTableSubview: button)?.post else { return }
		
		// FIXME: Implement commenting here
	}
	
	@IBAction func share(_ sender: Any) {
		guard let button = sender as? UIButton,
			let post = post(forTableSubview: button)?.post,
			let photo = post.photo,
			let comment = post.comments.first else { return }
		
		let text = comment.text
		let activityViewController = UIActivityViewController(activityItems: [photo, text], applicationActivities: nil)
		
		present(activityViewController, animated: true, completion: nil)
	}
	
	// MARK: Private
	
	private func setupAppearance() {
		let gradientView = UIView(frame: tableView.bounds)
		let gradientLayer = CAGradientLayer()
		gradientLayer.frame = gradientView.bounds
		let startColor = UIColor(red: 232.0/255.0, green: 244.0/255.0, blue: 250.0/255.0, alpha: 1.0)
		let endColor = UIColor(red: 200.0/255.0, green: 209.0/255.0, blue: 221.0/255.0, alpha: 1.0)
		gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
		gradientLayer.locations = [0.0, 1.0]
		gradientView.layer.insertSublayer(gradientLayer, at: 0)
		tableView.backgroundView = gradientView
		
		tableView.separatorStyle = .none
	}
	
	private func requestFullSync(_ completion: (() -> Void)? = nil) {
		
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		
		PostController.sharedController.performFullSync {
			
			DispatchQueue.main.async {
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
			}
			
			completion?()
		}
	}
	
	private func post(forTableSubview view: UIView) -> (post: Post, indexPath: IndexPath)? {
		let point = view.convert(CGPoint.zero, to: tableView)
		guard let indexPath = tableView.indexPathForRow(at: point) else { return nil }
		return (PostController.sharedController.posts[indexPath.row], indexPath)
	}
	
	// MARK: - UITableViewDataSource
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return PostController.sharedController.posts.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as? PostTableViewCell else { return PostTableViewCell() }
		
		let posts = PostController.sharedController.posts
		let post = posts[indexPath.row]
		cell.post = post
		
		if !post.hasCheckedFavoriteStatus { // Update isFavorited property
			let controller = PostController.sharedController
			controller.checkSubscriptionTo(commentsForPost: post) { (_) in
				DispatchQueue.main.async { self.tableView.reloadRows(at: [indexPath], with: .none) }
			}
		}
		
		return cell
	}
	
	
	// MARK: Search Controller
	
	private func setUpSearchController() {
		
		let resultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchResultsTableViewController")
		
		searchController = UISearchController(searchResultsController: resultsController)
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.sizeToFit()
		searchController?.hidesNavigationBarDuringPresentation = true
		tableView.tableHeaderView = searchController?.searchBar
		
		definesPresentationContext = true
	}
	
	func updateSearchResults(for searchController: UISearchController) {
		
		if let resultsViewController = searchController.searchResultsController as? SearchResultsTableViewController,
			let searchTerm = searchController.searchBar.text?.lowercased() {
			
			let posts = PostController.sharedController.posts
			let filteredPosts = posts.filter { $0.matches(searchTerm: searchTerm) }.map { $0 as SearchableRecord }
			resultsViewController.resultsArray = filteredPosts
			resultsViewController.tableView.reloadData()
		}
	}
	
	// MARK: Notifications
	
	func postsChanged(_ notification: Notification) {
		tableView.reloadData()
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		if segue.identifier == "toPostDetail" {
			
			if let detailViewController = segue.destination as? PostDetailTableViewController,
				let selectedIndexPath = self.tableView.indexPathForSelectedRow {
				
				let posts = PostController.sharedController.posts
				detailViewController.post = posts[selectedIndexPath.row]
			}
		}
		
		if segue.identifier == "toPostDetailFromSearch" {
			if let detailViewController = segue.destination as? PostDetailTableViewController,
				let sender = sender as? PostTableViewCell,
				let selectedIndexPath = (searchController?.searchResultsController as? SearchResultsTableViewController)?.tableView.indexPath(for: sender),
				let searchTerm = searchController?.searchBar.text?.lowercased() {
				
				let posts = PostController.sharedController.posts.filter({ $0.matches(searchTerm: searchTerm) })
				let post = posts[selectedIndexPath.row]
				
				detailViewController.post = post
			}
		}
	}
	
	// MARK: Properties
	
	var searchController: UISearchController?
}

