//
//  ViewController.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 12.10.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var task = Task()
    
    @IBAction func eraserEnabled(_ sender: UIButton) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.eraserButtonSelected = true
    }

    @IBAction func eraserDisabled(_ sender: UIButton) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.eraserButtonSelected = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(task.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

