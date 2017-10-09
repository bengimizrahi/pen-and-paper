//
//  TestView.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 09/10/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit


class TestView: UIView {

    var bufferImage: UIImage? = nil

    func createBuffer(_ size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if bufferImage == nil {
            bufferImage = createBuffer(bounds.size)
        }
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()!
        bufferImage!.draw(in: bounds)
        UIColor.black.setFill()
        let t = touches.first!
        let c = t.location(in: self)
        let s: CGFloat = 5.0
        let r = CGRect(origin: CGPoint(x: c.x - s, y: c.y - s), size: CGSize(width: 2*s, height: 2*s))
        context.addEllipse(in: r)
        context.drawPath(using: .fill)
        if let img = UIGraphicsGetImageFromCurrentImageContext() {
            bufferImage! = img
        }
        UIGraphicsEndImageContext()
        setNeedsDisplay(r)
    }

    override func draw(_ rect: CGRect) {
        guard let _ = bufferImage else { return }

        let scaleFactor = UIScreen.main.scale
        let croppedImage = bufferImage!.cgImage!.cropping(to: rect.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)))!
        let context = UIGraphicsGetCurrentContext()!
        context.draw(croppedImage, in: rect)
    }

}
