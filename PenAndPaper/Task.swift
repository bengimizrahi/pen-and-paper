//
//  Task.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 30.10.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class Task {

    // MARK: Drawing Information

    var strokes: Set<Stroke>

    // MARK: View

    var view: TaskView

    init() {
        strokes = Set<Stroke>()
        view = TaskView()
        view.task = self
    }
}
