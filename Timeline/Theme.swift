//
//  Theme.swift
//  Timeline
//
//  Created by Andrew Madsen on 6/28/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import UIKit

// Color palette

extension UIColor {
	class var appWhite: UIColor {
		return UIColor(white: 255.0 / 255.0, alpha: 1.0)
	}
	
	class var appSlateGrey: UIColor {
		return UIColor.purple//(red: 105.0 / 255.0, green: 111.0 / 255.0, blue: 114.0 / 255.0, alpha: 1.0)
	}
	
	class var appBlack: UIColor {
		return UIColor(white: 0.0, alpha: 1.0)
	}
	
	class var appPurpleyGrey: UIColor {
		return UIColor(red: 143.0 / 255.0, green: 142.0 / 255.0, blue: 148.0 / 255.0, alpha: 1.0)
	}
	
	class var appWhiteTwo: UIColor {
		return UIColor(white: 251.0 / 255.0, alpha: 1.0)
	}
	
	class var appWarmGrey: UIColor {
		return UIColor(white: 146.0 / 255.0, alpha: 1.0)
	}
	
	class var appCoolGrey: UIColor {
		return UIColor(red: 164.0 / 255.0, green: 170.0 / 255.0, blue: 179.0 / 255.0, alpha: 1.0)
	}
	
	class var appLipstick: UIColor {
		return UIColor(red: 234.0 / 255.0, green: 56.0 / 255.0, blue: 77.0 / 255.0, alpha: 1.0)
	}
	
	class var appPaleGrey: UIColor {
		return UIColor(red: 239.0 / 255.0, green: 239.0 / 255.0, blue: 244.0 / 255.0, alpha: 1.0)
	}
	
	class var appOrangeRed: UIColor {
		return UIColor(red: 254.0 / 255.0, green: 56.0 / 255.0, blue: 36.0 / 255.0, alpha: 1.0)
	}
}

// Text styles

extension UIFont {
	static var appNavigationButtonLeftFont: UIFont {
		return UIFont.systemFont(ofSize: 5.67, weight: UIFontWeightRegular)
	}
	
	static var appCommentFont: UIFont {
		return UIFont.systemFont(ofSize: 4.67, weight: UIFontWeightRegular)
	}
	
	static var appActionSheetDescriptionFont: UIFont {
		return UIFont.systemFont(ofSize: 4.33, weight: UIFontWeightRegular)
	}
	
	static var appTabBarTextFont: UIFont {
		return UIFont.systemFont(ofSize: 3.33, weight: UIFontWeightRegular)
	}
	
	static var timelineTitleFont: UIFont {
		return UIFont(name: "ScriptoramaTradeshowJF", size: 30.0)!
	}
}
