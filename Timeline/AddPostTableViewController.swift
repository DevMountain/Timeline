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
    
    @IBAction func addPostTapped(sender: AnyObject) {
        
        if let image = image,
            let caption = captionTextField.text {
            
            PostController.sharedController.createPost(image, caption: caption, completion: {
                
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            
        } else {
            
            let alertController = UIAlertController(title: "Missing Post Information", message: "Check your image and caption and try again.", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
            
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
    
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedPhotoSelect" {
            
            let embedViewController = segue.destinationViewController as? PhotoSelectViewController
            embedViewController?.delegate = self
        }
    }
}

extension AddPostTableViewController: PhotoSelectViewControllerDelegate {
    
    func photoSelectViewControllerSelected(image: UIImage) {
        
        self.image = image
    }
}