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

        func getCurveDataAndAdvance() -> (CGPoint, CGPoint, CGPoint)? {
            guard !self.stroke.vertices.isEmpty else { return nil }
            idx = idx ?? 0
            guard idx! + 3 < self.stroke.vertices.count
                else { return nil }

            let avg = { (p1: CGPoint, p2: CGPoint) in
                return CGPoint(x: (p1.x + p2.x) / 2.0, y: (p1.y + p2.y) / 2.0)
            }

            let data = (
                stroke.vertices[idx!].location,
                stroke.vertices[idx! + 1].location,
                avg(stroke.vertices[idx! + 1].location,
                    stroke.vertices[idx! + 2].location)
            )
            idx! += 2
            return data
        }

        func getLastDrawnPoint() -> CGPoint? {
            guard idx != nil else { return nil }

            let avg = { (p1: CGPoint, p2: CGPoint) in
                return CGPoint(x: (p1.x + p2.x) / 2.0, y: (p1.y + p2.y) / 2.0)
            }

            let prevIdx = max(idx! - 1, 0)
            return avg(stroke.vertices[prevIdx].location,
                       stroke.vertices[idx!].location)
        }

        func draw(on context: CGContext) {
            guard let a = getLastDrawnPoint() else { return }

            context.beginPath()
            context.move(to: a)
            while let (c1, c2, b) = getCurveDataAndAdvance() {
                context.addCurve(to: b, control1: c1, control2: c2)
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

