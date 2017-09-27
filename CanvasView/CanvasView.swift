//
//  CanvasView.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 26/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class CanvasView: UIView {

    var strokes: [Stroke]? {
        didSet {
            setNeedsDisplay()
        }
    }

    var activeStroke: Stroke? {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let drawStroke = { (stroke:Stroke) -> () in
            guard stroke.vertices.count > 0 else { return }
            context.beginPath()
            context.move(to: stroke.vertices.first!.location)
            for v in stroke.vertices[1...] {
                context.addLine(to: v.location)
            }
            context.drawPath(using: .stroke)
        }

        UIColor.black.set()

        if let activeStroke = activeStroke {
            drawStroke(activeStroke)
        }
        if let strokes = strokes {
            for s in strokes {
                drawStroke(s)
            }
        }
    }

}
