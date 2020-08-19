
import XCTest

extension XCTestCase {
    /// Creates an XCTestExpectation and waits for `block` to call `fulfill()`.
    ///
    /// Example usage:
    ///
    /// ```
    /// waitForExpectation(timeout: TimeInterval(10)) { expectation in
    ///     doSomethingInTheBackground {
    ///         expectation.fulfill()
    ///     }
    /// }
    /// ```
    ///
    public func waitForExpectation(description: String? = nil,
                            count: Int = 1,
                            timeout: TimeInterval = 1.0,
                            _ block: (XCTestExpectation) -> ()) {
        let exp = expectation(description: description ?? "")
        exp.expectedFulfillmentCount = count
        block(exp)
        wait(for: [exp], timeout: timeout)
    }

    /// Creates an `XCTestExpectation` and waits until `condition` returns `true`.
    ///
    /// Example usage:
    ///
    /// ```
    /// var valueThatIsUpdatedAsynchronously: Int = 0
    ///
    /// waitUntil {
    ///     valueThatIsUpdatedAsynchronously > 5
    /// }
    /// ```
    ///
    public func waitUntil(file: StaticString = #file,
                   line: UInt = #line,
                   timeout: TimeInterval = 1.0,
                   condition: @escaping (() -> Bool)) {
        let predicate = NSPredicate { _, _ -> Bool in
            return condition()
        }

        let exp = expectation(for: predicate, evaluatedWith: nil)

        let result = XCTWaiter.wait(for: [exp], timeout: timeout)
        switch result {
        case .timedOut:
            XCTFail("Timed out waiting for condition to return `true`.", file: file, line: line)
        default:
            break
        }
    }
}
