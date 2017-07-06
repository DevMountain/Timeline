//
//  PostActionHandler.swift
//  Timeline
//
//  Created by Andrew Madsen on 7/5/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import Foundation

@objc protocol PostActionHandler {
	func toggleFavorite(_ sender: Any)
	func addComment(_ sender: Any)
	func share(_ sender: Any)
}
