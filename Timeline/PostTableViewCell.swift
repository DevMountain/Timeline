//
//  PostTableViewCell.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/27/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var postImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateWithPost(post: Post) {
        
        postImageView.image = post.photo
    }
}