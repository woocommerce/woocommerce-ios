import XCTest
@testable import WooCommerce

class DeveloperEmailCheckerTests: XCTestCase {
    private let developerEmailChecker = DeveloperEmailChecker()

    func testAutomatticEmail() {
        let email = "dev@automattic.com"
        XCTAssertTrue(developerEmailChecker.isDeveloperEmail(email: email))
    }

    func testA8cEmail() {
        let email = "dev@a8c.com"
        XCTAssertTrue(developerEmailChecker.isDeveloperEmail(email: email))
    }

    func testGmail() {
        let email = "dev@gmail.com"
        XCTAssertFalse(developerEmailChecker.isDeveloperEmail(email: email))
    }
}
