//
//  PostTableViewCell.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/27/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {
	
	// MARK: Private
	
	private func updateViews() {
		postImageView.image = post?.photo
	}
	
	
	// MARK: Properties
	
	var post: Post? {
		didSet {
			updateViews()
		}
	}
	
    @IBOutlet weak var postImageView: UIImageView!
}
