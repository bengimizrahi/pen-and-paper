//
//  TaskTableViewCell.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 30.10.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {

    @IBOutlet weak var taskView: TaskView!

    func setTask(_ newTask: Task) {
        taskView.task = newTask
    }
}
