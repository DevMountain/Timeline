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
//    @IBOutlet weak var postImageViewHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateWithPost(post: Post) {
        
        postImageView.image = post.photo
        updateHeightConstraintForImage(post.photo)
    }
    
    func updateHeightConstraintForImage(image: UIImage?) {
        
        if let image = image {
            let imageWidth : CGFloat = self.contentView.frame.size.width
            let imageHeight: CGFloat = image.size.height / image.size.width * imageWidth
            
            let constraintConstant = imageHeight < 300 ? imageHeight : 300
            
//            postImageViewHeightConstraint.constant = constraintConstant
        }
    }
}