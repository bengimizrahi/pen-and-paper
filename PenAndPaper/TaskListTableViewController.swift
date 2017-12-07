//
//  TaskListTableViewController.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 7.12.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class TaskListTableViewController : UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var parentTask: Task? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
    }
}

extension TaskListTableViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parentTask!.subTasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskViewController") as! TaskViewController
        let task = parentTask!.subTasks[indexPath.row]
        cell.taskDescriptionImageView.image = task.cachedImage
        if !(task.subTasks.isEmpty) {
            cell.subtasksViewController = TaskListTableViewController()
            cell.subtasksViewController!.parentTask = task
            cell.subtasksContainerView.addSubview(cell.subtasksViewController!.view)
        }
        return cell
    }
}
