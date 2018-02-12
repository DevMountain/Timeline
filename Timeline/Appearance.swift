//
//  Appearance.swift
//  Timeline
//
//  Created by Andrew Madsen on 6/28/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import UIKit

enum Appearance {
	
	static func configure() {
		UIApplication.shared.statusBarStyle = .lightContent
		
		UINavigationBar.appearance().isTranslucent = false
		UINavigationBar.appearance().tintColor = .appWhite
		UINavigationBar.appearance().barTintColor = .appLipstick
		
		// Navigation bar title text
		UINavigationBar.appearance().titleTextAttributes = [
			.foregroundColor : UIColor.appWhite,
			.font : UIFont.timelineTitleFont
		]
		
		UILabel.appearance().textColor = .appSlateGrey
	}
	
}
