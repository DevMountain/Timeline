//
//  AppDelegate.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/24/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Request notification permissions
        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        return true
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        guard let notificationInfo = userInfo as? [String: NSObject] else { return }
        
        let queryNotification = CKQueryNotification(fromRemoteNotificationDictionary: notificationInfo)
        
        guard let recordID = queryNotification.recordID else { print("No Record ID available from CKQueryNotification."); return }
        
        let cloudKitManager = PostController.sharedController.cloudKitManager
        
        cloudKitManager.fetchRecordWithID(recordID) { (record, error) in
            
            guard let record = record else { print("Unable to fetch CKRecord from Record ID"); return }
            
            switch record.recordType {
                
            case Post.typeKey:
                let _ = Post(record: record)
            case Comment.typeKey:
                let _ = Comment(record: record)
            default:
                return
            }
        }
        
        completionHandler(UIBackgroundFetchResult.NewData)
    }
}

