
import Foundation
import XCTest

/// Additional assertions to help with readability in tests.
///
extension XCTestCase {
    /// Asserts that an array is empty.
    ///
    func assertEmpty<Element>(_ array: [Element]) {
        XCTAssertTrue(array.isEmpty)
    }
}
