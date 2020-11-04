import XCTest

import FakesTests

var tests = [XCTestCaseEntry]()
tests += FakesTests.allTests()
XCTMain(tests)
