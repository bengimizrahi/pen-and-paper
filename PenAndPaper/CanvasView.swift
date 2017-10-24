//
//  CanvasView.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 23.10.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

extension Stroke {
    func draw() {
        var path = UIBezierPath()

        // Move to the first vertex location and set the initial thickness
        let firstVertex = vertices.first!
        path.move(to: firstVertex.location)
        path.lineWidth = firstVertex.thickness

        // Add subsequent vertex locations and make strokes with corresponding
        // thicknesses.
        for v in vertices[1...] {
            path.addLine(to: v.location)
            path.stroke()

            path = UIBezierPath()
            path.move(to: v.location)
            path.lineWidth = v.thickness
        }
    }
}

class StripeLayer: CATiledLayer, CALayerDelegate {

    var stripeColor: UIColor? = nil
    var lineHeight: CGFloat? = nil

    override var bounds: CGRect {
        didSet {
            let size = CGSize(width: bounds.width, height: lineHeight!)
            let scaledSize = size.applying(
                    CGAffineTransform(scaleX: contentsScale, y: contentsScale))
            tileSize = scaledSize
        }
    }

    func draw(_ layer: CALayer, in ctx: CGContext) {
        UIGraphicsPushContext(ctx)
        let rect = ctx.boundingBoxOfClipPath

        let path = UIBezierPath()
        stripeColor!.set()
        let baselineY = rect.minY + lineHeight! - 1.5
        path.move(to: CGPoint(x: rect.minX, y: baselineY))
        path.addLine(to: CGPoint(x: rect.maxX, y: baselineY))
        path.lineWidth = 0.5
        path.stroke()
        UIGraphicsPopContext()
    }
}


class CanvasLayer: CALayer, CALayerDelegate {
    weak var parentView: CanvasView? = nil

    func draw(_ layer: CALayer, in ctx: CGContext) {
        UIGraphicsPushContext(ctx)

        // Obtain the rect where the display will happen
        let rect = ctx.boundingBoxOfClipPath

        let canvasBounds = CGRect(origin: CGPoint(), size: parentView!.canvas.size)
        let rectToPaint = canvasBounds.intersection(rect)
        let rectToPaintInPixels = rectToPaint.applying(
            CGAffineTransform(scaleX: contentsScale,
                              y: contentsScale))

        if let subCgImage = parentView!.canvas.cgImage!.cropping(to: rectToPaintInPixels) {
            let subimage = UIImage(cgImage: subCgImage)
            subimage.draw(in: rectToPaint)
        }

        UIGraphicsPopContext()

        parentView!.rectNeedsDisplay = nil
    }
}


class CanvasView: UIView {

    // MARK: CanvasView Constants

    static let kMargin: CGFloat = 20.0
    static let kLineHeight: CGFloat = 40.0
    static let kStripeColor = UIColor(red: 179.0 / 255.0,
                                        green: 223.0 / 255.0,
                                        blue: 251.0 / 255.0,
                                        alpha: 1.0)
    static let kMinQuandrance: CGFloat = 0.003
    static let kGridSize = CGSize(width: kLineHeight, height: kLineHeight)

    // MARK: CALayers

    var stripeLayer: StripeLayer
    var canvasLayer: CanvasLayer

    // MARK: States

    var touchIsAssociatedWithErasing = false

    // MARK: Drawing Information

    var vertexToStartWidth = Vertex(location: CGPoint(),
                                    thickness: CGFloat())
    var strokes = Set<Stroke>()
    var currentStroke: Stroke? = nil
    var canvas = UIImage()
    var rectNeedsDisplay: CGRect? = nil

    // MARK: Metadata for efficient erasing

    var numOfGridsHorizontally: Int
    var grids: [[Set<Stroke>]]

    // MARK: CanvasView Initializer / Deinitializer

