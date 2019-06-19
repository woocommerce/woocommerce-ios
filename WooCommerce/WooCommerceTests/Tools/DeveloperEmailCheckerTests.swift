import XCTest
@testable import WooCommerce

class DeveloperEmailCheckerTests: XCTestCase {
    func testAutomatticEmail() {
        let email = "dev@automattic.com"
        XCTAssertTrue(DeveloperEmailChecker.isDeveloperEmail(email: email))
    }

    func testA8cEmail() {
        let email = "dev@a8c.com"
        XCTAssertTrue(DeveloperEmailChecker.isDeveloperEmail(email: email))
    }

    func testGmail() {
        let email = "dev@gmail.com"
        XCTAssertFalse(DeveloperEmailChecker.isDeveloperEmail(email: email))
    }
}
