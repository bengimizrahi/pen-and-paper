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
    weak var eraserButton: UIButton!
    
    var tasks = [UUID : Task]()
    var orderOfTasks = [UUID]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.panGestureRecognizer.allowedTouchTypes =
                [NSNumber(value: UITouchType.direct.rawValue)]
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = TaskView.kLineHeight

        let eraserButton = UIButton(type: .custom)
        eraserButton.setTitle("Eraser", for: .normal)
        eraserButton.setTitleColor(UIColor.red, for: .normal)
        eraserButton.addTarget(self, action: #selector(eraserButtonTapped), for: [.touchUpInside])
        let eraserBarButtonItem = UIBarButtonItem(customView: eraserButton)
        navigationItem.rightBarButtonItems?.append(eraserBarButtonItem)
        self.eraserButton = eraserButton
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func addButtonTapped() {
        let task = Task()
        task.view.delegate = self
        tasks[task.id] = task
        orderOfTasks.insert(task.id, at: 0)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        tableView.endUpdates()
    }

    @objc func eraserButtonTapped() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.eraserButtonSelected = !delegate.eraserButtonSelected
        let backgroundColor = delegate.eraserButtonSelected ? UIColor.lightGray : UIColor.clear
        eraserButton.backgroundColor = backgroundColor
    }
}

extension TasksTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
                withIdentifier: "Cell", for: indexPath) as! TaskTableViewCell
        let taskId = orderOfTasks[indexPath.row]
        cell.setTask(tasks[taskId]!)
        return cell
    }
}

extension TasksTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let taskId = orderOfTasks[indexPath.row]
        let task = tasks[taskId]!
        return task.view.intrinsicContentSize.height
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
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
