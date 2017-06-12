//
//  PostCollectionViewController.swift
//  Timeline
//
//  Created by Andrew Madsen on 6/11/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import UIKit

private let reuseIdentifier = "postCell"

class PostCollectionViewController: UIViewController, UICollectionViewDataSource, UISearchResultsUpdating {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUpSearchController()
		
		requestFullSync()
		
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refreshControlActivated(_:)), for: .valueChanged)
		collectionView.refreshControl = refreshControl
		
		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(postsChanged(_:)), name: PostController.PostsChangedNotification, object: nil)
	}
	
	// MARK: Actions
	
	@IBAction func refreshControlActivated(_ sender: UIRefreshControl) {
		requestFullSync {
			DispatchQueue.main.async {
				self.collectionView.refreshControl?.endRefreshing()
			}
		}
	}
	
	// MARK: Private
	
	private func requestFullSync(_ completion: @escaping (() -> Void) = {}) {
		
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		
		PostController.sharedController.performFullSync {
			
			DispatchQueue.main.async {
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
			}
			completion()
		}
	}
	
	// MARK: UICollectionViewDataSource
	
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return PostController.sharedController.posts.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? PostCollectionViewCell else {
			fatalError()
		}
		
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
		if let searchBar = searchController?.searchBar {
			headerView.addSubview(searchBar)
			searchBar.leftAnchor.constraint(equalTo: headerView.leftAnchor).isActive = true
			searchBar.rightAnchor.constraint(equalTo: headerView.rightAnchor).isActive = true
			searchBar.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
			searchBar.bottomAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
		}
		
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
		collectionView.reloadData()
	}
	
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "toPostDetail" {
			
			if let detailViewController = segue.destination as? PostDetailTableViewController,
				let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first {
				
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
	
	@IBOutlet var headerView: UIView!
	@IBOutlet var collectionView: UICollectionView!
	
	var searchController: UISearchController?
}
