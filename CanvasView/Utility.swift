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
    let reportOnExit: Bool

    init(reportOnExit: Bool) {
        startTime = Date()
        self.reportOnExit = reportOnExit
    }

    deinit {
        if reportOnExit {
            print("Elapsed time: \(timeInterval()) secs")
        }
    }

    func timeInterval() -> TimeInterval {
        let endTime = Date()
        let diff = endTime.timeIntervalSince(startTime)
        return diff
    }
}
