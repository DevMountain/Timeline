/*
//
//  SearchTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//
//  Abstract: Lists latest public results from CloudKit. Filters by caption, hashtag, or username when user searches. Objects are loaded into a Managed Object Context, but are discarded after the search session has finished.
//  Alternative: Only displays users to follow. If user taps another use to follow, it loads a PostList with that user's posts.
*/


import UIKit

class SearchTableViewController: UITableViewController, UISearchResultsUpdating {

    var searchController: UISearchController?
    
    var posts: [Post]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        posts = PostController.sharedController.fetchedResultsController.fetchedObjects as? [Post]
        
        setUpSearchController()
    }
    
    override func viewDidAppear(animated: Bool) {
        posts = PostController.sharedController.fetchedResultsController.fetchedObjects as? [Post]
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return posts?.count ?? 0
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("postCell", forIndexPath: indexPath) as? PostTableViewCell,
            let post = posts?[indexPath.row] else { return UITableViewCell() }
        
        cell.updateWithPost(post)
        cell.textLabel?.text = "\(post.added)"
        
        return cell
    }
    
    // MARK: - Search Controller
    
    func setUpSearchController() {
        
        let resultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SearchResultsTableViewController")
        
        searchController = UISearchController(searchResultsController: resultsController)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.sizeToFit()
        searchController?.hidesNavigationBarDuringPresentation = false
        tableView.tableHeaderView = searchController?.searchBar
        
        definesPresentationContext = true
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        let searchTerm = searchController.searchBar.text!.lowercaseString
        
        if let resultsViewController = searchController.searchResultsController as? SearchResultsTableViewController,
            let posts = posts {
            
            resultsViewController.resultsArray = posts.filter({$0.matchesSearchTerm(searchTerm)})
            resultsViewController.tableView.reloadData()
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        
    }
}
