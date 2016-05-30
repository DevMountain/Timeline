//
//  AccountSetupTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class AccountSetupTableViewController: UITableViewController {

    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var photoSelectChildView: UIView!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func confirmButtonTapped(sender: AnyObject) {
        
        if let image = image, let text = displayNameField.text {
            
            UserController.sharedController.updateUser(text, profileImage: image)
            
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            
            let alertController = UIAlertController(title: "Missing Profile Information", message: "Check your display name and profile image and try again.", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
            
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "embedPhotoSelect" {
            
            let embedViewController = segue.destinationViewController as? PhotoSelectViewController
            embedViewController?.delegate = self
        }
    }
}

extension AccountSetupTableViewController: PhotoSelectViewControllerDelegate {
    
    func photoSelectViewControllerSelected(image: UIImage) {
        
        self.image = image
    }
}