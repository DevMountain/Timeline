//
//  User.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/30/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import Foundation
import UIKit

struct User {
    
    private let displayNameKey = "displayName"
    private let profileImageKey = "profileImagePath"
    
    let displayName: String
    let profileImagePath: String
    
    var profileImage: UIImage? {
        
        guard let imageData = NSData(contentsOfFile: profileImagePath) else { return nil }
        
        return UIImage(data: imageData)
    }
    
    var dictionaryValue: [String: AnyObject] {
        
        let userDictionary = [
            displayNameKey: self.displayName,
            profileImageKey: self.profileImagePath
        ]
        
        return userDictionary
    }
    
    init(displayName: String, profileImagePath: String) {
        
        self.displayName = displayName
        self.profileImagePath = profileImagePath
    }
    
    init?(dictionary: [String: AnyObject]) {
        
        guard let displayName = dictionary[displayNameKey] as? String,
            let profileImagePath = dictionary[profileImageKey] as? String else { return nil }
        
        self.displayName = displayName
        self.profileImagePath = profileImagePath
    }
}