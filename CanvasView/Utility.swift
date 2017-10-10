//
//  Utility.swift
//  CanvasView
//
//  Created by Bengi Mizrahi on 28/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import Foundation

class Measure {

    let startTime: Date
    let function: (TimeInterval)->()

    init(function: @escaping (_ interval: TimeInterval)->()) {
        startTime = Date()
        self.function = function
    }

    deinit {
        function(timeInterval())
    }

    func timeInterval() -> TimeInterval {
        let endTime = Date()
        let diff = endTime.timeIntervalSince(startTime)
        return diff
    }
}

class LogFunc {

    let funcName: String

    init(_ funcName: String) {
        self.funcName = funcName
        print("Entering \(funcName)")
    }

    deinit {
        print("Exiting \(funcName)")
    }
}
