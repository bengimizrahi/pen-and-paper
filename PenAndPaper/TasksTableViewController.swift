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
    var selectedTask: Task? = nil
    var selectedIndexPath: IndexPath? = nil
    var freeFloatingCell = TaskTableViewCell(style: .default,
                                             reuseIdentifier: "TaskTableViewCell")
    var reloadingDeselectedCell = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self

        // Disable scrolling the table view with a stylus
        tableView.panGestureRecognizer.allowedTouchTypes =
                [NSNumber(value: UITouchType.direct.rawValue)]

        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = TaskView.kLineHeight
        tableView.allowsSelection = true

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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
                withIdentifier: "TaskTableViewCell", for: indexPath) as! TaskTableViewCell
        let taskId = orderOfTasks[indexPath.row]
        if let selIdxPath = selectedIndexPath, indexPath == selIdxPath && !reloadingDeselectedCell {
            cell.clearTask()
            //cell.isHidden = true
        } else {
            cell.setTask(tasks[taskId]!)
        }

        cell.tag = taskId.hashValue
        return cell
    }
}

extension TasksTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        print("tableView(_ tableView: ..., heightForRowAt indexPath: \(indexPath))")
        let taskId = orderOfTasks[indexPath.row]
        let task = tasks[taskId]!
        return task.view.intrinsicContentSize.height
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("tableView(_ tableView: ..., didSelectRowAt indexPath: \(indexPath))")
        let cell = tableView.cellForRow(at: indexPath) as! TaskTableViewCell

        // No-op if we are selecting an already selected cell
        guard indexPath != selectedIndexPath else { return }

        if let selectedTask = selectedTask {
            // Remove the previously selected task from the free floating cell
            selectedTask.view.removeFromSuperview()

            // Remove the free floating cell from the table view
            freeFloatingCell.removeFromSuperview()

            // Turn off edit mode for the previously selected task view
            selectedTask.view.controlState = .none

            // Put the previously selected task view back to its cell
            tableView.reloadData()
        }

        selectedTask = cell.task!
        selectedIndexPath = indexPath

        selectedTask!.view.removeFromSuperview()
        freeFloatingCell.setTask(selectedTask!)

        selectedTask!.view.controlState = .selected

        tableView.addSubview(freeFloatingCell)
        freeFloatingCell.frame = cell.frame
        freeFloatingCell.tag = -1
    }
}

extension TasksTableViewController: TaskViewDelegate {
    func taskView(_ taskView: TaskView, heightChangedFrom oldHeight: CGFloat, to newHeight: CGFloat) {
        freeFloatingCell.frame.size = taskView.intrinsicContentSize
    }

    func taskView(_ taskView: TaskView, commit height: CGFloat) {
    }
}
