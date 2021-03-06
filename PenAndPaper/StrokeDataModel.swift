//
//  StrokeDataModel.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 27/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

struct Vertex {
    var location: CGPoint
    var thickness: CGFloat

    func gridIndex(_ gridSize: CGSize) -> (Int, Int) {
        let i = Int(location.y / gridSize.height)
        let j = Int(location.x / gridSize.width)
        return (i, j)
    }
}

class Stroke {
    var vertices = [Vertex]()
    var maxThickness: CGFloat = 0.0

    func append(vertex: Vertex) {
        vertices.append(vertex)
        maxThickness = max(maxThickness, vertex.thickness)
    }

    func crosses(with line: (CGPoint, CGPoint)) -> Bool {
        if vertices.count == 1 {
            let v0 = vertices.first!.location.applying(CGAffineTransform(translationX: 0.0, y: -0.5))
            let v1 = v0.applying(CGAffineTransform(translationX: 0.0, y: 1.0))
            return linesIntersect(a: line, b: (v0, v1))
        }

        for idx in 0 ..< vertices.count - 1 {
            let v0 = vertices[idx].location
            let v1 = vertices[idx + 1].location

            if linesIntersect(a: line, b: (v0, v1)) {
                return true
            }
        }

        return false
    }

    func overlaps(with point:CGPoint) -> Bool {
        if vertices.count == 1 {
            return distance(from: vertices.first!.location, to: point, isLessThan: 10.0)
        }

        for i in 0 ..< vertices.count - 1 {
            let v0 = vertices[i].location
            let v1 = vertices[i + 1].location

            if distanceToLine(from: point, to: (v0, v1), isLessThan: 10.0) {
                return true
            }
        }
        return false
    }

    func frame() -> CGRect {
        let vertexFrame = { (v: Vertex) -> CGRect in
            let r = CGRect(origin: v.location,
                           size:CGSize(width: self.maxThickness,
                                       height: self.maxThickness))
            r.applying(CGAffineTransform(translationX: -self.maxThickness / 2.0,
                                         y: -self.maxThickness / 2.0))
            return r
        }
        if vertices.count == 1 {
            return vertexFrame(vertices.first!)
        } else {
            let box = vertexFrame(vertices.first!)
            return vertices.reduce(box) { $0.union(vertexFrame($1)) }
        }
    }

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
            path.lineCapStyle = .round
            path.stroke()

            path = UIBezierPath()
            path.move(to: v.location)
            path.lineWidth = v.thickness
        }
    }
}

extension Stroke: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    static func ==(lhs: Stroke, rhs: Stroke) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
