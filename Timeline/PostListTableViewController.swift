//
//  PostListTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController, UISearchResultsUpdating {
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		setUpSearchController()
		
		refreshPosts()
		
		// hides search bar
		if tableView.numberOfRows(inSection: 0) > 0 {
			tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
		}
		
		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(postsChanged(_:)), name: PostController.PostsChangedNotification, object: nil)
	}
	
	// MARK: Actions
	
	@IBAction func refreshControlActivated(_ sender: UIRefreshControl) {
		
		refreshPosts {
			DispatchQueue.main.async {
				self.refreshControl?.endRefreshing()
			}
		}
	}
	
	// MARK: Private
	
	private func refreshPosts(_ completion: (() -> Void)? = nil) {
        
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		
        PostController.sharedController.fetchPosts {
			
			DispatchQueue.main.async {
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
			}
			
			completion?()
		}
	}
	
	// MARK: - UITableViewDataSource
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return PostController.sharedController.posts.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as? PostTableViewCell else { return PostTableViewCell() }
		
		let posts = PostController.sharedController.posts
		cell.post = posts[indexPath.row]
		
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
	
	@objc func postsChanged(_ notification: Notification) {
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

