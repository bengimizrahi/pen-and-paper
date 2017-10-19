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
                let px_lte_v0x = point.x <= v0.x
                let px_lte_v1x = point.x <= v1.x
                let py_lte_v0y = point.y <= v0.y
                let py_lte_v1y = point.y <= v1.y

                if px_lte_v0x != px_lte_v1x || py_lte_v0y != py_lte_v1y {
                    return true
                }
            }
        }

        return false
    }
}
