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
}

class CirclePainter : DrawDelegate {
    func draw(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> CGRect {
        UIColor.black.setFill()
        var rr: CGRect? = nil
        for ct in event.coalescedTouches(for: touch)! {
            let c = ct.preciseLocation(in: view)
            let s: CGFloat = 5.0
            let r = CGRect(origin: CGPoint(x: c.x - s, y: c.y - s),
                           size: CGSize(width: 2*s, height: 2*s))
            let context = UIGraphicsGetCurrentContext()!
            context.addEllipse(in: r)
            context.drawPath(using: .fill)
            rr = (rr == nil) ? r : rr?.union(r)
        }
        return rr!
    }
}

class DefaultPainter : DrawDelegate {

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
        }

        // move to the start vertex
        path.move(to: startingVertex.location)
        path.lineWidth = startingVertex.thickness
        var dirtyRect = CGRect(origin: startingVertex.location, size: CGSize())

        // add the rest of the vertices to the path
        while let ct = it.next() {
            let thickness = forceToThickness(force: ct.force)
            maxThicknessNoted = max(maxThicknessNoted, thickness)
            let vertex = Vertex(location: ct.preciseLocation(in: view),
                                thickness: thickness)
            path.addLine(to: vertex.location)
            path.lineWidth = vertex.thickness
            dirtyRect = dirtyRect.union(CGRect(origin: vertex.location, size: CGSize()))
        }

        path.stroke()

        let lastTouch = event.coalescedTouches(for: touch)!.last!
        startingVertex = Vertex(location: lastTouch.location(in: view),
                                thickness: forceToThickness(force: lastTouch.force))

        return dirtyRect.insetBy(dx: -maxThicknessNoted / 2.0, dy: -maxThicknessNoted / 2.0)
    }
}

class DrawingAgent {

    let bounds: CGRect
    var canvas: UIImage

    var dirtyRect: CGRect? = nil
    var drawDelegate = DefaultPainter()

    var kpiNumberOfTouches = 0
    var kpiNumberOfTouchHandle = 0.0
    var kpiNumberOfDrawRect = 0.0

    func printKpi() {
        let r = kpiNumberOfTouchHandle / kpiNumberOfDrawRect
        print("#touch: \(kpiNumberOfTouches), ratio: \(r)")
        kpiNumberOfTouchHandle = 0
        kpiNumberOfDrawRect = 0
    }

    init(bounds: CGRect) {
        self.bounds = bounds

        // create an empty canvas
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
    }

    func expandDirtyRect(with rect: CGRect) {
        dirtyRect = (dirtyRect == nil) ? rect : dirtyRect!.union(rect)
    }

    func handleTouch(_ touch: UITouch, _ event: UIEvent, _ view: UIView) -> CGRect {
        kpiNumberOfTouchHandle += 1

        // handle only .began and .moved
        assert(touch.phase == .began || touch.phase == .moved)

        //let _ = Measure { print("handleTouch: \($0)") }

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
        kpiNumberOfDrawRect += 1
        printKpi()

        //let _ = Measure { print("drawRect: \($0)") }

        let scale = UIScreen.main.scale
        let canvasRect = rect.applying(CGAffineTransform(scaleX: scale, y: scale))
        let subimage = UIImage(cgImage: canvas.cgImage!.cropping(to: canvasRect)!)
        subimage.draw(in: rect)
        dirtyRect = nil
    }
}

class CanvasView: UIView {

    static let kCornerRadius: CGFloat = 14.0

    class StripeLayerDelegate: NSObject, CALayerDelegate {
        func draw(_ layer: CALayer, in ctx: CGContext) {
            let rect = ctx.boundingBoxOfClipPath
            let red = CGFloat(drand48())
            let green = CGFloat(drand48())
            let blue = CGFloat(drand48())
            ctx.setFillColor(red: red, green: green, blue: blue, alpha: 0.5)
            ctx.fill(rect)
        }
    }

    class CanvasLayerDelegate: NSObject, CALayerDelegate {

        weak var drawingAgent: DrawingAgent? = nil

        func draw(_ layer: CALayer, in ctx: CGContext) {
            guard let agent = drawingAgent else { return }

            UIGraphicsPushContext(ctx)
            agent.drawRect(ctx.boundingBoxOfClipPath)
            UIGraphicsPopContext()
        }
    }

    var stripeLayer: CATiledLayer
    var canvasLayer: CALayer
    var stripeLayerDelegate: StripeLayerDelegate
    var canvasLayerDelegate: CanvasLayerDelegate
    lazy var drawingAgent: DrawingAgent = { [unowned self] in
        return DrawingAgent(bounds: bounds)
    }()

    required init?(coder aDecoder: NSCoder) {
        stripeLayer = CATiledLayer()
        canvasLayer = CALayer()
        stripeLayerDelegate = StripeLayerDelegate()
        canvasLayerDelegate = CanvasLayerDelegate()

        super.init(coder: aDecoder)

        canvasLayerDelegate.drawingAgent = drawingAgent

        let scale = UIScreen.main.scale
        stripeLayer.contentsScale = scale
        canvasLayer.contentsScale = scale

        stripeLayer.frame = bounds
        canvasLayer.frame = bounds

        stripeLayer.tileSize = CGSize(width: 50.0, height: 50.0)

        stripeLayer.delegate = stripeLayerDelegate
        canvasLayer.delegate = canvasLayerDelegate

        layer.addSublayer(stripeLayer)
        layer.addSublayer(canvasLayer)

        layer.masksToBounds = true
        layer.borderWidth = 0.5
        layer.cornerRadius = CanvasView.kCornerRadius
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesMoved(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard goodQuadrance(touch: touches.first!) else { return }
        let dirtyRect = canvasLayerDelegate.drawingAgent!.handleTouch(touches.first!, event!, self)
        canvasLayer.setNeedsDisplay(dirtyRect)
    }
}
