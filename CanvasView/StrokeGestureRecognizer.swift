//
//  StrokeGestureRecognizer.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 26/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

let minQuandrance: CGFloat = 0.003
let defaultThickness: CGFloat = 2.0
let forceWeight: CGFloat = 0.33

class StrokeGestureRecognizer : UIGestureRecognizer {

    var trackedTouch: UITouch? = nil
    var outstandingVertices = [Vertex]()

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

        collect(trackedTouch!, with: event)
        state = .began

        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        assert(touches.count == 1)

        collect(touches.first!, with: event)
        state = .changed

        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        assert(touches.count == 1)

        collect(touches.first!, with: event)
        state = .ended

        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        assert(touches.count == 1)

        collect(touches.first!, with: event)
        state = .cancelled

        super.touchesCancelled(touches, with: event)
    }

    override func reset() {
        trackedTouch = nil

        super.reset()
    }

    func getAndClearOutstandingVertices() -> [Vertex] {
        let vertices = outstandingVertices
        outstandingVertices.removeAll(keepingCapacity: true)
        return vertices
    }

    func collect(_ touch: UITouch, with event: UIEvent) {
        let goodQuadrance = { (touch: UITouch) -> Bool in
            let prev = touch.precisePreviousLocation(in: self.view)
            let curr = touch.preciseLocation(in: self.view)
            let (dx, dy) = (curr.x - prev.x, curr.y - prev.y)
            let quadrance = dx * dx + dy * dy
            return quadrance >= minQuandrance
        }

        if let coalescedTouches = event.coalescedTouches(for: touch) {
            for ct in coalescedTouches {
                let vertex = Vertex(
                    location: touch.preciseLocation(in: view!),
                    thickness: defaultThickness + (ct.force - 1.0) * forceWeight)
                if goodQuadrance(ct) {
                    outstandingVertices.append(vertex)
                }
            }
        }
    }
}
