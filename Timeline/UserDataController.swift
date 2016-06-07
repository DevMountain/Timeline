//
//  UserController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/30/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import UIKit

class UserDataController {
    
    var currentUserData: UserData?
    
    static let sharedController = UserDataController()
    
    private let userDataKey = "userData"
    
    init() {
        
        let userDictionary = NSUserDefaults.standardUserDefaults().objectForKey(userDataKey) as? [String: AnyObject] ?? [:]
        currentUser = UserData(dictionary: userDictionary)
    }
    
    func updateUser(displayName: String, profileImage: UIImage) {
        
        // fetch current user userdata record
        // update it
        // save it
    }
    
    func fetchCurrentUserData(completion: (() -> Void)?) {
        
        // fetch current user record id
        // fetch userdata record with current user data
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}