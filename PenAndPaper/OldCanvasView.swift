//
//  OldCanvasView.swift
//  OldCanvasView
//
//  Created by Bengi Mizrahi on 10/10/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

protocol DrawDelegate {
    func bounds() -> CGRect
    func draw(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> CGRect
    func redraw()
}

class CirclePainter : DrawDelegate {

    let sz: CGFloat = 5.0

    var points = [CGPoint]()

    func bounds() -> CGRect {
        var box = points.reduce(CGRect()) { $0.union(CGRect(origin: $1, size: CGSize())) }
        box.size.height += (sz / 2.0)
        box.size.width += (sz / 2.0)
        return box
    }

    func drawCircle(at rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        context.addEllipse(in: rect)
        context.drawPath(using: .fill)
    }

    func circleRect(at point: CGPoint) -> CGRect {
        let r = CGRect(origin: CGPoint(x: point.x - sz, y: point.y - sz),
                       size: CGSize(width: 2 * sz, height: 2 * sz))
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

    func erase(rect: CGRect) {

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

    func bounds() -> CGRect {
        return strokeCollection.reduce(CGRect()) { $0.union($1.frame()) }
    }

    func draw(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> CGRect {
        if touch.phase == .cancelled || touch.phase == .ended {
            if let completedStroke = currentStroke {
                strokeCollection.append(completedStroke)
                currentStroke = nil
            }
            return CGRect()
        }

        var maxThicknessNoted: CGFloat = 0.0

        // start a bezier path
        UIColor.black.set()
        let path = UIBezierPath()

        var it = event.coalescedTouches(for: touch)!.makeIterator()

        // if touch began, use the first vertex as the starting vertex
        if touch.phase == .began {
            let firstTouch = it.next()!
            let thickness = forceToThickness(force: firstTouch.force)
            maxThicknessNoted = max(maxThicknessNoted, thickness)
            startingVertex = Vertex(location: firstTouch.preciseLocation(in: view),
                                    thickness: thickness)
            currentStroke = Stroke()
            currentStroke!.append(vertex: startingVertex)
        }

        // move to the start vertex
        path.move(to: startingVertex.location)
        print("M \(startingVertex.location) W \(startingVertex.thickness)")
        path.lineWidth = startingVertex.thickness
        var dirtyRect = CGRect(origin: startingVertex.location, size: CGSize())

        // add the rest of the vertices to the path
        while let ct = it.next() {
            let thickness = forceToThickness(force: ct.force)
            maxThicknessNoted = max(maxThicknessNoted, thickness)
            let vertex = Vertex(location: ct.preciseLocation(in: view),
                                thickness: thickness)
            path.addLine(to: vertex.location)
            print("L \(vertex.location) S M \(vertex.location) W \(vertex.thickness)")
            path.stroke()
            path.move(to: vertex.location)
            path.lineWidth = vertex.thickness
            currentStroke!.append(vertex: vertex)
            dirtyRect = dirtyRect.union(CGRect(origin: vertex.location, size: CGSize()))
        }

        let lastTouch = event.coalescedTouches(for: touch)!.last!
        startingVertex = Vertex(location: lastTouch.preciseLocation(in: view),
                                thickness: forceToThickness(force: lastTouch.force))

        return dirtyRect.insetBy(dx: -maxThicknessNoted, dy: -maxThicknessNoted)
    }

    func erase(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> Bool {
        var erasePath = (touch.phase == .began) ? [] : [startingVertex]
        let touches = event.coalescedTouches(for: touch)!
        touches.forEach { erasePath.append(Vertex(location: $0.preciseLocation(in: view),
                                                      thickness: 0.0)) }
        var markedStrokesForErasure = [Int]()
        for (idx, stroke) in strokeCollection.enumerated() {
            for i in 0 ..< erasePath.count {
                let p = erasePath[i].location
                if stroke.overlaps(with: p) {
                    markedStrokesForErasure.append(idx)
                    break
                }
            }
        }

        let atLeastOneStrokeErased = !markedStrokesForErasure.isEmpty
        if atLeastOneStrokeErased {
            for idx in markedStrokesForErasure.reversed() {
                strokeCollection.remove(at: idx)
            }
        }

        // why???? (Remember the - - - - - problem found by svg)
        if touch.phase == .began || touch.phase == .moved {
            startingVertex = Vertex(location: touches.first!.preciseLocation(in: view),
                                    thickness: 0.0)
        }

        return atLeastOneStrokeErased
    }

    func redraw() {
        UIColor.black.set()

        func drawStroke(stroke: Stroke) {
            let path = UIBezierPath()

            assert(stroke.vertices.count > 0)

            let firstVertex = stroke.vertices.first!
            path.move(to: firstVertex.location)
            print("REDRAW M \(firstVertex.location) W \(firstVertex.thickness)")
            path.lineWidth = firstVertex.thickness
            for vertex in stroke.vertices[1...] {
                print("REDRAW L \(vertex.location) S M \(vertex.location) W \(vertex.thickness)")
                path.addLine(to: vertex.location)
                path.stroke()
                path.move(to: vertex.location)
                path.lineWidth = vertex.thickness
            }
        }

        for stroke in strokeCollection {
            drawStroke(stroke: stroke)
        }
        if let currentStroke = currentStroke {
            drawStroke(stroke: currentStroke)
        }
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
        let resizingTriggeringEdge = bounds.height - OldCanvasView.kResizingTriggeringMargin
        guard dirtyRect.maxY >= resizingTriggeringEdge else { return }

        let newBounds = { () -> CGRect in
            var b = self.bounds
            let n = CGFloat(Int((dirtyRect.origin.y + dirtyRect.height) /
                    DrawingAgent.kOffscreenImageResizingAmount))
            let newHeight = (n + 1) * DrawingAgent.kOffscreenImageResizingAmount
            b.size.height = newHeight
            return b
        }()
        guard newBounds != bounds else { return }

        UIGraphicsBeginImageContextWithOptions(newBounds.size, false, 0.0)
        canvas.draw(in: bounds)
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        bounds = newBounds
        UIGraphicsEndImageContext()
    }

    func shrinkSize(_ newSize: CGSize) {
        bounds = CGRect(origin:CGPoint(), size: newSize)
    }

    func expandDirtyRect(with rect: CGRect) {
        dirtyRect = (dirtyRect == nil) ? rect : dirtyRect!.union(rect)
    }

    func handleTouch(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> CGRect {
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

    func handleErase(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> (Bool, CGRect) {
        let erased = drawDelegate.erase(touch, event, view)
        guard erased else { return (false, CGRect()) }

        var shrinkedBounds = drawDelegate.bounds()
        shrinkedBounds.size.width = bounds.width
        shrinkedBounds.size.height = max(shrinkedBounds.height, OldCanvasView.kInterBaselineDistance)

        UIGraphicsBeginImageContextWithOptions(shrinkedBounds.size, false, 0.0)
        drawDelegate.redraw()
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return (erased, shrinkedBounds)
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

class OldCanvasView: UIView {

    static let kResizingTriggeringMargin: CGFloat = 20.0
    static let kInterBaselineDistance: CGFloat = 40.0
    static let kBaselineColor = UIColor(red: 179.0 / 255.0,
                                        green: 223.0 / 255.0,
                                        blue: 251.0 / 255.0,
                                        alpha: 1.0)

    class StripeLayer: CATiledLayer, CALayerDelegate {
        func draw(_ layer: CALayer, in ctx: CGContext) {
            UIGraphicsPushContext(ctx)
            let rect = ctx.boundingBoxOfClipPath

            let path = UIBezierPath()
            kBaselineColor.set()
            let baselineY = rect.minY + kInterBaselineDistance - 1.5
            path.move(to: CGPoint(x: rect.minX, y: baselineY))
            path.addLine(to: CGPoint(x: rect.maxX, y: baselineY))
            path.lineWidth = 0.5
            path.stroke()
            UIGraphicsPopContext()
        }
    }

    class CanvasLayer: CALayer, CALayerDelegate {
        weak var drawingAgent: DrawingAgent? = nil

        func draw(_ layer: CALayer, in ctx: CGContext) {
            guard let agent = drawingAgent else { return }

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

        stripeLayer.tileSize = CGSize(
                width: bounds.width,
                height: OldCanvasView.kInterBaselineDistance).applying(
                    CGAffineTransform(scaleX: scale, y: scale))

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
        let resizingTriggeringHeight = bounds.height - OldCanvasView.kResizingTriggeringMargin
        guard dirtyRect.maxY >= resizingTriggeringHeight else { return }

        self.drawingAgent.resize(dirtyRect: dirtyRect)

        let newHeight = dirtyRect.origin.y + dirtyRect.height + OldCanvasView.kResizingTriggeringMargin
        let newSize = CGSize(width: bounds.width, height: newHeight)

        frame.size = newSize
        canvasLayer.frame.size = newSize
        stripeLayer.frame.size = newSize

        canvasLayer.setNeedsDisplay()
        canvasLayer.removeAllAnimations()
        stripeLayer.setNeedsDisplay()
        stripeLayer.removeAllAnimations()
    }

    func shrinkSize(_ size: CGSize) {
        var newSize = size
        newSize.height = max(newSize.height, OldCanvasView.kInterBaselineDistance)

        self.drawingAgent.shrinkSize(newSize)

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

        let cts = event!.coalescedTouches(for: touches.first!)!
        let box = boundingBox(touches: cts, in: self)
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let eraserEnabled = delegate.eraserButtonSelected
        if eraserEnabled == false {
            resize(box!)
            let dirtyRect = drawingAgent.handleTouch(touches.first!, event!, self)

            let ph = touches.first!.phase
            if ph == .began || ph == .moved {
                canvasLayer.setNeedsDisplay(dirtyRect)
            }
        } else {
            guard let t = touches.first, (t.phase == .began || t.phase == .moved)
                else { return } // <- not important anymore, we use overlaps()

            let (erased, shrinkedBounds) = drawingAgent.handleErase(touches.first!, event!, self)
            if erased {
                shrinkSize(shrinkedBounds.size)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
    }
}
