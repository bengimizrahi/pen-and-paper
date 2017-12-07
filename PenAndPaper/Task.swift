//
//  Task.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 7.12.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class Task {
    var strokes = Set<Stroke>()
    var cachedImage: UIImage
    var subTasks: [Task]

    init(strokes: Set<Stroke> = [], cachedImage: UIImage = UIImage()) {
        self.strokes = strokes
        self.cachedImage = cachedImage
        subTasks = []
    }
}
