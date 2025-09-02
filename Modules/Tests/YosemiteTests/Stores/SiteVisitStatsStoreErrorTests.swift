import XCTest
@testable import Yosemite
@testable import Networking

class SiteStatsStoreErrorTests: XCTestCase {
    func testNoPermissionError() {
        let remoteError = NetworkError.from(
            dotcomError: DotcomError.noStatsPermission,
            originalNetworkError: NetworkError.unacceptableStatusCode(statusCode: 401, response: nil))

        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .noPermission)
    }

    func testStatsModuleDisabledError() {
        let remoteError = NetworkError.from(
            dotcomError: DotcomError.statsModuleDisabled,
            originalNetworkError: NetworkError.unacceptableStatusCode(statusCode: 400, response: nil))
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .statsModuleDisabled)
    }

    func testOtherDotcomError() {
        let remoteError = NetworkError.from(
            dotcomError: DotcomError.unknown(code: "something_else", message: "This blog does not have a coffee machine connected"),
            originalNetworkError: NetworkError.unacceptableStatusCode(statusCode: 400, response: nil))
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .unknown)
    }

    func testNonNetworkRemoteError() {
        let remoteError = NSError(domain: "Woo", code: 404, userInfo: nil)
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .unknown)
    }
}
