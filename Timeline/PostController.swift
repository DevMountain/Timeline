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
        
        saveContext()
        
        if let completion = completion {
            completion()
        }
    }
    
    func addCommentToPost(text: String, post: Post, completion: ((success: Bool) -> Void)?) {
        
        let _ = Comment(post: post, text: text)
        
        saveContext()
        
        if let completion = completion {
            completion(success: true)
        }
    }
    
    // MARK: - Helper Fetches
    
    func postWithName(name: String) -> Post? {
        
        let fetchRequest = NSFetchRequest(entityName: "Post")
        let predicate = NSPredicate(format: "recordName == %@", argumentArray: [name])
        fetchRequest.predicate = predicate
        
        // TODO: Sometimes this works... sometimes it doesn't
        
        let result = (try? Stack.sharedStack.managedObjectContext.executeFetchRequest(fetchRequest) as? [Post]) ?? nil
        
        return result?.first
    }
    
    // MARK: - Sync Code
    
    func fullSync() {
        
        // push any local records that aren't in cloudkit
        
        pushChangesToCloudKit { (success) in
            
            self.fetchChangesFromCloudKit({ (succes) in
                
                print("sync finished")
                NSUserDefaults.standardUserDefaults().setObject(NSDate(), forKey: "lastSync")
            })
        }
        
    }
    
    func fetchChangesFromCloudKit(completion: (succes: Bool) -> Void) {
        
        let lastSyncDate = NSUserDefaults.standardUserDefaults().objectForKey("lastSync") as? NSDate ?? NSDate(timeIntervalSince1970: 0.0)
        
        let group = dispatch_group_create()
        
        dispatch_group_enter(group)

        self.cloudKitManager.fetchRecentRecords("Post", fromDate: lastSyncDate, toDate: NSDate(), completion: { (records, error) in
            
            guard let records = records else { print("No fetched Post records to create."); return }
            
            for record in records {
                
                let newPost = Post(record: record)
                self.saveContext()
    
                print("Fetched record: \(record) and initialized post: \(newPost)")
            }
            
            dispatch_group_leave(group)
        })
        
        dispatch_group_enter(group)
        
        self.cloudKitManager.fetchRecentRecords("Comment", fromDate: lastSyncDate, toDate: NSDate(), completion: { (records, error) in
            
            guard let records = records else { print("No fetched Comment records to create."); return }
            
            for commentRecord in records {
                
                let newComment = Comment(record: commentRecord)
                self.saveContext()
                
                print("Fetched record: \(commentRecord) and initialized comment: \(newComment)")
            }
            
            dispatch_group_leave(group)
        })
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { 
            
            // TODO: Address unpaired comments
            
            completion(succes: true)
        }

    }
    
    func pushChangesToCloudKit(completion: ((success: Bool) -> Void)?) {
        
        let insertedObjects = Array(Stack.sharedStack.managedObjectContext.insertedObjects)
        
        cloudKitManager.saveAllChanges(insertedObjects) { (records) in
            
            print("changes pushed to cloudkit")
            
            if let records = records {
                
                for record in records {
                    
                    let matchingObject = self.postWithName(record.recordID.recordName)
                    matchingObject?.updateWithRecord(record)
                    self.saveContext(false)
                }
            }
            
            if let completion = completion {
                completion(success: true)
            }
        }
    }
    
    func saveContext(pushChanges: Bool = true) {
        
        if pushChanges {
            pushChangesToCloudKit(nil)
        }
        
        do {
            try Stack.sharedStack.managedObjectContext.save()
        } catch {
            print("Error saving Managed Object Context. Error: \(error)")
        }
    }
}