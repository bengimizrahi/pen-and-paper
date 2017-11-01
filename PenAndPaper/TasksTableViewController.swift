//
//  TasksTableViewController.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 30.10.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class TasksTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var tasks = [Task]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.panGestureRecognizer.requiresExclusiveTouchType = true
        tableView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouchType.direct.rawValue)]
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = TaskView.kLineHeight
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func addButtonTapped() {
        let task = Task()
        task.view.delegate = self
        tasks.insert(task, at: 0)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
}

extension TasksTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
                withIdentifier: "Cell", for: indexPath) as! TaskTableViewCell
        cell.setTask(tasks[indexPath.row])
        return cell
    }
}

extension TasksTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tasks[indexPath.row].view.intrinsicContentSize.height
    }
}

extension TasksTableViewController: TaskViewDelegate {
    func taskView(_ taskView: TaskView, heightChangedFrom oldHeight: CGFloat, to newHeight: CGFloat) {
        let delta = newHeight - oldHeight
        var offsetCells = false
        UIView.animate(withDuration: 0.1) {
            for cell in self.tableView.visibleCells as! [TaskTableViewCell] {
                if !offsetCells {
                    if cell.task!.view === taskView {
                        offsetCells = true
                        cell.frame.size.height += delta
                    }
                } else {
                    cell.frame.origin.y += delta
                }
            }
        }
    }

    func taskView(_ taskView: TaskView, commit height: CGFloat) {
        tableView.reloadData()
    }
}
