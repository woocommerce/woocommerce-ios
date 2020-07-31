
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

    /// Asserts that `lhs` has the same pointer address as `rhs`.
    ///
    func assertThat(_ lhs: AnyObject?, isIdenticalTo rhs: AnyObject?, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(lhs === rhs,
                      "Expected object \(String(describing: lhs)) to have the same pointer address as \(String(describing: rhs)).",
                      file: file,
                      line: line)
    }

    /// Asserts that `subject` contains the given string.
    ///
    func assertThat(_ subject: String, contains value: String, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(subject.contains(value),
                      "Expected “\(subject)” to contain “\(value)”.",
                      file: file,
                      line: line)
    }

    /// Asserts that `subject`'s type is **exactly** `expectedType`.
    ///
    /// If `subject`'s type is just a subclass of `expectedType`, then this will fail.
    ///
    func assertThat<T>(_ subject: Any?, isAnInstanceOf expectedType: T.Type, file: StaticString = #file, line: UInt = #line) {
        guard let subject = subject else {
            XCTFail("Expected nil to be an instance of \(expectedType)",
                    file: file,
                    line: line)
            return
        }

        XCTAssertTrue(type(of: subject) == expectedType,
                      "Expected \(subject) to be an instance of \(expectedType)",
                      file: file,
                      line: line)
    }
}
