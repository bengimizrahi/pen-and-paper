//
//  TaskTableViewCell.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 30.10.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class TaskTableViewCell: UITableViewCell {
    var task: Task?
    
    func setTask(_ task: Task) {
        if let t = self.task {
            t.view.removeFromSuperview()
        }
        self.task = task
        addSubview(task.view)
    }
}
