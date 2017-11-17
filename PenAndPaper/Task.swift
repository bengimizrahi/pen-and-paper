//
//  Task.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 30.10.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class Task {
    let id = UUID()
    var strokes = Set<Stroke>()
    var numOfGridsHorizontally = 0
    var grids = [[Set<Stroke>]]()
    var canvas = UIImage()

    var size: CGSize {
        return canvas.size
    }
    
    init() {
        // Setup canvas
        let screenWidth = UIScreen.main.bounds.width
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: screenWidth, height: TaskView.kLineHeight), false, 0.0)
        canvas = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        // Setup grids
        numOfGridsHorizontally = Int(size.width / TaskView.kLineHeight) + 1
        grids = [[Set<Stroke>](repeating: [], count: numOfGridsHorizontally)]
    }
}
