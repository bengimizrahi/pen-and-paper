//
//  StrokeDataModel.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 27/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

let kOverlapRegionWidth: CGFloat = 5.0

struct Vertex {
    var location: CGPoint
    var thickness: CGFloat
}

class Stroke {
    var vertices = [Vertex]()

    func append(vertex: Vertex) {
        vertices.append(vertex)
    }

    func overlaps(with point:CGPoint) -> Bool {
        if vertices.count == 1 {
            return distance(from: vertices.first!.location, to: point) <= kOverlapRegionWidth
        }

        for i in 0 ..< vertices.count - 1 {
            let v0 = vertices[i].location
            let v1 = vertices[i + 1].location
            if distance(from: point, to: (v0, v1)) <= kOverlapRegionWidth {
                return true
            }
        }

        return false
    }
}
