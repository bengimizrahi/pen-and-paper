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
    @IBOutlet weak var d1Button: UIBarButtonItem!
    
    var tasks = [Int : Task]()
    var orderOfTasks = [Int]()

    var originalHeight: CGFloat = 0.0

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

    @IBAction func d1Tapped() {
        for id in orderOfTasks {
            print("Task \(id) superview: \(tasks[id]!.view.superview != nil)")
        }
    }
}

extension TasksTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("tableView(_ tableView: UITableView, cellForRowAt indexPath: \(indexPath))")
        let cell = tableView.dequeueReusableCell(
                withIdentifier: "Cell", for: indexPath) as! TaskTableViewCell
        let taskId = orderOfTasks[indexPath.row]
        cell.setTask(tasks[taskId]!)
        print("    attached task id \(taskId)")
        return cell
    }
}

extension TasksTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        print("didEndDisplaying row at: \(indexPath)")
        let taskCell = cell as! TaskTableViewCell
        if let oy = taskCell.originalY {
            print("    cell was transformed, now reset!")
            taskCell.frame.origin.y = oy
            taskCell.originalY = nil
        }
//        print("    removing task with id \(taskCell.task!.id) from its superview")
//        taskCell.task!.view.removeFromSuperview()
    }
}

extension TasksTableViewController: TaskViewDelegate {
    func sizeBeganChanging(_ taskView: TaskView) {
        originalHeight = taskView.bounds.height
        for cell in self.tableView.visibleCells as! [TaskTableViewCell] {
            if cell.task!.view !== taskView {
                cell.originalY = cell.frame.origin.y
            }
        }
    }

    func sizeContinuedChanging(_ taskView: TaskView, deltaHeight: CGFloat) {
        let delta = taskView.bounds.height - originalHeight
        var offsetCells = false
        UIView.animate(withDuration: 0.1) {
            for cell in self.tableView.visibleCells as! [TaskTableViewCell] {
                if !offsetCells {
                    if cell.task!.view === taskView {
                        offsetCells = true
                        cell.frame.size.height = taskView.bounds.height
                    }
                } else {
                    cell.frame.origin.y = cell.originalY! + delta
                }
            }
        }
    }

    func sizeEndedChanging(_ taskView: TaskView, deltaHeight: CGFloat) {
        for cell in self.tableView.visibleCells as! [TaskTableViewCell] {
            print("from", cell.frame)
            if let y = cell.originalY {
                cell.frame.origin.y = y
                print("to", cell.frame)
                cell.originalY = nil
            }
        }
        let idx = orderOfTasks.index { $0 == taskView.task.id }!
        let idxPath = IndexPath(row: idx, section:0)
        tableView.performBatchUpdates({
            self.tableView.insertRows(at: [idxPath], with: .none)
            self.tableView.deleteRows(at: [idxPath], with: .none)
        }, completion: nil)
    }

    func resized(_ taskView: TaskView) {

    }
}