    required init?(coder aDecoder: NSCoder) {
        // First initialize CanvasView's member variables
        stripeLayer = StripeLayer(coder: aDecoder)!
        stripeLayer.stripeColor = CanvasView.kStripeColor
        stripeLayer.lineHeight = CanvasView.kLineHeight
        canvasLayer = CanvasLayer()

        numOfGridsHorizontally = 0
        grids = [[Set<Stroke>]]()

        // Initialize the UIView
        super.init(coder: aDecoder)
        // Now, we have bounds/frame information

        // Bind the canvas layer to this view for drawing context
        canvasLayer.parentView = self

        // Set scale and gravity information
        let scale = UIScreen.main.scale
        stripeLayer.contentsScale = scale
        canvasLayer.contentsScale = scale
        canvasLayer.contentsGravity = kCAGravityBottom

        // Set the frames of the sublayers. This will also set up the
        // tile size of the StripeLayer.
        stripeLayer.frame = bounds
        canvasLayer.frame = bounds

        // Set up delegate of the layers as themselves
        stripeLayer.delegate = stripeLayer
        canvasLayer.delegate = canvasLayer

        // Add the layers as sublayers
        layer.addSublayer(stripeLayer)
        layer.addSublayer(canvasLayer)

        // Setup canvas
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: bounds.width, height: CanvasView.kLineHeight), false, 0.0)
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        // Setup grids
        numOfGridsHorizontally = Int(bounds.width / CanvasView.kLineHeight) + 1
        grids = [[Set<Stroke>](repeating: [], count: numOfGridsHorizontally)]
    }

    deinit {
        // Tear down the delegate relationship
        stripeLayer.delegate = nil
        canvasLayer.delegate = nil
    }

    // MARK: Helper Member Functions

    func goodQuadrance(touch: UITouch) -> Bool {
        if touch.phase == .began { return true }
        let prev = touch.precisePreviousLocation(in: self)
        let curr = touch.preciseLocation(in: self)
        let (dx, dy) = (curr.x - prev.x, curr.y - prev.y)
        let quadrance = dx * dx + dy * dy
        return quadrance >= CanvasView.kMinQuandrance
    }

    func eraserButtonSelected() -> Bool {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.eraserButtonSelected
    }

    // MARK: Handle Touches

    func handleTouches(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Exclude touches that move only in the 'force' dimension
        guard goodQuadrance(touch: touches.first!) else { return }

        // Forward event to the current handler
        if touchIsAssociatedWithErasing {
            handleTouchesForErasing(touches, with: event)
        } else {
            handleTouchesForDrawing(touches, with: event)
        }
    }

    func handleTouchesForDrawing(_ touches: Set<UITouch>, with event: UIEvent?) {
        let t = touches.first!

        // Ignore .stationary touches
        guard t.phase != .stationary else { return }

        // Calculate the bounding box of the coalesced touches
        let coalescedTouches = event!.coalescedTouches(for: t)!
        let box = boundingBox(touches: coalescedTouches, in: self)

        // Expand the size if needed
        let expansionTriggeringBoundary = bounds.height - CanvasView.kMargin
        if box!.maxY >= expansionTriggeringBoundary {
            let newCanvasSize = { () -> CGSize in
                var sz = self.canvas.size
                let n = CGFloat(Int(box!.maxY / CanvasView.kLineHeight))
                let newHeight = (n + 1) * CanvasView.kLineHeight
                sz.height = newHeight
                return sz
            }()
            if newCanvasSize != canvas.size {
                // Add new grids of Set<Stroke> for expanded region
                let heightDiff = newCanvasSize.height - canvas.size.height
                let numOfNewLines = Int(heightDiff / CanvasView.kLineHeight)
                for _ in 0 ..< numOfNewLines {
                    grids.append([Set<Stroke>](repeating: [], count: numOfGridsHorizontally))
                }

                // Draw the old image onto the new-sized image context
                UIGraphicsBeginImageContextWithOptions(newCanvasSize, false, 0.0)
                canvas.draw(in: CGRect(origin: CGPoint(), size: canvas.size))
                canvas = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
            }

            // Change the bounds of the view and sublayers
            let expandedSize = CGSize(width: bounds.width,
                                 height: box!.maxY + CanvasView.kMargin)
            frame.size = expandedSize
            canvasLayer.frame.size = expandedSize
            stripeLayer.frame.size = expandedSize

            // Set needs display for stripe layer
            stripeLayer.setNeedsDisplay()
            stripeLayer.removeAllAnimations()
        }

        if t.phase == .cancelled || t.phase == .ended {
            // Collect the stroke
            strokes.insert(currentStroke!)

            // Add the stroke to the corresponding grids
            for v in currentStroke!.vertices {
                let (i, j) = v.grid(CanvasView.kGridSize)
                grids[i][j].insert(currentStroke!)
            }

            // Lose track of the stroke
            currentStroke = nil
        } else {
            // Create a new image context from the old image
            UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0.0)
            canvas.draw(at: CGPoint())

            // Draw the touches
            var maxThicknessNoted: CGFloat = 0.0
            UIColor.black.set()
            var path = UIBezierPath()
            var it = event!.coalescedTouches(for: t)!.makeIterator()

            if t.phase == .began {
                // Reset the starting vertex with the first touch location
                let firstTouch = it.next()!
                let thickness = forceToThickness(force: firstTouch.force)
                maxThicknessNoted = max(maxThicknessNoted, thickness)
                vertexToStartWidth = Vertex(location: firstTouch.preciseLocation(in: self),
                                            thickness: thickness)

                // Create a new stroke and insert the first vertex
                currentStroke = Stroke()
                currentStroke!.append(vertex: vertexToStartWidth)
            }

            // Move the bezier path to the starting vertex
            path.move(to: vertexToStartWidth.location)
            path.lineWidth = vertexToStartWidth.thickness
            var dirtyRect = CGRect(origin: vertexToStartWidth.location, size: CGSize())

            // Add the rest of the vertices to the path
            while let nt = it.next() {
                let thickness = forceToThickness(force: nt.force)
                maxThicknessNoted = max(maxThicknessNoted, thickness)

                let v = Vertex(location: nt.preciseLocation(in: self), thickness: thickness)
                path.addLine(to: v.location)
                path.stroke()

                path = UIBezierPath()
                path.move(to: v.location)
                path.lineWidth = v.thickness

                currentStroke!.append(vertex: v)

                dirtyRect = dirtyRect.union(CGRect(origin: v.location, size: CGSize()))
            }

            // Set the starting vertex to the last drawn vertex
            vertexToStartWidth = Vertex(location: t.preciseLocation(in: self),
                                        thickness: forceToThickness(force: t.force))

            // Add an inset of size of maximum thickness to the dirty rect
            let insetDirtyRect = dirtyRect.insetBy(dx: -maxThicknessNoted, dy: -maxThicknessNoted)

            // Update the rect that needs display
            rectNeedsDisplay = (rectNeedsDisplay == nil) ?
                    insetDirtyRect : rectNeedsDisplay!.union(insetDirtyRect)

            // Get the final image
            canvas = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()

            // Set needs display for the corresponding rect
            canvasLayer.setNeedsDisplay(rectNeedsDisplay!)
        }
    }

    func handleTouchesForErasing(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Convert coalesced touches into vertices
        let t = touches.first!
        var erasePath = (t.phase == .began) ? [] : [vertexToStartWidth]
        let cts = event!.coalescedTouches(for: t)!
        cts.forEach { erasePath.append(Vertex(location: $0.preciseLocation(in: self),
                                              thickness: 0.0)) }

        // Obtain indices of vertices, which overlaps with the erase path
        var someStrokesErased = false
        for s in strokes {
            for v in erasePath {
                let p = v.location
                if s.overlaps(with: p) {
                    strokes.remove(s)
                    someStrokesErased = true
                    break
                }
            }
        }

        // Set the last touch location as the starting vertex for the subsequent
        // touch event.
        vertexToStartWidth = Vertex(location: t.preciseLocation(in: self), thickness: 0.0)

        // Calculate the minimum CGRect that bounds all the strokes
        let strokesBounds = strokes.reduce(CGRect()) { $0.union($1.frame()) }

        // Calculate the new canvas size
        var newCanvasBounds = strokesBounds
        newCanvasBounds.size.width = bounds.width
        let n = CGFloat(Int(newCanvasBounds.height / CanvasView.kLineHeight))
        newCanvasBounds.size.height = (n + 1) * CanvasView.kLineHeight

        // Calculate the new view size
        var newViewSize = strokesBounds
        newViewSize.size.width = bounds.width
        newViewSize.size.height = max(CanvasView.kLineHeight, strokesBounds.maxY + CanvasView.kMargin)

        // Redraw the strokes to a new image context
        UIGraphicsBeginImageContextWithOptions(newCanvasBounds.size, false, 0.0)
        UIColor.black.set()
        for s in strokes {
            s.draw()
        }
        if let s = currentStroke {
            s.draw()
        }
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        // Shrink the size if needed
        if someStrokesErased {
            // Change the bounds of the view and sublayers
            frame.size = newViewSize.size
            canvasLayer.frame.size = newViewSize.size
            stripeLayer.frame.size = newViewSize.size

            // Set needs display for the sublayers
            canvasLayer.setNeedsDisplay()
            canvasLayer.removeAllAnimations()
            stripeLayer.setNeedsDisplay()
            stripeLayer.removeAllAnimations()
        }
    }

    // MARK: Touch Began / Moved / Cancelled / Ended

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchIsAssociatedWithErasing = eraserButtonSelected()
        handleTouches(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches, with: event)
    }
}
