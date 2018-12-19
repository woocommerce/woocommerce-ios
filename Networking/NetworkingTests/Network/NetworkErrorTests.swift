import XCTest
@testable import Networking


/// NetworkError Tests
///
class NetworkErrorTests: XCTestCase {

    /// Verifies that statusCode(s) within the "Successful Range" [200, 299) yield nil errors.
    ///
    func testSuccessStatusCodesYieldNilNetworkErrors() {
        XCTAssertNil(NetworkError(from: 200))
        XCTAssertNil(NetworkError(from: 299))
    }

    /// Verifies that (not defined) Network Errors are wrapped within a `.unacceptableStatusCode` case
    ///
    func testUnknownErrorsAreCaughtByUnacceptableEnumCase() {
        guard case let .unacceptableStatusCode(statusCode)? = NetworkError(from: 300) else {
            XCTFail()
            return
        }

        XCTAssertEqual(statusCode, 300)
    }

    /// Verifies that NotFound is properly parsed.
    ///
    func testNotFoundErrorIsProperlyParsed() {
        guard case .notFound? = NetworkError(from: 404) else {
            XCTFail()
            return
        }
    }
}
