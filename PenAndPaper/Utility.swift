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

class BoundingBox {
    var box: CGRect? = nil

    func expand(with rect: CGRect) {
        box = (box == nil) ? rect : box!.union(rect)
    }
}

func linesIntersect(a: (CGPoint, CGPoint), b: (CGPoint, CGPoint)) -> Bool {
    // Reference: https://martin-thoma.com/how-to-check-if-two-line-segments-intersect/

    func boundingBoxesIntersect(a: CGRect, b: CGRect) -> Bool {
        return a.minX <= b.maxX &&
                b.minX <= a.maxX &&
                a.minY <= b.maxY &&
                b.minY <= a.maxY
    }

    func crossProduct(a: CGPoint, b: CGPoint) -> CGFloat {
        return a.x * b.y - b.x * a.y
    }

    let epsilon = 0.000001

    func pointOnLine(p: CGPoint, l: (CGPoint, CGPoint)) -> Bool {
        let (p1, p2) = l
        let translate = CGAffineTransform(translationX: -p1.x, y: -p1.y)
        let translatedLine = (p1.applying(translate), p2.applying(translate))
        return abs(Double(crossProduct(a: p, b: translatedLine.1))) <= epsilon
    }

    func pointRightOfLine(p: CGPoint, l: (CGPoint, CGPoint)) -> Bool {
        let (p1, p2) = l
        let translate = CGAffineTransform(translationX: -p1.x, y: -p1.y)
        let translatedLine = (p1.applying(translate), p2.applying(translate))
        return abs(Double(crossProduct(a: p, b: translatedLine.1))) < 0
    }

    func lineSegmentTouchesOrCrossesLine(l: (CGPoint, CGPoint), ls: (CGPoint, CGPoint)) -> Bool {
        return pointOnLine(p: ls.0, l: l) || pointOnLine(p: ls.1, l: l) ||
                (pointRightOfLine(p: ls.0, l: l) != pointRightOfLine(p: ls.1, l: l))
    }

    let boxA = CGRect(x: min(a.0.x, a.1.x), y: min(a.0.y, a.1.y),
                      width: CGFloat(abs(Double(a.0.x - a.1.x))),
                      height: CGFloat(abs(Double(a.0.y - a.1.y))))
    let boxB = CGRect(x: min(b.0.x, b.1.x), y: min(b.0.y, b.1.y),
                      width: CGFloat(abs(Double(b.0.x - b.1.x))),
                      height: CGFloat(abs(Double(b.0.y - b.1.y))))

    return boundingBoxesIntersect(a: boxA, b: boxB) &&
        lineSegmentTouchesOrCrossesLine(l: a, ls: b) &&
        lineSegmentTouchesOrCrossesLine(l: b, ls: a)
}

func distance(from point: CGPoint, to line:(CGPoint, CGPoint)) -> CGFloat {
    // Reference: http://mathworld.wolfram.com/Point-LineDistance2-Dimensional.html

    let (x0, y0) = (Double(point.x), Double(point.y))
    let (x1, y1) = (Double(line.0.x), Double(line.0.y))
    let (x2, y2) = (Double(line.1.x), Double(line.1.y))

    let nominator = abs(((x2 - x1) * (y1 - y0)) - ((x1 - x0) * (y2 - y1)))
    let denominator = sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)))
    let dist = nominator / denominator

    return CGFloat(dist)
}

func distance(from point0: CGPoint, to point1: CGPoint) -> CGFloat {
    let (x0, y0) = (Double(point0.x), Double(point0.y))
    let (x1, y1) = (Double(point1.x), Double(point1.y))

    let dist = sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
    return CGFloat(dist)
}
