import XCTest
import Foundation
import Yosemite
@testable import WooCommerce

/// `ProductVisibility` Tests
///
final class ProductVisibilityTests: XCTestCase {

    func testProductVisibilityWithEmptyPassword() {
        let visibility = ProductVisibility(status: .publish, password: nil)
        let visibility2 = ProductVisibility(status: .publish, password: "")

        XCTAssertEqual(visibility, .public)
        XCTAssertEqual(visibility2, .public)
    }

    func testProductVisibilityWithPrivateStatus() {
        let visibility = ProductVisibility(status: .privateStatus, password: nil)

        XCTAssertEqual(visibility, .private)
    }

    func testProductVisibilityWithPendingStatus() {
        let visibility = ProductVisibility(status: .pending, password: nil)

        XCTAssertEqual(visibility, .public)
    }

    func testProductVisibilityWithDraftStatus() {
        let visibility = ProductVisibility(status: .draft, password: nil)

        XCTAssertEqual(visibility, .public)
    }

    func testProductVisibilityPasswordProtected() {
        let visibility = ProductVisibility(status: .publish, password: "1234")

        XCTAssertEqual(visibility, .passwordProtected)
    }

}
