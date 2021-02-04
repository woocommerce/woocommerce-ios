import XCTest

/// Asserts that a collection is empty.
///
public func assertEmpty<T: Collection>(_ collection: T, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(collection.isEmpty, "Expected collection \(collection) to be empty.", file: file, line: line)
}

/// Asserts that a collection is not empty.
///
public func assertNotEmpty<T: Collection>(_ collection: T, file: StaticString = #file, line: UInt = #line) {
    XCTAssertFalse(collection.isEmpty, "Expected collection \(collection) to not be empty.", file: file, line: line)
}

/// Asserts that `lhs` has the same pointer address as `rhs`.
///
public func assertThat(_ lhs: AnyObject?, isIdenticalTo rhs: AnyObject?, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(lhs === rhs,
                  "Expected object \(String(describing: lhs)) to have the same pointer address as \(String(describing: rhs)).",
                  file: file,
                  line: line)
}

/// Asserts that `subject` contains the given string.
///
public func assertThat(_ subject: String, contains value: String, file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(subject.contains(value),
                  "Expected “\(subject)” to contain “\(value)”.",
                  file: file,
                  line: line)
}

/// Asserts that `subject`'s type is **exactly** `expectedType`.
///
/// If `subject`'s type is just a subclass of `expectedType`, then this will fail.
///
public func assertThat<T>(_ subject: Any?, isAnInstanceOf expectedType: T.Type, file: StaticString = #file, line: UInt = #line) {
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
