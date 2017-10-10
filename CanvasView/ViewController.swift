//
//  ViewController.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 10/10/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var testView: TestView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearButton.addTarget(self, action: #selector(clearButtonPressed), for: .touchUpInside)
        // Do any additional setup after loading the view.
    }

    @IBAction func clearButtonPressed() {
        testView.counter = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
