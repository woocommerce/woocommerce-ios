import XCTest
@testable import WooCommerce
@testable import Yosemite

final class WPComPlanNameSanitizerTests: XCTestCase {

    func test_free_trial_plan_is_sanitized() {
        // Given
        let freeTrialID = "1052"
        let plan = WPComSitePlan(id: freeTrialID, hasDomainCredit: false, expiryDate: Date())

        // When
        let sanitized = WPComPlanNameSanitizer.getPlanName(from: plan)

        XCTAssertEqual(sanitized, NSLocalizedString("Free Trial", comment: ""))
    }

    func test_wpcom_plan_is_sanitized() {
        // Given
        let plan = WPComSitePlan(id: "123", hasDomainCredit: false, name: "WordPress.com Business")

        // When
        let sanitized = WPComPlanNameSanitizer.getPlanName(from: plan)

        XCTAssertEqual(sanitized, NSLocalizedString("Business", comment: ""))
    }

    func test_wooExpress_plan_is_sanitized() {
        // Given
        let plan = WPComSitePlan(id: "123", hasDomainCredit: false, name: "Woo Express: Performance")

        // When
        let sanitized = WPComPlanNameSanitizer.getPlanName(from: plan)

        XCTAssertEqual(sanitized, NSLocalizedString("Performance", comment: ""))
    }

    func test_any_other_plan_is_not_sanitized() {
        // Given
        let plan = WPComSitePlan(id: "123", hasDomainCredit: false, name: "Plus")

        // When
        let sanitized = WPComPlanNameSanitizer.getPlanName(from: plan)

        XCTAssertEqual(sanitized, NSLocalizedString("Plus", comment: ""))
    }
}
