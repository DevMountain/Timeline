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
    let cloudKitManager: CloudKitManager
    
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
        
        self.cloudKitManager = CloudKitManager()
        
        fullSync()
    }
    
    func createPost(image: UIImage, caption: String, completion: (() -> Void)?) {
        
        guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
        
        let _ = Post(photo: data, caption: caption)
        
        save()
        
        if let completion = completion {
            completion()
        }
    }
    
    func addCommentToPost(text: String, post: Post, completion: ((success: Bool) -> Void)?) {
        
        let _ = Comment(post: post, text: text)
        
        save()
        
        if let completion = completion {
            completion(success: true)
        }
    }
    
    func fullSync() {
        
        // push any local records that aren't in cloudkit
        
        let insertedObjects = Array(Stack.sharedStack.managedObjectContext.insertedObjects)
        
        cloudKitManager.saveAllChanges(insertedObjects) { (records) in
            
            print("saved records: \(records)")
        }
        
        // fetch new records that aren't in the local store
        
        let lastSyncDate = (fetchedResultsController.fetchedObjects?.first as? Post)?.added ?? NSDate(timeIntervalSince1970: 0)
        
        cloudKitManager.fetchRecentRecords("Post", fromDate: lastSyncDate, toDate: NSDate(), completion: { (records, error) in
            
            guard let records = records else { print("No fetched records to create."); return }
            
            for record in records {
                
                let newPost = Post(record: record)
                self.save()
            }
        })
        
    }
    
    func save() {
        
        fullSync()
        
        do {
            try Stack.sharedStack.managedObjectContext.save()
        } catch {
            print("Error saving Managed Object Context. Error: \(error)")
        }
    }
}