import XCTest
import Foundation
import Yosemite
@testable import WooCommerce

/// `ProductVisibility` Tests
///
final class ProductVisibilityTests: XCTestCase {

    func test_ProductVisibility_with_empty_password() {
        let visibility = ProductVisibility(status: .published, password: nil)
        let visibility2 = ProductVisibility(status: .published, password: "")

        XCTAssertEqual(visibility, .public)
        XCTAssertEqual(visibility2, .public)
    }

    func test_ProductVisibility_with_private_status() {
        let visibility = ProductVisibility(status: .privateStatus, password: nil)

        XCTAssertEqual(visibility, .private)
    }

    func test_ProductVisibility_with_pending_status() {
        let visibility = ProductVisibility(status: .pending, password: nil)

        XCTAssertEqual(visibility, .public)
    }

    func test_ProductVisibility_with_draft_status() {
        let visibility = ProductVisibility(status: .draft, password: nil)

        XCTAssertEqual(visibility, .public)
    }

    func test_ProductVisibility_password_protected() {
        let visibility = ProductVisibility(status: .published, password: "1234")

        XCTAssertEqual(visibility, .passwordProtected)
    }

}
