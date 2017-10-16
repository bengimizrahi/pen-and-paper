//
//  CanvasView.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 10/10/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

protocol DrawDelegate {
    func draw(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> CGRect
    func redraw()
}

class CirclePainter : DrawDelegate {

    var points = [CGPoint]()

    func drawCircle(at rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.addEllipse(in: rect)
        context.drawPath(using: .fill)
    }

    func circleRect(at point: CGPoint) -> CGRect {
        let s: CGFloat = 5.0
        let r = CGRect(origin: CGPoint(x: point.x - s, y: point.y - s),
                       size: CGSize(width: 2 * s, height: 2 * s))
        return r
    }

    func draw(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> CGRect {
        UIColor.black.setFill()
        var rr: CGRect? = nil
        for ct in event.coalescedTouches(for: touch)! {
            let c = ct.preciseLocation(in: view)
            let r = circleRect(at: c)
            drawCircle(at: r)
            points.append(c)
            rr = (rr == nil) ? r : rr?.union(r)
        }
        return rr!
    }

    func redraw() {
        for p in points {
            drawCircle(at: circleRect(at: p))
        }
    }
}

class DefaultPainter : DrawDelegate {

    var strokeCollection = [Stroke]()
    var currentStroke: Stroke? = nil
    var startingVertex = Vertex(location: CGPoint(),
                                thickness: CGFloat())

    func draw(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> CGRect {
        assert(touch.phase == .began || touch.phase == .moved)

        var maxThicknessNoted: CGFloat = 0.0

        // start a bezier path
        UIColor.black.set()
        let path = UIBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        var it = event.coalescedTouches(for: touch)!.makeIterator()

        // if touch began, use the first vertex as the starting vertex
        if touch.phase == .began {
            let firstTouch = it.next()!
            let thickness = forceToThickness(force: firstTouch.force)
            maxThicknessNoted = max(maxThicknessNoted, thickness)
            startingVertex = Vertex(location: firstTouch.preciseLocation(in: view),
                                    thickness: thickness)

            if let completedStroke = currentStroke {
                strokeCollection.append(completedStroke)
            }
            currentStroke = Stroke()
        }

        // move to the start vertex
        path.move(to: startingVertex.location)
        path.lineWidth = defaultThickness
        currentStroke!.append(vertex: startingVertex)
        var dirtyRect = CGRect(origin: startingVertex.location, size: CGSize())

        // add the rest of the vertices to the path
        while let ct = it.next() {
            let thickness = forceToThickness(force: ct.force)
            maxThicknessNoted = max(maxThicknessNoted, thickness)
            let vertex = Vertex(location: ct.preciseLocation(in: view),
                                thickness: thickness)
            path.addLine(to: vertex.location)
            path.move(to: vertex.location)
            //path.lineWidth = defaultThickness
            currentStroke!.append(vertex: vertex)
            dirtyRect = dirtyRect.union(CGRect(origin: vertex.location, size: CGSize()))
        }
        path.stroke()

        let lastTouch = event.coalescedTouches(for: touch)!.last!
        startingVertex = Vertex(location: lastTouch.location(in: view),
                                thickness: forceToThickness(force: lastTouch.force))

        return dirtyRect.insetBy(dx: -maxThicknessNoted / 2.0, dy: -maxThicknessNoted / 2.0)
    }

    func redraw() {
        UIColor.black.set()

        var c = 0
        func drawStroke(stroke: Stroke) {
            let path = UIBezierPath()
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            assert(stroke.vertices.count > 0)

            let firstVertex = stroke.vertices.first!
            path.move(to: firstVertex.location)
            path.lineWidth = defaultThickness
            for vertex in stroke.vertices[1...] {
                path.addLine(to: vertex.location)
                path.move(to: vertex.location)
//                path.lineWidth = vertex.thickness
            }
            path.stroke()

            c += 1
            print("# of strokes drawn: \(c)")
        }

        for stroke in strokeCollection {
            drawStroke(stroke: stroke)
        }
        drawStroke(stroke: currentStroke!)
    }
}

class DrawingAgent {

    static let kOffscreenImageResizingAmount: CGFloat = 100.0

    var bounds: CGRect
    var canvas: UIImage

    var dirtyRect: CGRect? = nil
    var drawDelegate = DefaultPainter()

    init(bounds: CGRect) {
        self.bounds = bounds

        // create an empty canvas
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
    }

    func resize(dirtyRect: CGRect) {
        let resizingTriggeringRect = { () -> CGRect in
            var rect = bounds
            rect.origin.y = bounds.height - CanvasView.kResizingTriggeringMargin
            return rect
        }()
        guard dirtyRect.intersects(resizingTriggeringRect) else { return }

        let newBounds = { () -> CGRect in
            var b = self.bounds
            b.size.height += DrawingAgent.kOffscreenImageResizingAmount
            return b
        }()
        bounds = newBounds

        UIGraphicsBeginImageContextWithOptions(newBounds.size, false, 0.0)
        drawDelegate.redraw()
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
    }

    func expandDirtyRect(with rect: CGRect) {
        dirtyRect = (dirtyRect == nil) ? rect : dirtyRect!.union(rect)
    }

