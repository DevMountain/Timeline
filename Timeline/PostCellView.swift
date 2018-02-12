//
//  PostCellView.swift
//  Timeline
//
//  Created by Andrew R Madsen on 7/28/17.
//  Copyright © 2017 Andrew R Madsen. All rights reserved.
//

import UIKit

class PostCellView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .white
        createSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.backgroundColor = .white
        createSubviews()
    }
    
    // MARK: Private
    
    private func createSubviews() {
        
        postImageView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        let heightConstraint = postImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 450.0)
        heightConstraint.isActive = true
        heightConstraint.priority = .required
        postImageView.contentMode = .scaleAspectFill
        postImageView.clipsToBounds = true
        
        // Buttons
        favoriteButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
        favoriteButton.addTarget(nil, action: #selector(PostActionHandler.toggleFavorite(_:)), for: .touchUpInside)
        commentsButton.setImage(#imageLiteral(resourceName: "discussion"), for: .normal)
        commentsButton.addTarget(nil, action: #selector(PostActionHandler.addComment(_:)), for: .touchUpInside)
        shareButton.setImage(#imageLiteral(resourceName: "share"), for: .normal)
        shareButton.addTarget(nil, action: #selector(PostActionHandler.share(_:)), for: .touchUpInside)
        
        let buttonsStackView = UIStackView(arrangedSubviews: [favoriteButton, commentsButton, shareButton])
        buttonsStackView.axis = .horizontal
        buttonsStackView.alignment = .fill
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = 24.0
        
        // Timestamp label
        timestampLabel.font = .appTimestampFont
        timestampLabel.textColor = .appPurpleyGrey
        timestampLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        timestampLabel.setContentHuggingPriority(UILayoutPriority(UILayoutPriority.defaultLow.rawValue + 1.0), for: .horizontal)
        let clockImageView = UIImageView(image: #imageLiteral(resourceName: "clock"))
        let timestampStackView = UIStackView(arrangedSubviews: [clockImageView, timestampLabel])
        timestampStackView.axis = .horizontal
        timestampStackView.alignment = .center
        timestampStackView.distribution = .fill
        timestampStackView.spacing = 4.0
        
        let spacingView = UIView()
        spacingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacingView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let bottomStackView = UIStackView(arrangedSubviews: [buttonsStackView, spacingView, timestampStackView])
        bottomStackView.axis = .horizontal
        bottomStackView.alignment = .fill
        bottomStackView.distribution = .fill
        bottomStackView.layoutMargins = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)
        bottomStackView.isLayoutMarginsRelativeArrangement = true
        
        captionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        captionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        captionLabel.font = .appCommentFont
        captionLabel.textColor = .appSlateGrey
        
        let captionStackView = UIStackView(arrangedSubviews: [captionLabel]) // Just to get margins
        captionStackView.isLayoutMarginsRelativeArrangement = true
        captionStackView.layoutMargins = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)
        
        let mainStackView = UIStackView(arrangedSubviews: [postImageView, bottomStackView, captionStackView])
        mainStackView.axis = .vertical
        mainStackView.alignment = .fill
        mainStackView.distribution = .fill
        mainStackView.spacing = 8.0
        
        addSubview(mainStackView)
        let views = ["mainStackView": mainStackView]
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "|[mainStackView]|", options: [], metrics: nil, views: views)
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[mainStackView]-|", options: [], metrics: nil, views: views)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints(hConstraints)
        addConstraints(vConstraints)
    }
    
    private func updateViews() {
        guard let post = post else {
            postImageView.image = nil
            captionLabel.isHidden = true
            timestampLabel.text = ""
            favoriteButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
            return
        }
        postImageView.image = post.photo
        let favImage = post.isFavorite ? #imageLiteral(resourceName: "filledHeart") : #imageLiteral(resourceName: "heart")
        favoriteButton.setImage(favImage, for: .normal)
        timestampLabel.text = timestampFormatter.string(from: Date().timeIntervalSince(post.timestamp))
        if let caption = post.comments.first?.text {
            captionLabel.isHidden = false
            captionLabel.text = caption
        } else {
            captionLabel.isHidden = true
        }
    }
    
    // Properties
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    let postImageView = UIImageView(frame: .zero)
    let favoriteButton = UIButton(type: .custom)
    let commentsButton = UIButton(type: .custom)
    let shareButton = UIButton(type: .custom)
    let timestampLabel = UILabel(frame: .zero)
    let captionLabel = UILabel(frame: .zero)
    
    private lazy var timestampFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.maximumUnitCount = 1
        return formatter
    }()
}
