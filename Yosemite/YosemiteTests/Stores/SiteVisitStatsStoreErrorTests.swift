import XCTest
@testable import Yosemite
@testable import Networking

class SiteVisitStatsStoreErrorTests: XCTestCase {
    func testStatsModuleDisabledError() {
        let remoteError = DotcomError.unknown(code: "invalid_blog", message: "This blog does not have the Stats module enabled")
        let error = SiteVisitStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .statsModuleDisabled)
    }

    func testOtherInvalidBlogError() {
        let remoteError = DotcomError.unknown(code: "invalid_blog", message: "This blog does not have Jetpack connected")
        let error = SiteVisitStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .unknown)
    }

    func testNonDotcomRemoteError() {
        let remoteError = NSError(domain: "Woo", code: 404, userInfo: nil)
        let error = SiteVisitStatsStoreError(error: remoteError)
        XCTAssertEqual(error, .unknown)
    }
}
