//
//  AddPostTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class AddPostTableViewController: UITableViewController {
	
	var image: UIImage?
	
	@IBOutlet weak var captionTextField: UITextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
	}
	
	@IBAction func addPostTapped(_ sender: AnyObject) {
		
		if let image = image,
			let caption = captionTextField.text {
			
			PostController.sharedController.createPost(image, caption: caption) { (_) in
				self.dismiss(animated: true, completion: nil)
			}
			
		} else {
			
			let alertController = UIAlertController(title: "Missing Post Information", message: "Check your image and caption and try again.", preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
			
			present(alertController, animated: true, completion: nil)
		}
	}
	
	@IBAction func cancelButtonTapped(_ sender: AnyObject) {
		
		dismiss(animated: true, completion: nil)
	}
	
	// MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		if segue.identifier == "embedPhotoSelect" {
			
			let embedViewController = segue.destination as? PhotoSelectViewController
			embedViewController?.delegate = self
		}
	}
}

extension AddPostTableViewController: PhotoSelectViewControllerDelegate {
	
	func photoSelectViewControllerSelected(_ image: UIImage) {
		
		self.image = image
	}
}
