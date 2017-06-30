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
		
		// Buttons
		let favButton = UIButton(type: .custom)
		favButton.setImage(#imageLiteral(resourceName: "heart"), for: .normal)
		let commentsButton = UIButton(type: .custom)
		commentsButton.setImage(#imageLiteral(resourceName: "discussion"), for: .normal)
		let shareButton = UIButton(type: .custom)
		shareButton.setImage(#imageLiteral(resourceName: "share"), for: .normal)
		
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
		
		// Caption
		let captionLabel = UILabel()
		captionLabel.font = .appCommentFont
		captionLabel.textColor = .appSlateGrey
		
		// Main stack view
		let mainStackView = UIStackView(arrangedSubviews: [imageView, bottomStackView, captionLabel])
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
			timestampLabel.text = ""
			return
		}
		postImageView.image = post.photo
		timestampLabel.text = timestampFormatter.string(from: Date().timeIntervalSince(post.timestamp))
		captionLabel.text = post.comments.first?.text
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
