import XCTest
@testable import Hardware

final class HardwareTests: XCTestCase {
    // A test to check if the build is failing because it is missing a report.xcresult
    func test_charge_status_exists() {
        XCTAssertNotNil(ChargeStatus.failed)
    }
}
