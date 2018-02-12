//
//  AddPostTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class AddPostTableViewController: UITableViewController {
	
	// MARK: Actions
	
	@IBAction func addPostTapped(_ sender: AnyObject) {
		
		if let image = image,
			let caption = captionTextField.text {
			
			PostController.sharedController.createPostWith(image: image, caption: caption) { (_) in
				DispatchQueue.main.async {
					self.dismiss(animated: true, completion: nil)
				}
			}
			
		} else {
			
			DispatchQueue.main.async {
				let alertController = UIAlertController(title: "Missing Post Information", message: "Check your image and caption and try again.", preferredStyle: .alert)
				alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
				
				self.present(alertController, animated: true, completion: nil)
			}
		}
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		if segue.identifier == "embedPhotoSelect" {
			
			let embedViewController = segue.destination as? PhotoSelectViewController
			embedViewController?.delegate = self
		}
	}
	
	// MARK: Properties
	
	var image: UIImage?
	
	@IBOutlet weak var captionTextField: UITextField!
}

extension AddPostTableViewController: PhotoSelectViewControllerDelegate {
	
	func photoSelectViewControllerSelected(_ image: UIImage) {
		
		self.image = image
	}
}
