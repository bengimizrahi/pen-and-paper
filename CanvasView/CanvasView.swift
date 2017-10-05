//
//  CanvasView.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 26/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class CanvasView: UIView {

    var strokes: [Stroke]? = nil
    var activeStroke: Stroke? = nil
    var cachedImage: UIImage? = nil
    var debugCount = 0

    override func draw(_ rect: CGRect) {
        debugCount += 1

        let _ = Measure(reportOnExit: true)

        let drawStroke = { (context: CGContext, stroke:Stroke) -> () in
            guard stroke.vertices.count > 0 else { return }
            if let l = stroke.lastDrawnVertex {
                guard l + 1 < stroke.vertices.count else { return }
            }

            context.beginPath()
            let lastDrawnVertex = stroke.lastDrawnVertex ?? 0
            context.move(to: stroke.vertices[lastDrawnVertex].location)
            var c = 0
            for v in stroke.vertices[(lastDrawnVertex + 1)...] {
                context.addLine(to: v.location)
                c += 1
            }
            context.drawPath(using: .stroke)
            stroke.lastDrawnVertex = stroke.vertices.count - 1
            print("c: \(c)")
        }


        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        guard let cacheContext = UIGraphicsGetCurrentContext() else { return }
        cachedImage?.draw(in: bounds)
        UIColor.black.set()
        if let activeStroke = activeStroke {
            drawStroke(cacheContext, activeStroke)
        }
        cachedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        cachedImage!.draw(in: bounds)
    }

    func setNeedsDisplayForActiveStroke() {
        if let frame = activeStroke?.frame() {
            setNeedsDisplay(frame)
        }
    }
}
