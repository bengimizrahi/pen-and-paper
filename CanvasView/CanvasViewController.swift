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

    @IBOutlet weak var canvasView: CanvasView!

    var strokes: [Stroke] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func strokeUpdated(_ gestureRecognizer: StrokeGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            canvasView!.activeStroke = gestureRecognizer.activeStroke!
            canvasView!.setNeedsDisplayForActiveStroke()
            print("began")
        case .changed:
            canvasView!.activeStroke = gestureRecognizer.activeStroke!
            canvasView!.setNeedsDisplayForActiveStroke()
        case .ended:
            print("ended")
            canvasView!.setNeedsDisplayForActiveStroke()
            strokes.append(gestureRecognizer.activeStroke!)
            canvasView.strokes = strokes
        case .cancelled:
            print("cancelled")
        default:
            print("???")
        }
    }
}

