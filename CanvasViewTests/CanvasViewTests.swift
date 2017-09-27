//
//  CanvasViewTests.swift
//  CanvasViewTests
//
//  Created by Bengi Mizrahi on 26/09/2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import XCTest
@testable import CanvasView

class CanvasViewTests: XCTestCase {

    override func setUp() {
        super.setUp()

    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testExample() {
        let v = Vertex(location: CGPoint(x: 0, y: 0), force: 1.0)
        XCTAssertEqual(v.debugDescription, "Vertex(loc: (0.0, 0.0), force: 1.0, est: , est-exp: ")

        let v2 = Vertex(location: CGPoint(x: 0, y: 0), force: 1.0,
                       estimatedProperties: [.azimuth],
                       estimatedPropertiesExpectingUpdates: [.azimuth])
        XCTAssertEqual(v2.debugDescription, "Vertex(loc: (0.0, 0.0), force: 1.0, est: z, est-exp: z")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
