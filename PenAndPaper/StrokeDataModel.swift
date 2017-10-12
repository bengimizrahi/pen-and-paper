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
}

class Stroke {
    var vertices = [Vertex]()

    func append(vertex: Vertex) {
        vertices.append(vertex)
    }
}
