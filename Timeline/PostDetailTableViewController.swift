//
//  PostDetailTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData

class PostDetailTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var post: Post?
    
    var fetchedResultsController: NSFetchedResultsController?
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40
        
        if let post = post {
            
            updateWithPost(post)
        }
        
        setUpFetchedResultsController()
    }
    
    func updateWithPost(post: Post) {
        
        imageView.image = post.photo
    }
    
    func setUpFetchedResultsController() {
        
        guard let post = post else { fatalError("Unable to use Post to set up fetched results controller.") }
        
        let request = NSFetchRequest(entityName: "Comment")
        let predicate = NSPredicate(format: "post == %@", argumentArray: [post])
        let dateSortDescription = NSSortDescriptor(key: "timestamp", ascending: true)
        
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        request.sortDescriptors = [dateSortDescription]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: Stack.sharedStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController?.performFetch()
        } catch let error as NSError {
            print("Unable to perform fetch request: \(error.localizedDescription)")
        }
        
        fetchedResultsController?.delegate = self
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        guard let sections = fetchedResultsController?.sections else { return 1 }
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let sections = fetchedResultsController?.sections else { return 0 }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("commentCell", forIndexPath: indexPath)
        
        if let comment = fetchedResultsController?.objectAtIndexPath(indexPath) as? Comment {
            
            cell.textLabel?.text = comment.text
            cell.detailTextLabel?.text = comment.recordName
        }
        
        return cell
    }
    
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        case .Insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
        case .Move:
            guard let indexPath = indexPath,
                newIndexPath = newIndexPath else {return}
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
        case .Update:
            guard let indexPath = indexPath else {return}
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
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
        
        guard let photo = post?.photo,
            let comment = post?.comments?.firstObject as? Comment,
            let text = comment.text else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [photo, text], applicationActivities: nil)
        
        presentViewController(activityViewController, animated: true, completion: nil)
    }

}
