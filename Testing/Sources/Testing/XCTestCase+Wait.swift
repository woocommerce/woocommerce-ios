
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
                            timeout: TimeInterval = 0.2,
                            _ block: (XCTestExpectation) -> ()) {
        let exp = expectation(description: description ?? "")
        exp.expectedFulfillmentCount = count
        block(exp)
        wait(for: [exp], timeout: timeout)
    }
}
