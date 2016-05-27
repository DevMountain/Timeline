//
//  PostDetailTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {
    
    var post: Post?
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40
        
        if let post = post {
            
            updateWithPost(post)
        }
    }
    
    func updateWithPost(post: Post) {
        
        imageView.image = post.photo
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return post?.comments?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("commentCell", forIndexPath: indexPath)
        
        if let comments = post?.comments,
            let comment = comments[indexPath.row] as? Comment {
            
            cell.textLabel?.text = comment.text
        }
        
        return cell
    }
    
    // MARK: - Post Actions
    
    @IBAction func commentButtonTapped(sender: AnyObject) {
        
        presentCommentAlert()
    }
    
    @IBAction func shareButtonTapped(sender: AnyObject) {
        
        presentActivityViewController()
    }
    
    @IBAction func followUserButtonTapped(sender: AnyObject) {
        
    }
    
    func presentCommentAlert() {
        
        let alertController = UIAlertController(title: "Add Comment", message: nil, preferredStyle: .Alert)
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            
            textField.placeholder = "Nice shot!"
        }
        
        let addCommentAction = UIAlertAction(title: "Add Comment", style: .Default) { (action) in
            
            guard let commentText = alertController.textFields?.first?.text,
                let post = self.post else { return }
            
            PostController.sharedController.addCommentToPost(commentText, post: post, completion: { (success) in
                
                self.tableView.reloadData()
            })
        }
        alertController.addAction(addCommentAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func presentActivityViewController() {
        
        guard let post = post else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [post], applicationActivities: nil)
        
        presentViewController(activityViewController, animated: true, completion: nil)
    }

}
