//
//  CanvasViewController.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 26/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

@IBDesignable
class CanvasViewController: UIViewController {

    @IBOutlet weak var canvasView: UIImageView!

    var strokes: [Stroke] = []
    var activeStroke: Stroke? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView!.layer.drawsAsynchronously = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        assert(false)
    }

    @IBAction func strokeUpdated(_ gestureRecognizer: StrokeGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            draw(stroke: gestureRecognizer.activeStroke!)
            activeStroke = gestureRecognizer.activeStroke!
        case .changed:
            draw(stroke: activeStroke!)
        case .cancelled:
            fallthrough
        case .ended:
            draw(stroke: activeStroke!)
            strokes.append(activeStroke!)
        default:
            print("???")
        }
    }

    func draw(stroke: Stroke) {
        guard stroke.vertices.count > 0 else { return }
        if let l = stroke.lastDrawnVertex {
            guard l + 1 < stroke.vertices.count else { return }
        }

        let drawStroke = { (context: CGContext, stroke: Stroke) in
            context.beginPath()
            context.setLineCap(.round)
            let lastDrawnVertex = stroke.lastDrawnVertex ?? 0
            context.move(to: stroke.vertices[lastDrawnVertex].location)
            for v in stroke.vertices[(lastDrawnVertex + 1)...] {
                context.setLineWidth(v.thickness)
                context.addLine(to: v.location)
            }
            context.drawPath(using: .stroke)
            stroke.lastDrawnVertex = stroke.vertices.count - 1
        }

        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, 0.0)
        canvasView!.image?.draw(in: canvasView!.bounds)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        UIColor.black.set()
        if let activeStroke = activeStroke {
            drawStroke(context, activeStroke)
        }
        canvasView!.image = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
    }
}

