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
    
    func setTask(_ newTask: Task) {
        if let t = task {
            t.view.removeFromSuperview()
        }
        task = newTask
        contentView.addSubview(task!.view)
    }
}
