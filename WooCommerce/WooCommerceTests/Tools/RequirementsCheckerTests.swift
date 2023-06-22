import XCTest
@testable import Yosemite
@testable import WooCommerce

final class RequirementsCheckerTests: XCTestCase {

    func test_checkSiteEligibility_skips_wpcom_plan_check_for_self_hosted_sites() {
        // Given
        let site = Site.fake().copy(isWordPressComStore: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = RequirementsChecker(stores: stores)

        var invokedWPComPlanCheck = false
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, _):
                invokedWPComPlanCheck = true
            default:
                break
            }
        }

        // When
        checker.checkSiteEligibility(for: site)

        // Then
        XCTAssertFalse(invokedWPComPlanCheck)
    }

    func test_checkSiteEligibility_invokes_wpcom_plan_check_for_wpcom_sites() {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = RequirementsChecker(stores: stores)

        var invokedWPComPlanCheck = false
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, _):
                invokedWPComPlanCheck = true
            default:
                break
            }
        }

        // When
        checker.checkSiteEligibility(for: site)

        // Then
        XCTAssertTrue(invokedWPComPlanCheck)
    }
}
