//
//  PostCellView.swift
//  Timeline
//
//  Created by Andrew Madsen on 06/30/17.
//  Copyright © 2017 DevMountain. All rights reserved.
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
		let imageView = UIImageView(frame: .zero)
		imageView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		
		// Buttons
		let favButton = UIButton(type: .custom)
		favButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
		favButton.addTarget(nil, action: #selector(PostActionHandler.toggleFavorite(_:)), for: .touchUpInside)
		let commentsButton = UIButton(type: .custom)
		commentsButton.setImage(#imageLiteral(resourceName: "discussion"), for: .normal)
		commentsButton.addTarget(nil, action: #selector(PostActionHandler.addComment(_:)), for: .touchUpInside)
		let shareButton = UIButton(type: .custom)
		shareButton.setImage(#imageLiteral(resourceName: "share"), for: .normal)
		shareButton.addTarget(nil, action: #selector(PostActionHandler.share(_:)), for: .touchUpInside)
		
		let buttonsStackView = UIStackView(arrangedSubviews: [favButton, commentsButton, shareButton])
		buttonsStackView.axis = .horizontal
		buttonsStackView.alignment = .fill
		buttonsStackView.distribution = .fillEqually
		buttonsStackView.spacing = 24.0
		
		// Timestamp label
		let timestampLabel = UILabel()
		timestampLabel.font = .appTimestampFont
		timestampLabel.textColor = .appPurpleyGrey
		let clockImageView = UIImageView(image: #imageLiteral(resourceName: "clock"))
		let timestampStackView = UIStackView(arrangedSubviews: [clockImageView, timestampLabel])
		timestampStackView.axis = .horizontal
		timestampStackView.alignment = .center
		timestampStackView.distribution = .fill
		timestampStackView.spacing = 4.0
		
		let spacingView = UIView()
		spacingView.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
		spacingView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
		
		let bottomStackView = UIStackView(arrangedSubviews: [buttonsStackView, spacingView, timestampStackView])
		bottomStackView.axis = .horizontal
		bottomStackView.alignment = .fill
		bottomStackView.distribution = .fill
		bottomStackView.layoutMargins = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)
		bottomStackView.isLayoutMarginsRelativeArrangement = true
		
		// Caption
		let captionLabel = UILabel()
		captionLabel.font = .appCommentFont
		captionLabel.textColor = .appSlateGrey
		captionLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .vertical)
		let captionStackView = UIStackView(arrangedSubviews: [captionLabel]) // Just to get margins
		captionStackView.isLayoutMarginsRelativeArrangement = true
		captionStackView.layoutMargins = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)
		
		// Main stack view
		let mainStackView = UIStackView(arrangedSubviews: [imageView, bottomStackView, captionStackView])
		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.axis = .vertical
		mainStackView.spacing = 8.0
		addSubview(mainStackView)
		
		self.leftAnchor.constraint(equalTo: mainStackView.leftAnchor, constant: -16.0).isActive = true
		self.rightAnchor.constraint(equalTo: mainStackView.rightAnchor, constant: 16.0).isActive = true
		self.topAnchor.constraint(equalTo: mainStackView.topAnchor, constant: -16.0).isActive = true
		self.bottomAnchor.constraint(equalTo: mainStackView.bottomAnchor, constant: 16.0).isActive = true
		
		// Set properties
		self.postImageView = imageView
		self.favoriteButton = favButton
		self.timestampLabel = timestampLabel
		self.captionLabel = captionLabel
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
	
	
	// MARK: Properties
	
	var post: Post? {
		didSet {
			updateViews()
		}
	}
	
    @IBOutlet weak var postImageView: UIImageView!
	@IBOutlet var favoriteButton: UIButton!
	@IBOutlet var timestampLabel: UILabel!
	@IBOutlet var captionLabel: UILabel!
	
	private lazy var timestampFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .brief
		formatter.maximumUnitCount = 1
		return formatter
	}()
}
