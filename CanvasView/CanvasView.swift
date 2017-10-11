//
//  CanvasView.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 10/10/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class DrawingAgent {

    let bounds: CGRect
    var canvas: UIImage

    var dirtyRect: CGRect? = nil
    var startingVertex = Vertex(location: CGPoint(),
                                thickness: CGFloat())

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

    func handleTouch(_ touch: UITouch, _ event: UIEvent, _ view: UIView) {
        kpiNumberOfTouchHandle += 1

        // handle only .began and .moved
        guard touch.phase == .began || touch.phase == .moved else { return }

        //let _ = Measure { print("handleTouch: \($0)") }

        // start with a new canvas
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)

        // first draw the old canvas into the new one
        canvas.draw(in: bounds)

        // start a bezier path
        UIColor.black.set()
        let path = UIBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        kpiNumberOfTouches += event.coalescedTouches(for: touch)!.count
        var it = event.coalescedTouches(for: touch)!.makeIterator()

        // if touch began, use the first vertex as the starting vertex
        if touch.phase == .began {
            let firstTouch = it.next()!
            startingVertex = Vertex(location: firstTouch.location(in: view),
                                    thickness: forceToThickness(force: firstTouch.force))
        }

        // move to the start vertex
        path.move(to: startingVertex.location)
        path.lineWidth = startingVertex.thickness
        expandDirtyRect(with: CGRect(origin: startingVertex.location, size: CGSize()))

        // add the rest of the vertices to the path
        while let ct = it.next() {
            let vertex = Vertex(location: ct.location(in: view),
                                thickness: forceToThickness(force: ct.force))
            path.addLine(to: vertex.location)
            expandDirtyRect(with: CGRect(origin: vertex.location, size: CGSize()))
        }

        path.stroke()

        let lastTouch = event.coalescedTouches(for: touch)!.last!
        startingVertex = Vertex(location: lastTouch.location(in: view),
                                thickness: forceToThickness(force: lastTouch.force))
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        view.setNeedsDisplay(dirtyRect!.insetBy(dx: -2.0, dy: -2.0))
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

    class StripeLayerDelegate : NSObject, CALayerDelegate {
        func draw(_ layer: CALayer, in ctx: CGContext) {
            let rect = ctx.boundingBoxOfClipPath
            let red = CGFloat(drand48())
            let green = CGFloat(drand48())
            let blue = CGFloat(drand48())
            ctx.setFillColor(red: red, green: green, blue: blue, alpha: 0.5)
            ctx.fill(rect)
        }
    }

    lazy var drawingAgent: DrawingAgent = { [unowned self] in
        return DrawingAgent(bounds: bounds)
    }()
    var stripeLayerDelegate: StripeLayerDelegate

    required init?(coder aDecoder: NSCoder) {
        stripeLayerDelegate = StripeLayerDelegate()
        super.init(coder: aDecoder)
        let stripeLayer = CATiledLayer()
        stripeLayer.contentsScale = UIScreen.main.scale
        stripeLayer.frame = bounds
        stripeLayer.tileSize = CGSize(width: 50.0, height: 50.0)
        stripeLayer.delegate = stripeLayerDelegate
        layer.addSublayer(stripeLayer)
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
        drawingAgent.handleTouch(touches.first!, event!, self)
    }

    override func draw(_ rect: CGRect) {
        drawingAgent.drawRect(rect)
    }
}
