//
//  PostController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CoreData

class PostController {
    
    static let sharedController = PostController()
    
    let fetchedResultsController: NSFetchedResultsController
    
    init() {
        
        let request = NSFetchRequest(entityName: "Post")
        request.returnsObjectsAsFaults = false
        let dateSortDescription = NSSortDescriptor(key: "added", ascending: false)
        request.sortDescriptors = [dateSortDescription]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: Stack.sharedStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Unable to perform fetch request: \(error.localizedDescription)")
        }
    }
    
    func createPost(image: UIImage, caption: String, completion: (() -> Void)?) {
        
        guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
        
        let _ = Post(photo: data, caption: caption)
        
        saveAllChanges()
        
        if let completion = completion {
            completion()
        }
    }
    
    func addCommentToPost(text: String, post: Post, completion: ((success: Bool) -> Void)?) {
        
        let _ = Comment(post: post, text: text)
        
        saveAllChanges()
        
        if let completion = completion {
            completion(success: true)
        }
    }
    
    func saveAllChanges() {
    
        do {
            try Stack.sharedStack.managedObjectContext.save()
        } catch {
            print("Error saving Managed Object Context. Items not saved.")
        }
    }
}