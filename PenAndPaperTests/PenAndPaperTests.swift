//
//  PenAndPaperTests.swift
//  PenAndPaperTests
//
//  Created by Bengi Mizrahi on 12.10.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import XCTest
@testable import PenAndPaper

class PenAndPaperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLinesIntersect() {
        let data = [
            (((-5.0, 0.0), (5.0, 0.0)), ((0.0, -5.0), (0.0, 5.0)), true),
            (((0.0, 0.0), (10.0, 10.0)), ((2.0, 2.0), (16.0, 4.0)), true),
            (((-2.0, 2.0), (-2.0, -2.0)), ((-2.0, 0.0), (0.0, 0.0)), true),
            (((0.0, 4.0), (4.0, 4.0)), ((4.0, 0.0), (4.0, 8.0)), true),
            (((0.0, 0.0), (10.0, 10.0)), ((2.0, 2.0), (6.0, 6.0)), true),
            (((6.0, 8.0), (14.0, -2.0)), ((6.0, 8.0), (14.0, -2.0)), true),
            (((4.0, 4.0), (12.0, 12.0)), ((6.0, 8.0), (8.0, 10.0)), false),
            (((-8.0, 8.0), (-4.0, 2.0)), ((-4.0, 6.0), (0.0, 0.0)), false),
            (((0.0, 0.0), (0.0, 2.0)), ((4.0, 4.0), (4.0, 6.0)), false),
            (((0.0, 0.0), (0.0, 2.0)), ((4.0, 4.0), (6.0, 4.0)), false),
            (((-2.0, -2.0), (4.0, 4.0)), ((6.0, 6.0), (10.0, 10.0)), false),
            (((0.0, 0.0), (2.0, 2.0)), ((4.0, 0.0), (1.0, 4.0)), false),
            (((2.0, 2.0), (8.0, 2.0)), ((4.0, 4.0), (6.0, 4.0)), false),
            (((4.0, 2.0), (4.0, 4.0)), ((10.0, 0.0), (0.0, 8.0)), false),
        ]
        for (((x0, y0), (x1, y1)), ((x2, y2), (x3, y3)), result) in data {
            let line1 = (CGPoint(x: x0, y: y0), CGPoint(x: x1, y: y1))
            let line2 = (CGPoint(x: x2, y: y2), CGPoint(x: x3, y: y3))
            XCTAssertEqual(linesIntersect(a: line1, b: line2), result)
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
