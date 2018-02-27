//
//  AppDelegate.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/24/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Request notification permissions
		let unc = UNUserNotificationCenter.current()
		unc.requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
			if let error = error {
				NSLog("Error requesting authorization for notifications: \(error)")
				return
			}
		}
		
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		
		PostController.sharedController.fetchPosts()
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

