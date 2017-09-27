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
    var force: CGFloat
    var estimatedProperties: UITouchProperties
    var estimatedPropertiesExpectingUpdates: UITouchProperties

    init(location: CGPoint, force: CGFloat,
             estimatedProperties: UITouchProperties = [],
             estimatedPropertiesExpectingUpdates: UITouchProperties = []) {
        self.location = location
        self.force = force
        self.estimatedProperties = estimatedProperties
        self.estimatedPropertiesExpectingUpdates =
                estimatedPropertiesExpectingUpdates
    }
}

extension Vertex: CustomDebugStringConvertible {
    var debugDescription: String {
        let get_bitset = { (estProp: UITouchProperties) -> String in
            let l: [(UITouchProperties, String)] =
                [(.force, "f"), (.azimuth, "z"), (.altitude, "t"), (.location, "l")]
            return l.reduce("", { s, t in estProp.contains(t.0) ? s + t.1 : s })
        }
        return "Vertex(loc: \(location), force: \(force), " +
                "est: \(get_bitset(estimatedProperties)), " +
                "est-exp: \(get_bitset(estimatedPropertiesExpectingUpdates))"
    }
}

class Stroke {
    var vertices: [Vertex] = []

    func add(_ vertex: Vertex) {
        vertices.append(vertex)
    }

    func update(_ vertex: Vertex, at index: Int) {
        vertices[index] = vertex
    }

    func frame() -> CGRect? {
        guard vertices.count > 0 else {
            return nil
        }

        var frame = CGRect(origin: vertices.first!.location, size: CGSize())
        for v in vertices[1...] {
            frame = frame.union(CGRect(origin:v.location, size: CGSize()))
        }

        return frame.insetBy(dx: -4.0, dy: -4.0)
    }
}

extension Stroke: CustomDebugStringConvertible {
    var debugDescription: String {
        return String(describing:vertices)
    }
}
