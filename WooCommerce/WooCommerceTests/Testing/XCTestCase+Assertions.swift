
import Foundation
import XCTest

/// Additional assertions to help with readability in tests.
///
extension XCTestCase {
    /// Asserts that an array is empty.
    ///
    func assertEmpty<Element>(_ array: [Element], file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(array.isEmpty, "Expected array \(array) to be empty.", file: file, line: line)
    }
}
