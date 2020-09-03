import XCTest

/// Asserts that an array is empty.
///
public func assertEmpty<Element>(_ array: [Element], file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(array.isEmpty, "Expected array \(array) to be empty.", file: file, line: line)
}
