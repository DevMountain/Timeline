//
//  UserController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/30/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import UIKit

class UserController {
    
    var currentUser: User?
    
    static let sharedController = UserController()
    
    private let userDataKey = "userData"
    
    init() {
        
        let userDictionary = NSUserDefaults.standardUserDefaults().objectForKey(userDataKey) as? [String: AnyObject] ?? [:]
        currentUser = User(dictionary: userDictionary)
    }
    
    func updateUser(displayName: String, profileImage: UIImage) {
                
        guard let imageData = UIImageJPEGRepresentation(profileImage, 0.8) else { fatalError("Unable to serialize profile image to NSData.") }
        
        let filePath = getDocumentsDirectory().stringByAppendingPathComponent("profileImage.jpg")
        imageData.writeToFile(filePath, atomically: true)
        
        let newUser = User(displayName: displayName, profileImagePath: filePath)
        
        currentUser = newUser
        
        NSUserDefaults.standardUserDefaults().setObject(newUser.dictionaryValue, forKey: userDataKey)
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}