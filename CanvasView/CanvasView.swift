//
//  CanvasView.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 05/10/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

let minQuandrance: CGFloat = 0.003
let defaultThickness: CGFloat = 2.0
let forceWeight: CGFloat = 0.33

struct DrawingJob {
    var vertices = [Vertex]()
    var rect: CGRect? = nil

    mutating func append(_ vertex: Vertex) {
        vertices.append(vertex)
        let r2 = CGRect(origin: vertex.location, size: CGSize())
        if rect == nil {
            rect = r2
        } else {
            rect = rect!.union(r2)
        }
    }

    func valid() -> Bool {
        return rect != nil && vertices.count > 1
    }

    mutating func expand(_ job2: DrawingJob) {
        if vertices.isEmpty {
            self = job2
            return
        }

        vertices.append(contentsOf: job2.vertices)
        rect = rect!.union(job2.rect!)
    }

    func draw(context: CGContext) -> Vertex? {
        guard valid() else { return nil }

        var lastDrawnVertex: Vertex? = nil

        func beginStroke(_ vertex: Vertex) {
            print("v \(vertex.location)")
            context.beginPath()
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.setLineWidth(vertex.thickness)
            context.move(to: vertex.location)
            lastDrawnVertex = vertex
        }
        func continueStroke(_ vertex: Vertex) {
            print("_ \(vertex.location)")
            context.setLineWidth(vertex.thickness)
            context.addLine(to: vertex.location)
            lastDrawnVertex = vertex
        }
        func endStroke() {
            print("^")
            context.drawPath(using: .stroke)
        }

        UIColor.black.set()
        print("going to draw \(vertices.count) vertices : \n\t\(vertices)")
        for (idx, v) in vertices.enumerated() {
            if idx == 0 {
                beginStroke(v)
            } else if idx == vertices.count - 1 {
                continueStroke(v)
                endStroke()
            } else {
                switch v.type {
                case .down:
                    beginStroke(v)
                case .intermediate:
                    continueStroke(v)
                case .up:
                    continueStroke(v)
                    endStroke()
                }
            }
        }

        return lastDrawnVertex
    }
}

class CanvasView: UIView {

    var outstandingDrawingJob = DrawingJob()
    var lastDrawnVertex: Vertex? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isMultipleTouchEnabled = false
        self.clearsContextBeforeDrawing = false
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isMultipleTouchEnabled = false
        self.clearsContextBeforeDrawing = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        collect(touches.first!, with: event!, strokeStarted: true)
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        collect(touches.first!, with: event!)
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        collect(touches.first!, with: event!, strokeEnded: true)
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        collect(touches.first!, with: event!, strokeEnded: true)
        super.touchesCancelled(touches, with: event)
    }

    override func draw(_ rect: CGRect) {
        print("draw in: \(rect)")
        if outstandingDrawingJob.valid() { print("job: \(outstandingDrawingJob.rect!)") }

        if outstandingDrawingJob.valid() {
            let context = UIGraphicsGetCurrentContext()!
            let lastDrawnVertex = outstandingDrawingJob.draw(context: context)
            outstandingDrawingJob = DrawingJob()
            if let last = lastDrawnVertex {
                outstandingDrawingJob.append(last)
            }
        }
    }

    func collect(_ touch: UITouch, with event: UIEvent, strokeStarted: Bool = false, strokeEnded: Bool = false) {
        let goodQuadrance = { (touch: UITouch) -> Bool in
            let prev = touch.precisePreviousLocation(in: self)
            let curr = touch.preciseLocation(in: self)
            let (dx, dy) = (curr.x - prev.x, curr.y - prev.y)
            let quadrance = dx * dx + dy * dy
            return quadrance >= minQuandrance
        }

        var job = DrawingJob()

        if let coalescedTouches = event.coalescedTouches(for: touch) {
            for (idx, ct) in coalescedTouches.enumerated() {
                let type: VertexType
                if idx == 0 && strokeStarted {
                    type = .down
                } else if idx == coalescedTouches.count - 1 && strokeEnded {
                    type = .up
                } else {
                    type = .intermediate
                }
                if idx == 0 || idx == coalescedTouches.count - 1 || goodQuadrance(ct) {
                    let vertex = Vertex(
                        location: ct.preciseLocation(in: self),
                        thickness: defaultThickness + (ct.force - 1.0) * forceWeight,
                        type: type)
                    print("\(type) \(vertex.location)")
                    job.append(vertex)
                }
            }
        }
        outstandingDrawingJob.expand(job)
        if job.valid() {
            print("setNeedsDisplay(\(outstandingDrawingJob.rect!))")
            setNeedsDisplay(outstandingDrawingJob.rect!)
        }
    }
}
