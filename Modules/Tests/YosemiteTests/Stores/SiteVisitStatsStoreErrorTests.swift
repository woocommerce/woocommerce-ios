import XCTest
@testable import Yosemite
@testable import Networking

class SiteStatsStoreErrorTests: XCTestCase {
    @MainActor
    func testNoPermissionError() {
        let remoteError = DotcomError.noStatsPermission()
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .noPermission)
    }

    @MainActor
    func testStatsModuleDisabledError() {
        let remoteError = DotcomError.statsModuleDisabled()
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .statsModuleDisabled)
    }

    @MainActor
    func testOtherDotcomError() {
        let remoteError = DotcomError.unknown(code: "invalid_blog", message: "This blog does not have Jetpack connected", data: nil)
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .unknown)
    }

    @MainActor
    func testNonDotcomRemoteError() {
        let remoteError = NSError(domain: "Woo", code: 404, userInfo: nil)
        let error = SiteStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .unknown)
    }
}
