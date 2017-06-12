//
//  PostCollectionViewCell.swift
//  Timeline
//
//  Created by Andrew Madsen on 6/11/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import UIKit

class PostCollectionViewCell: UICollectionViewCell {
	
	// MARK: Private
	
	private func updateViews() {
		postImageView?.image = post?.photo
	}
	
	
	// MARK: Properties
	
	var post: Post? {
		didSet {
			updateViews()
		}
	}
	
	@IBOutlet weak var postImageView: UIImageView!
    
}
