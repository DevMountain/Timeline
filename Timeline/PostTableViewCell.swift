//
//  PostTableViewCell.swift
//  Timeline
//
//  Created by Andrew Madsen on 6/30/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
	
		let cellView = PostCellView(frame: bounds)
		cellView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		cellView.translatesAutoresizingMaskIntoConstraints = true
		contentView.addSubview(cellView)
		self.cellView = cellView
    }
	
	private var cellView: PostCellView!
	
	var post: Post? {
		get { return cellView.post }
		set { cellView.post = newValue }
	}
}
