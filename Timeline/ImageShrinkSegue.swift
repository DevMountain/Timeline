//
//  ImageShrinkSegue.swift
//  Timeline
//
//  Created by Andrew R Madsen on 8/7/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import UIKit

protocol PostImageDisplaying {
    var photoView: UIImageView { get }
    var viewController: UIViewController { get }
}

// TODO: Don't need this anymore in Swift 4
extension PostImageDisplaying where Self: UIViewController {
    var viewController: UIViewController {
        return self
    }
}

class ImageShrinkSegue: UIStoryboardSegue {
    
    override func perform() {
        guard let sourceVC = source as? PostImageDisplaying,
            let destinationVC = destination as? PostImageDisplaying else {
                super.perform()
                return
        }
        
        sourceVC.viewController.present(destinationVC.viewController, animated: true, completion: nil)
    }

}
