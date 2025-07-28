import XCTest
@testable import Yosemite
@testable import Networking

class SiteStatsStoreErrorTests: XCTestCase {
    func testNoPermissionError() {
        let remoteError = DotcomError.noStatsPermission
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .noPermission)
    }

    func testStatsModuleDisabledError() {
        let remoteError = DotcomError.statsModuleDisabled
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .statsModuleDisabled)
    }

    func testOtherDotcomError() {
        let remoteError = DotcomError.unknown(code: "invalid_blog", message: "This blog does not have Jetpack connected")
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .unknown)
    }

    func testNonDotcomRemoteError() {
        let remoteError = NSError(domain: "Woo", code: 404, userInfo: nil)
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .unknown)
    }
}
