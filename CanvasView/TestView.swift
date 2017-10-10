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
    var counter = 0

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
        let _ = Measure { print("touchesMoved: \($0)") }
        if bufferImage == nil || counter == 0 {
            bufferImage = createBuffer(bounds.size)
        }

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()!
        bufferImage!.draw(in: bounds)
        UIColor.black.setFill()
        var rr: CGRect? = nil
        //var darr = [CGPoint]()
        for ct in event!.coalescedTouches(for: touches.first!)! {
            let c = ct.preciseLocation(in: self)
            //darr.append(c)
            let s: CGFloat = 5.0
            let r = CGRect(origin: CGPoint(x: c.x - s, y: c.y - s), size: CGSize(width: 2*s, height: 2*s))
            context.addEllipse(in: r)
            context.drawPath(using: .fill)
            rr = (rr == nil) ? r : rr?.union(r)
        }
        //print(darr)
        if let img = UIGraphicsGetImageFromCurrentImageContext() {
            bufferImage! = img
        }
        UIGraphicsEndImageContext()
        if counter == 0 {
            setNeedsDisplay()
        } else {
            setNeedsDisplay(rr!)
        }
        counter = (counter + 1)
    }

    override func draw(_ rect: CGRect) {
        let _ = Measure { print("draw: \($0)") }

        guard let _ = bufferImage else { return }

        let scaleFactor = UIScreen.main.scale
        let scaledRect = rect.applying(CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
        let croppedImage = bufferImage!.cgImage!.cropping(to: scaledRect)!
        let img = UIImage(cgImage: croppedImage)
        img.draw(in: rect)
    }

}
