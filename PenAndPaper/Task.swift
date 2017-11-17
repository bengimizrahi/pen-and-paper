//
//  Task.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 30.10.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

var nextId = 0

class Task {

    let id: Int

    // MARK: Drawing Information

    var strokes: Set<Stroke>

    // MARK: View

    var view: TaskView

    init() {
        id = nextId
        nextId += 1
        strokes = Set<Stroke>()
        view = TaskView()
        view.task = self
    }
}
