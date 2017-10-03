//
//  CanvasViewController.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 26/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

@IBDesignable
class CanvasViewController : UIViewController {

    @IBOutlet weak var canvasView: UIImageView!

    var strokes = [Stroke]()
    var unfinishedPainters = [Stroke.StrokePainter]()
    var activeStroke: Stroke

    required init?(coder aDecoder: NSCoder) {
        activeStroke = Stroke()
        unfinishedPainters.append(Stroke.StrokePainter(stroke: activeStroke))

        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let gestureRecognizer = StrokeGestureRecognizer()
        gestureRecognizer.addTarget(self, action: #selector(strokeUpdated(_:)))
        canvasView.addGestureRecognizer(gestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        assert(false)
    }

    @IBAction func strokeUpdated(_ gestureRecognizer: UIPanGestureRecognizer) {
        print("?")
//        let appendOutstandingVerticesToActiveStroke = {
//            let vertices = gestureRecognizer.getAndClearOutstandingVertices()
//            self.activeStroke.append(vertices)
//        }
//
//        switch gestureRecognizer.state {
//        case .possible:
//            return
//        case .began:
//            fallthrough
//        case .changed:
//            appendOutstandingVerticesToActiveStroke()
//            drawStrokes()
//        case .cancelled:
//            fallthrough
//        case .failed:
//            fallthrough
//        case .ended:
//            appendOutstandingVerticesToActiveStroke()
//            activeStroke = Stroke()
//            unfinishedPainters.append(Stroke.StrokePainter(stroke: activeStroke))
//            drawStrokes()
//        }
    }

    func drawStrokes() {
        guard !unfinishedPainters.isEmpty else { return }

        UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, 0.0)
        canvasView!.image?.draw(in: canvasView!.bounds)
        defer {
            canvasView!.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }

        guard let context = UIGraphicsGetCurrentContext() else { return }
        UIColor.black.set()

        var paintersToRemove = [Int]()
        for (i, p) in unfinishedPainters.enumerated() {
            if p.stroke.phase == .done { paintersToRemove.append(i) }
            p.draw(on: context)
        }
        for i in paintersToRemove { unfinishedPainters.remove(at: i) }
    }
}
