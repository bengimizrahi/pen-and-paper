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

    init(location: CGPoint, thickness: CGFloat) {
        self.location = location
        self.thickness = thickness
    }
}

extension Vertex: CustomDebugStringConvertible {
    var debugDescription: String {
        return "Vertex(loc: \(location), thickness: \(thickness), "
    }
}

class Stroke {
    var vertices: [Vertex] = []
    var lastDrawnVertex: Int? = nil

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

    func undrawnVertices() -> ArraySlice<Vertex>? {
        if let lastDrawnVertex = lastDrawnVertex {
            return vertices[lastDrawnVertex...]
        }
        return nil
    }
}

extension Stroke: CustomDebugStringConvertible {
    var debugDescription: String {
        return String(describing:vertices)
    }
}