    func handleTouch(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> CGRect {
        // handle only .began and .moved
        assert(touch.phase == .began || touch.phase == .moved)

        // start with a new canvas
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)

        // first draw the old canvas into the new one
        canvas.draw(in: bounds)

        // call the draw delegate
        let rect = drawDelegate.draw(touch, event, view)
        expandDirtyRect(with: rect)

        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return dirtyRect!
    }

    func drawRect(_ rect: CGRect) {
        let scale = UIScreen.main.scale
        let canvasRectInPoints = CGRect(origin: CGPoint(), size: canvas.size)
        let rectToDrawInPoints = canvasRectInPoints.intersection(rect)
        let rectToDrawInPixels = rectToDrawInPoints.applying(CGAffineTransform(scaleX: scale, y: scale))

        if let subCgImage = canvas.cgImage!.cropping(to: rectToDrawInPixels) {
            let subimage = UIImage(cgImage: subCgImage)
            subimage.draw(in: rectToDrawInPoints)
        }
        dirtyRect = nil
    }
}

class CanvasView: UIView {

    static let kResizingTriggeringMargin: CGFloat = 20.0

    class StripeLayer: CATiledLayer, CALayerDelegate {
        func draw(_ layer: CALayer, in ctx: CGContext) {
            let rect = ctx.boundingBoxOfClipPath
            let i = (rect.origin.x / 10.0).truncatingRemainder(dividingBy: 1.0)
            let red = CGFloat(i)
            let j = (rect.origin.y / 10.0).truncatingRemainder(dividingBy: 1.0)
            let green = CGFloat(j)
            let k = (rect.origin.y / 20.0).truncatingRemainder(dividingBy: 1.0)
            let blue = CGFloat(k)
            ctx.setFillColor(red: red, green: green, blue: blue, alpha: 0.5)
            ctx.fill(rect)
        }
    }

    class CanvasLayer: CALayer, CALayerDelegate {
        weak var drawingAgent: DrawingAgent? = nil

        func draw(_ layer: CALayer, in ctx: CGContext) {
            guard let agent = drawingAgent else { return }

            print("draw: ")

            UIGraphicsPushContext(ctx)
            agent.drawRect(ctx.boundingBoxOfClipPath)
            UIGraphicsPopContext()
        }
    }

    var stripeLayer: StripeLayer
    var canvasLayer: CanvasLayer
    lazy var drawingAgent: DrawingAgent = { [unowned self] in
        return DrawingAgent(bounds: bounds)
    }()

    required init?(coder aDecoder: NSCoder) {
        stripeLayer = StripeLayer()
        canvasLayer = CanvasLayer()

        super.init(coder: aDecoder)

        canvasLayer.drawingAgent = drawingAgent

        let scale = UIScreen.main.scale
        stripeLayer.contentsScale = scale
        canvasLayer.contentsScale = scale
        canvasLayer.contentsGravity = kCAGravityBottom

        stripeLayer.frame = bounds
        canvasLayer.frame = bounds

        stripeLayer.tileSize = CGSize(width: 100.0, height: 100.0)

        stripeLayer.delegate = stripeLayer
        canvasLayer.delegate = canvasLayer

        layer.addSublayer(stripeLayer)
        layer.addSublayer(canvasLayer)
    }

    deinit {
        stripeLayer.delegate = nil
        canvasLayer.delegate = nil
    }

    func goodQuadrance(touch: UITouch) -> Bool {
        if touch.phase == .began { return true }
        let prev = touch.precisePreviousLocation(in: self)
        let curr = touch.preciseLocation(in: self)
        let (dx, dy) = (curr.x - prev.x, curr.y - prev.y)
        let quadrance = dx * dx + dy * dy
        return quadrance >= minQuandrance
    }

    func resize(_ dirtyRect: CGRect) {
        let resizingTriggeringRect = { () -> CGRect in
            var rect = bounds
            rect.origin.y = bounds.height - CanvasView.kResizingTriggeringMargin
            return rect
        }()
        guard dirtyRect.intersects(resizingTriggeringRect) else { return }

        let startTime = Date()
        self.drawingAgent.resize(dirtyRect: dirtyRect)
        let endTime = Date()
        let diff = endTime.timeIntervalSince(startTime)
        print("delta T: \(diff)")

        let newHeight = dirtyRect.origin.y + dirtyRect.height + CanvasView.kResizingTriggeringMargin
        let newSize = CGSize(width: bounds.width, height: newHeight)

        frame.size = newSize
        canvasLayer.frame.size = newSize
        stripeLayer.frame.size = newSize


        canvasLayer.setNeedsDisplay()
        canvasLayer.removeAllAnimations()
        stripeLayer.setNeedsDisplay()
        stripeLayer.removeAllAnimations()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard goodQuadrance(touch: touches.first!) else { return }
        let dirtyRect = drawingAgent.handleTouch(touches.first!, event!, self)
        resize(dirtyRect)
        print("touchesMoved: setNeedsDisplay(rect)")
        canvasLayer.setNeedsDisplay(dirtyRect)
    }
}
