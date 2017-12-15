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

    func setupAsRoot() {
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add,
                                           target: self,
                                           action: #selector(handleAddBarButtonTap))
        navigationItem.rightBarButtonItems = [addBarButton]
    }

    @objc func handleAddBarButtonTap() {
        let canvasViewController = CanvasViewController()
        let navigationController = UINavigationController(rootViewController: canvasViewController)
        navigationController.modalTransitionStyle = .crossDissolve
        navigationController.modalPresentationStyle = .custom
        navigationController.transitioningDelegate = self
        present(navigationController, animated: true, completion: nil);
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
        if !task.subTasks.isEmpty {
            cell.subtasksViewController = TaskListTableViewController()
            cell.subtasksViewController!.parentTask = task
            cell.subtasksContainerView.addSubview(cell.subtasksViewController!.view)
        }
        return cell
    }
}

extension TaskListTableViewController : UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        return CanvasViewPresentationController(presentedViewController: presented,
                                                presenting: presenting)
    }
}
