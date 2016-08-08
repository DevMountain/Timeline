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
		
		let postController = PostController.sharedController
		postController.performFullSync()
		
        completionHandler(UIBackgroundFetchResult.NewData)
    }
}

