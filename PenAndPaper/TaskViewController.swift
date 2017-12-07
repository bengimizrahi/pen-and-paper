//
//  TaskViewController.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 7.12.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class TaskViewController: UITableViewCell {
    @IBOutlet weak var taskDescriptionImageView: UIImageView!
    @IBOutlet weak var subtasksContainerView: UIView!
    var subtasksViewController: TaskListTableViewController? = nil
}
