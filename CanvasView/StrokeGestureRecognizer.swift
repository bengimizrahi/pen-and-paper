//
//  StrokeGestureRecognizer.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 26/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class StrokeGestureRecognizer: UIGestureRecognizer {

    var activeStroke: Stroke? = nil
    var trackedTouch: UITouch? = nil

    func append(_ touch: UITouch, with event: UIEvent) {
        let vertex = Vertex(
              location: touch.preciseLocation(in: view!),
              force: touch.force,
              estimatedProperties: touch.estimatedProperties,
              estimatedPropertiesExpectingUpdates: touch.estimatedPropertiesExpectingUpdates)
        activeStroke!.add(vertex)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        let ignoreUntrackedTouches = {
            for t in touches {
                if t !== self.trackedTouch {
                    self.ignore(t, for: event)
                }
            }
        }

        guard state == .possible else {
            ignoreUntrackedTouches()
            return
        }

        trackedTouch = touches.first!
        ignoreUntrackedTouches()
        activeStroke = Stroke()
        append(trackedTouch!, with: event)
        state = .began

        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        assert(touches.count == 1)

        append(touches.first!, with: event)
        state = .changed

        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        assert(touches.count == 1)

        append(touches.first!, with: event)
        state = .ended

        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        assert(touches.count == 1)

        append(touches.first!, with: event)
        state = .cancelled

        super.touchesCancelled(touches, with: event)
    }

    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        super.touchesEstimatedPropertiesUpdated(touches)
    }

    override func reset() {
        activeStroke = nil
        trackedTouch = nil
        super.reset()
    }
}
