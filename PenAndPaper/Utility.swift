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

func distance(from point: CGPoint, to line:(CGPoint, CGPoint)) -> CGFloat {
    // Reference: http://mathworld.wolfram.com/Point-LineDistance2-Dimensional.html

    let (x0, y0) = (Double(point.x), Double(point.y))
    let (x1, y1) = (Double(line.0.x), Double(line.0.y))
    let (x2, y2) = (Double(line.1.x), Double(line.1.y))
    print("(\(x1),\(y1))---------(\(x2),\(y2)) & (\(x0),\(y0))")
    let nominator = abs(((x2 - x1) * (y1 - y0)) - ((x1 - x0) * (y2 - y1)))
    let denominator = sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)))
    let dist = nominator / denominator
    print ("dist: \(dist) (\(nominator)/\(denominator))")
    return CGFloat(dist)
}

func distance(from point0: CGPoint, to point1: CGPoint) -> CGFloat {
    let (x0, y0) = (Double(point0.x), Double(point0.y))
    let (x1, y1) = (Double(point1.x), Double(point1.y))

    let dist = sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
    return CGFloat(dist)
}
