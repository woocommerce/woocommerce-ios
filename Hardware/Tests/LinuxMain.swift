import XCTest

import HardwareTests

var tests = [XCTestCaseEntry]()
tests += HardwareTests.allTests()
XCTMain(tests)
