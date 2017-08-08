//
//  ImageShrinkSegue.swift
//  Timeline
//
//  Created by Andrew R Madsen on 8/7/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import UIKit
import QuartzCore

// MARK: - PostImageDisplaying

protocol PostImageDisplaying {
    var photoView: UIImageView! { get }
}

// MARK: - ImageShrinkSegue

class ImageShrinkSegue: UIStoryboardSegue {
    
    override func perform() {
        destination.view.`self`()
        source.view.`self`()
        animator.destinationPhotoView = (destination as! PostImageDisplaying).photoView
        animator.sourcePhotoView = (source as! PostImageDisplaying).photoView
        destination.transitioningDelegate = animator
        source.present(destination, animated: true, completion: nil)
    }
    
    private let animator = ImageShrinkTransitionAnimator()
}

// MARK: - ImageShrinkTransitionAnimator

class ImageShrinkTransitionAnimator: NSObject, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    // MARK: UIViewControllerAnimatedTransitioning
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let toVC = transitionContext.viewController(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        
        guard let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to) else {
                return
        }
        
        let toViewEndFrame = transitionContext.finalFrame(for: toVC)
        containerView.addSubview(toView)
        toView.frame = toViewEndFrame
        toView.alpha = 0.0
        let imageViewInitialFrame = containerView.convert(sourcePhotoView.bounds, from: sourcePhotoView)
        let roundImageView = UIImageView(frame: imageViewInitialFrame)
        roundImageView.contentMode = .scaleAspectFill
        roundImageView.image = sourcePhotoView.image
        roundImageView.clipsToBounds = true
        containerView.addSubview(roundImageView)
        self.sourcePhotoView.alpha = 0.0
        self.destinationPhotoView.alpha = 0.0
        
        // Animate
        let duration = self.transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, delay: 0, options: [], animations: {
            // FIXME: This shouldn't be necessary anymore in iOS11
            let roundingAnimation = CABasicAnimation(keyPath: "cornerRadius")
            roundingAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            let endRadius: CGFloat = 50.0
            roundingAnimation.fromValue = 0
            roundingAnimation.toValue = endRadius
            roundImageView.layer.add(roundingAnimation, forKey: "cornerRadius")
            roundImageView.layer.cornerRadius = endRadius
            roundImageView.frame = containerView.convert(self.destinationPhotoView.bounds, from: self.destinationPhotoView)
            toView.alpha = 1.0
        }) { (success) in
            
            fromView.alpha = 1.0
            self.sourcePhotoView.alpha = 1.0
            roundImageView.removeFromSuperview()
            self.destinationPhotoView.alpha = 1.0
            
            transitionContext.completeTransition(success)
        }
    }
    
    // MARK: Properties
    
    var destinationPhotoView: UIImageView!
    var sourcePhotoView: UIImageView!
}
