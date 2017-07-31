//
//  PostTableViewCell.swift
//  AutosizingTest
//
//  Created by Andrew R Madsen on 7/27/17.
//  Copyright © 2017 Andrew R Madsen. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    private func commonInit() {
        self.backgroundColor = .white
        createSubviews()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func createSubviews() {
        
        contentView.addSubview(postCellView)
        let views = ["postCellView": postCellView]
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[postCellView]|", options: [], metrics: nil, views: views)
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[postCellView]-4-|", options: [], metrics: nil, views: views)
        postCellView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addConstraints(hConstraints)
        contentView.addConstraints(vConstraints)
    }
    
    var post: Post? {
        didSet {
            postCellView.post = post
        }
    }
    
    let postCellView = PostCellView(frame: .zero)
}
