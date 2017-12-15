//
//  CanvasView.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 22.11.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

extension UIColor {
    static let stripleColor = UIColor(red: 179.0 / 255.0,
                                      green: 223.0 / 255.0,
                                      blue: 251.0 / 255.0,
                                      alpha: 1.0)
}

class PaperLayer: CAShapeLayer {
    override init() {
        super.init()
        initialize()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    func initialize() {
        shadowOffset = CGSize()
        backgroundColor = UIColor.white.cgColor
    }
}

class StripeLayer: CATiledLayer, CALayerDelegate {
    var stripeColor: UIColor? = nil
    var lineHeight: CGFloat? = nil

    override init() {
        super.init()
        let scale = UIScreen.main.scale
        contentsScale = scale
        delegate = self
    }

    override init(layer: Any) {
        super.init(layer: layer)
        let scale = UIScreen.main.scale
        contentsScale = scale
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    override init() {
        super.init()
        let scale = UIScreen.main.scale
        contentsScale = scale
        contentsGravity = kCAGravityBottom
        delegate = self
    }

    override init(layer: Any) {
        super.init(layer: layer)
        let scale = UIScreen.main.scale
        contentsScale = scale
        contentsGravity = kCAGravityBottom
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

class Grids {
    let x: Int
    let y: Int
    let gridSize: CGSize
    var grids: [[Set<Stroke>]]

    init() {
        x = 0
        y = 0
        gridSize = CGSize.zero
        grids = []
    }

    init(bounds: CGSize, gridSize: CGSize) {
        self.gridSize = gridSize
        grids = []
        x = Int(bounds.width / gridSize.width) + 1
        y = Int(bounds.height / gridSize.height) + 1
        for _ in 0 ..< y {
            grids.append([Set<Stroke>](repeating: [], count: x))
        }
    }

    func clear() {
        for r in grids {
            for var g in r {
                g.removeAll(keepingCapacity: true)
            }
        }
    }

    func get(_ i: Int, _ j: Int) -> Set<Stroke>? {
        guard i >= 0 && i < y && j >= 0 && j < x else { return nil }
        return grids[i][j]
    }

    func add(stroke: Stroke) {
        for v in stroke.vertices {
            let (i, j) = v.gridIndex(self.gridSize)
            if i >= 0 && i < y && j >= 0 && j < x {
                grids[i][j].insert(stroke)
            }
        }
    }

    func remove(stroke: Stroke) {
        for (i, row) in grids.enumerated() {
            for (j, g) in row.enumerated() {
                if g.contains(stroke) {
                    grids[i][j].remove(stroke)
                }
            }
        }
    }
}

class CanvasView: UIView {

    // MARK - Constants

    static let kLineHeight: CGFloat = 40.0
    static let kMargin: CGFloat = 20.0
    static let kGridSize = CGSize(width: kLineHeight, height: kLineHeight)

    // MARK - Members

    var stripeLayer = StripeLayer()
    var canvasLayer = CanvasLayer()

    // MARK - Control states

    var eraserMode = false
    var touchIsAssociatedWithErasing = false

    // MARK - Drawing context

    var strokes = Set<Stroke>()
    var grids = Grids()
    var canvas = UIImage()

    // MARK - Current touch context

    var vertexToStartWith = Vertex(location: CGPoint(),
                                   thickness: CGFloat())
    var currentStroke: Stroke? = nil
    var strokesToErase = Set<Stroke>()
    var rectNeedsDisplay: CGRect? = nil

    // MARK - init / deinit

    override init(frame: CGRect) {
        // First initialize the CALayer objects
        stripeLayer.stripeColor = UIColor.stripleColor
        stripeLayer.lineHeight = CanvasView.kLineHeight

        super.init(frame: frame)
        secondPhaseInitialize()
    }

    required init?(coder aDecoder: NSCoder) {
        // First initialize the CALayer objects
        stripeLayer.stripeColor = UIColor.stripleColor
        stripeLayer.lineHeight = CanvasView.kLineHeight

        super.init(coder: aDecoder)
        secondPhaseInitialize()
    }

    func secondPhaseInitialize() {
        // Conduct initialisation involving self
        backgroundColor = UIColor.white
        layer.addSublayer(stripeLayer)
        layer.addSublayer(canvasLayer)
        canvasLayer.parentView = self

        // Setup grids
        grids = Grids(bounds: bounds.size, gridSize: CanvasView.kGridSize)

        // Setup canvas
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        stripeLayer.frame = bounds
        canvasLayer.frame = bounds
    }

    deinit {
        stripeLayer.delegate = nil
        canvasLayer.delegate = nil
    }

    func setStrokes(_ strokes: Set<Stroke>) {
        self.strokes = strokes
        grids.clear()
        UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0.0)
        for s in strokes {
            grids.add(stroke: s)
            s.draw()
        }
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        canvasLayer.setNeedsDisplay()
    }

    func croppedCanvas() -> UIImage? {
        guard !strokes.isEmpty else { return nil }

        let boundingBox = strokes.reduce(strokes.first!.frame()) { $0.union($1.frame()) }
        let topOffsetWithinStripes = boundingBox.minY.truncatingRemainder(
                dividingBy: CanvasView.kLineHeight)
        let bottomOffsetWithinStripes = boundingBox.maxY.truncatingRemainder(
                dividingBy: CanvasView.kLineHeight)
        let extraBottomInset = CanvasView.kLineHeight - bottomOffsetWithinStripes
        let finalHeight = min(bounds.height,
                              boundingBox.height + topOffsetWithinStripes + extraBottomInset)
        let snappedBoundingBox = CGRect(x: boundingBox.minX,
                                        y: boundingBox.minY - topOffsetWithinStripes,
                                        width: boundingBox.width,
                                        height: finalHeight)
        let scale = UIScreen.main.scale
        let snappedBoundingBoxInPixels = snappedBoundingBox.applying(
                CGAffineTransform(scaleX: scale, y: scale))

        canvas.cgImage!.cropping(to: snappedBoundingBoxInPixels)
        guard let subCgImage = canvas.cgImage!.cropping(to: snappedBoundingBoxInPixels) else { return nil }

        let subimage = UIImage(cgImage: subCgImage)
        return subimage
    }

    // MARK: Handle touches

    func handleTouches(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Exclude finger touches
        guard touches.first!.type == .stylus else { return }

        // Exclude touches that move only in the 'force' dimension
        guard goodQuadrance(touch: touches.first!, view: self) else { return }

        // Reset stroke related states
        if touches.first!.phase == .began {
            touchIsAssociatedWithErasing = eraserMode
        }

        // Forward event to the current handler
        if !touchIsAssociatedWithErasing {
            handleTouchesForDrawing(touches, with: event)
        } else {
            handleTouchesForErasing(touches, with: event)
        }
    }

    func handleTouchesForDrawing(_ touches: Set<UITouch>, with event: UIEvent?) {
        let t = touches.first!

        // Ignore .stationary touches
        guard t.phase != .stationary else { return }

        if t.phase == .cancelled || t.phase == .ended {
            strokes.insert(currentStroke!)
            grids.add(stroke: currentStroke!)

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
            assert(event != nil)
            assert(event!.coalescedTouches(for: t) != nil)
            var it = event!.coalescedTouches(for: t)!.makeIterator()

            if t.phase == .began {
                // Reset the starting vertex with the first touch location
                let firstTouch = it.next()!
                let thickness = forceToThickness(force: firstTouch.force)
                maxThicknessNoted = max(maxThicknessNoted, thickness)
                vertexToStartWith = Vertex(location: firstTouch.preciseLocation(in: self),
                                           thickness: thickness)

                // Create a new stroke and insert the first vertex
                currentStroke = Stroke()
                currentStroke!.append(vertex: vertexToStartWith)
            }

            // Move the bezier path to the starting vertex
            path.move(to: vertexToStartWith.location)
            path.lineWidth = vertexToStartWith.thickness
            var dirtyRect = CGRect(origin: vertexToStartWith.location, size: CGSize())

            // Add the rest of the vertices to the path
            while let nt = it.next() {
                let thickness = forceToThickness(force: nt.force)
                maxThicknessNoted = max(maxThicknessNoted, thickness)

                let v = Vertex(location: nt.preciseLocation(in: self), thickness: thickness)
                path.addLine(to: v.location)
                path.lineCapStyle = .round
                path.stroke()

                path = UIBezierPath()
                path.move(to: v.location)
                path.lineWidth = v.thickness

                currentStroke!.append(vertex: v)

                dirtyRect = dirtyRect.union(CGRect(origin: v.location, size: CGSize()))
            }

            // Set the starting vertex to the last drawn vertex
            vertexToStartWith = Vertex(location: t.preciseLocation(in: self),
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
        let cts = event!.coalescedTouches(for: t)!
        var erasePath = [Vertex]()
        cts.forEach { erasePath.append(Vertex(location: $0.preciseLocation(in: self),
                                              thickness: 0.0)) }

        if t.phase == .moved {
            // Erase the overlapping strokes
            var strokesToMarkForErase = Set<Stroke>()
            for v in erasePath {
                let (i, j) = v.gridIndex(CanvasView.kGridSize)
                if let grid = grids.get(i, j) {
                    for s in grid {
                        if s.overlaps(with: v.location) {
                            strokesToMarkForErase.insert(s)
                            strokesToErase.insert(s)
                            strokes.remove(s)
                            grids.remove(stroke: s)
                        }
                    }
                }
            }

            // Set the last touch location as the starting vertex for the subsequent
            // touch event.
            vertexToStartWith = Vertex(location: t.preciseLocation(in: self), thickness: 0.0)

            // Create a new image context from the old image
            UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0.0)
            canvas.draw(at: CGPoint())

            // Draw the erased touches with red
            UIColor.red.setStroke()
            for s in strokesToMarkForErase {
                s.draw()
            }

            // Get the final image
            canvas = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()

            // Set needs display for the corresponding rect
            rectNeedsDisplay = strokesToMarkForErase.reduce(CGRect()) { $0.union($1.frame()) }
            canvasLayer.setNeedsDisplay(rectNeedsDisplay!)

        } else if t.phase == .ended || t.phase == .cancelled {
            guard !strokesToErase.isEmpty else { return }

            // Redraw the strokes to a new image context
            UIGraphicsBeginImageContextWithOptions(canvas.size, false, 0.0)
            UIColor.black.set()
            for s in strokes {
                s.draw()
            }
            if let s = currentStroke {
                s.draw()
            }
            canvas = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()

            strokesToErase.removeAll(keepingCapacity: true)

            // Set needs display for the sublayers
            canvasLayer.setNeedsDisplay()
            canvasLayer.removeAllAnimations()
            stripeLayer.setNeedsDisplay()
            stripeLayer.removeAllAnimations()
        }
    }

    // MARK: Touch Began / Moved / Cancelled / Ended

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        handleTouches(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        handleTouches(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        handleTouches(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        handleTouches(touches, with: event)
    }
}

func debugPrintGridContents(grids : inout [[Set<Stroke>]], markers: [(Int, Int)]) {
    for (i, r) in grids.enumerated() {
        for (j, g) in r.enumerated() {
            let mark = markers.first { $0 == (i, j) } != nil
            print(!mark ? g.count : "X", separator: "", terminator: "")
        }
        print()
    }
}
