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
}

extension Stroke: CustomDebugStringConvertible {
    var debugDescription: String {
        return String(describing:vertices)
    }
}
