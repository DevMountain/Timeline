//
//  RoundImageView.swift
//  Timeline
//
//  Created by Andrew R Madsen on 8/7/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import UIKit

class RoundImageView: UIImageView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
//        layer.cornerRadius = bounds.width/2.0
//        layer.masksToBounds = true
    }
    
    override var frame: CGRect {
        didSet {
//            layer.cornerRadius = bounds.width/2.0
//            layer.masksToBounds = true
        }
    }
}

//class RoundImageView: UIView {
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        commonInit()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        commonInit()
//    }
//
//    private func commonInit() {
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(imageView)
//        imageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
//        imageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
//        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
//        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
//    }
//
//    var image: UIImage? {
//        didSet {
//            imageView.image = image
//        }
//    }
//
//    private let imageView = UIImageView()
//}
//
//fileprivate class RoundMaskView: UIView {
//    override func draw(_ rect: CGRect) {
//
//        let minDimension = min(bounds.width, bounds.height)
//        let square = CGRect(x: bounds.midX - minDimension / 2.0,
//                            y: bounds.midY - minDimension / 2.0,
//                            width: minDimension,
//                            height: minDimension)
//        let rectangle = UIBezierPath(rect: bounds)
//        let circle = UIBezierPath(ovalIn: square)
//        rectable.subt
//        circle.
//    }
//}
