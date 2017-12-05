//
//  ViewController.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 5.12.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var canvasView: CanvasView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.setStrokes([])
    }
}
