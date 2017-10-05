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

extension Vertex : CustomDebugStringConvertible {
    var debugDescription: String {
        return "Vertex(loc: \(location), thickness: \(thickness), "
    }
}

enum StrokePhase {
    case active
    case done
}

class Stroke {

    var vertices = [Vertex]()
    var phase: StrokePhase = .active

    func append(_ vertices: [Vertex]) {
        self.vertices.append(contentsOf: vertices)
    }

    class StrokePainter {

        let stroke: Stroke
        var idx: Int? = nil

        init(stroke: Stroke) {
            self.stroke = stroke
        }

        func getCurveDataAndAdvance() -> (Vertex, Vertex, Vertex)? {
            guard !self.stroke.vertices.isEmpty else {
                return nil
            }
            idx = idx ?? 0
            guard idx! + 3 < stroke.vertices.count else { return nil }

            let avg = { (v1: Vertex, v2: Vertex) in
                return Vertex(location: CGPoint(x: (v1.location.x + v2.location.x) / 2.0,
                                                y: (v1.location.y + v2.location.y) / 2.0),
                              thickness: (v1.thickness + v2.thickness) / 2.0)
            }

            let data = (
                stroke.vertices[idx!],
                stroke.vertices[idx! + 1],
                avg(stroke.vertices[idx! + 1],
                    stroke.vertices[idx! + 2])
            )
            idx! += 2
            return data
        }

        func getLastDrawnPoint() -> Vertex? {
            guard !stroke.vertices.isEmpty else { return nil }
            idx = idx ?? 0

            let avg = { (v1: Vertex, v2: Vertex) in
                return Vertex(location: CGPoint(x: (v1.location.x + v2.location.x) / 2.0,
                                                y: (v1.location.y + v2.location.y) / 2.0),
                              thickness: (v1.thickness + v2.thickness) / 2.0)
            }

            let prevIdx = max(idx! - 1, 0)
            return avg(stroke.vertices[prevIdx],
                       stroke.vertices[idx!])
        }

        func draw(on context: CGContext) {
            guard let a = getLastDrawnPoint() else { return }

            context.beginPath()
            context.setLineCap(.round)
            context.move(to: a.location)
            context.setLineWidth(a.thickness)
            while let (c1, c2, b) = getCurveDataAndAdvance() {
                context.addCurve(to: b.location, control1: c1.location, control2: c2.location)
                context.setLineWidth(b.thickness)
            }

            defer { context.drawPath(using: .stroke) }

            if stroke.phase == .active { return }

            let pointsLeft = (stroke.vertices.count - 1) - idx!
            guard pointsLeft > 0 else { return }
            if pointsLeft == 1 {
                context.addLine(to: stroke.vertices[idx!].location)
            } else if pointsLeft == 2 {
                context.addQuadCurve(to: stroke.vertices[idx! + 1].location,
                                     control: stroke.vertices[idx!].location)
            }
        }
    }
}

