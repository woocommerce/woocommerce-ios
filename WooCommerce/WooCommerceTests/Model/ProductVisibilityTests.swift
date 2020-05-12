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

        XCTAssertEqual(visibility, .publicVisibility)
        XCTAssertEqual(visibility2, .publicVisibility)
    }

    func testProductVisibilityWithPrivateStatus() {
        let visibility = ProductVisibility(status: .privateStatus, password: nil)

        XCTAssertEqual(visibility, .privateVisibility)
    }

    func testProductVisibilityWithPendingStatus() {
        let visibility = ProductVisibility(status: .pending, password: nil)

        XCTAssertEqual(visibility, .publicVisibility)
    }

    func testProductVisibilityWithDraftStatus() {
        let visibility = ProductVisibility(status: .draft, password: nil)

        XCTAssertEqual(visibility, .publicVisibility)
    }

}
