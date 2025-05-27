import XCTest
@testable import Networking

class BundleWooTests: XCTestCase {

    func testBuildNumberCanBeRead() {
        XCTAssertNotEqual("unknown", Bundle.main.buildNumber)
    }

    /// There's no CFBundleShortVersionString in Info.plist in a test environment, so we can't test it
//    func testMarketingVersionCanBeRead() {
//        XCTAssertNotEqual("unknown", Bundle.main.marketingVersion)
//    }
}
