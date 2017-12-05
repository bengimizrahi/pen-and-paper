//
//  Utility.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 28/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

let minQuandrance: CGFloat = 0.003
let defaultThickness: CGFloat = 2.0
let forceWeight: CGFloat = 0.50

func forceToThickness(force: CGFloat) -> CGFloat {
    return defaultThickness + (force - 1.0) * forceWeight
}


class Measure {

    let startTime: Date
    let function: (TimeInterval)->()

    init(function: @escaping (_ interval: TimeInterval)->()) {
        startTime = Date()
        self.function = function
    }

    deinit {
        function(timeInterval())
    }

    func timeInterval() -> TimeInterval {
        let endTime = Date()
        let diff = endTime.timeIntervalSince(startTime)
        return diff
    }
}

class LogFunc {

    let funcName: String

    init(_ funcName: String) {
        self.funcName = funcName
        print("Entering \(funcName)")
    }

    deinit {
        print("Exiting \(funcName)")
    }
}

func boundingBox(touches: [UITouch], in view: UIView) -> CGRect? {
    var box: CGRect? = nil
    for t in touches {
        let rect = CGRect(origin: t.preciseLocation(in: view), size: CGSize())
        box = (box == nil) ? rect : box!.union(rect)
    }
    return box
}

func linesIntersect(a: (CGPoint, CGPoint), b: (CGPoint, CGPoint)) -> Bool {
    // Reference: https://martin-thoma.com/how-to-check-if-two-line-segments-intersect/

    func boundingBoxesIntersect(a: CGRect, b: CGRect) -> Bool {
        let rs = a.minX <= b.maxX &&
                b.minX <= a.maxX &&
                a.minY <= b.maxY &&
                b.minY <= a.maxY
        return rs
    }

    func crossProduct(a: CGPoint, b: CGPoint) -> CGFloat {
        let rs = a.x * b.y - b.x * a.y
        return rs
    }

    let epsilon = 0.000001

    func pointOnLine(p: CGPoint, l: (CGPoint, CGPoint)) -> Bool {
        let (p1, p2) = l
        let translate = CGAffineTransform(translationX: -p1.x, y: -p1.y)
        let tl = (p1.applying(translate), p2.applying(translate))
        let tp = p.applying(translate)
        let rs = abs(Double(crossProduct(a: tp, b: tl.1))) <= epsilon
        return rs
    }

    func pointRightOfLine(p: CGPoint, l: (CGPoint, CGPoint)) -> Bool {
        let (p1, p2) = l
        let translate = CGAffineTransform(translationX: -p1.x, y: -p1.y)
        let tl = (p1.applying(translate), p2.applying(translate))
        let tp = p.applying(translate)
        let rs = crossProduct(a: tp, b: tl.1) < 0
        return rs
    }

    func lineSegmentTouchesOrCrossesLine(l: (CGPoint, CGPoint), ls: (CGPoint, CGPoint)) -> Bool {
        let rs = pointOnLine(p: ls.0, l: l) || pointOnLine(p: ls.1, l: l) ||
                (pointRightOfLine(p: ls.0, l: l) != pointRightOfLine(p: ls.1, l: l))
        return rs
    }

    let boxA = CGRect(x: min(a.0.x, a.1.x), y: min(a.0.y, a.1.y),
                      width: CGFloat(abs(Double(a.0.x - a.1.x))),
                      height: CGFloat(abs(Double(a.0.y - a.1.y))))
    let boxB = CGRect(x: min(b.0.x, b.1.x), y: min(b.0.y, b.1.y),
                      width: CGFloat(abs(Double(b.0.x - b.1.x))),
                      height: CGFloat(abs(Double(b.0.y - b.1.y))))

    let rs = boundingBoxesIntersect(a: boxA, b: boxB) &&
            lineSegmentTouchesOrCrossesLine(l: a, ls: b) &&
            lineSegmentTouchesOrCrossesLine(l: b, ls: a)
    return rs
}

func distanceToLine(from point: CGPoint, to line:(CGPoint, CGPoint), isLessThan dist: CGFloat) -> Bool {
    // Reference: http://mathworld.wolfram.com/Point-LineDistance2-Dimensional.html

    let (x0, y0) = (Double(point.x), Double(point.y))
    var (x1, y1) = (Double(line.0.x), Double(line.0.y))
    var (x2, y2) = (Double(line.1.x), Double(line.1.y))

    let nominator = abs(((x2 - x1) * (y1 - y0)) - ((x1 - x0) * (y2 - y1)))
    let denominator = sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)))
    let perpendicularDist = nominator / denominator

    guard CGFloat(perpendicularDist) <= dist else { return false }

    var expansionDirection = x1 < x2 ? -1.0 : 1.0
    x1 += expansionDirection * Double(dist)
    x2 += -expansionDirection * Double(dist)
    expansionDirection = y1 < y2 ? -1.0 : 1.0
    y1 += expansionDirection * Double(dist)
    y2 += -expansionDirection * Double(dist)

    return ((x0 < x1) != (x0 < x2)) && ((y0 < y1) != (y0 < y2))
}

func distance(from point0: CGPoint, to point1: CGPoint, isLessThan dist: CGFloat) -> Bool {
    let (x0, y0) = (Double(point0.x), Double(point0.y))
    let (x1, y1) = (Double(point1.x), Double(point1.y))

    let quadrance = (x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)
    return CGFloat(quadrance) < (dist * dist)
}

let kMinQuandrance: CGFloat = 0.003

func goodQuadrance(touch: UITouch, view: UIView) -> Bool {
    if touch.phase == .began { return true }
    let prev = touch.precisePreviousLocation(in: view)
    let curr = touch.preciseLocation(in: view)
    let (dx, dy) = (curr.x - prev.x, curr.y - prev.y)
    let quadrance = dx * dx + dy * dy
    return quadrance >= kMinQuandrance
}

