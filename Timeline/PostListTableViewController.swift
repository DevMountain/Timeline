//
//  PostListTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController, UISearchResultsUpdating {

    var searchController: UISearchController?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setUpSearchController()
        
        requestFullSync()

        // hides search bar
        if tableView.numberOfRowsInSection(0) > 0 {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
        }
		
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(postsChanged(_:)), name: PostController.PostsChangedNotification, object: nil)
    }
    
    @IBAction func refreshControlActivated(sender: UIRefreshControl) {
        
        requestFullSync { 
            self.refreshControl?.endRefreshing()
        }
    }
    
    func requestFullSync(completion: (() -> Void)? = nil) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        PostController.sharedController.performFullSync {
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if let completion = completion {
                completion()
            }
        }
    }
	
	// MARK: - Notifications
	
	func postsChanged(notification: NSNotification) {
		tableView.reloadData()
	}
	
    // MARK: - Table view data source
	
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return PostController.sharedController.posts.count
    }
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
        guard let cell = tableView.dequeueReusableCellWithIdentifier("postCell", forIndexPath: indexPath) as? PostTableViewCell else { return PostTableViewCell() }
		
		let posts = PostController.sharedController.posts
		let post = posts[indexPath.row]
		
        cell.updateWithPost(post)
        
        return cell
    }
	
    
    // MARK: - Search Controller
    
    func setUpSearchController() {
        
        let resultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SearchResultsTableViewController")
        
        searchController = UISearchController(searchResultsController: resultsController)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.sizeToFit()
        searchController?.hidesNavigationBarDuringPresentation = true
        tableView.tableHeaderView = searchController?.searchBar
        
        definesPresentationContext = true
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        if let resultsViewController = searchController.searchResultsController as? SearchResultsTableViewController,
            searchTerm = searchController.searchBar.text?.lowercaseString {
			
			let posts = PostController.sharedController.posts
            resultsViewController.resultsArray = posts.filter({$0.matchesSearchTerm(searchTerm)})
            resultsViewController.tableView.reloadData()
        }
    }

    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toPostDetail" {
            
            if let detailViewController = segue.destinationViewController as? PostDetailTableViewController,
                selectedIndexPath = self.tableView.indexPathForSelectedRow {
				
				let posts = PostController.sharedController.posts
                detailViewController.post = posts[selectedIndexPath.row]
            }
        }
        
        if segue.identifier == "toPostDetailFromSearch" {
            if let detailViewController = segue.destinationViewController as? PostDetailTableViewController,
                let sender = sender as? PostTableViewCell,
                let selectedIndexPath = (searchController?.searchResultsController as? SearchResultsTableViewController)?.tableView.indexPathForCell(sender),
                let searchTerm = searchController?.searchBar.text?.lowercaseString {
				
				let posts = PostController.sharedController.posts.filter({ $0.matchesSearchTerm(searchTerm) })
                let post = posts[selectedIndexPath.row]
                
                detailViewController.post = post
            }
        }
    }
}
