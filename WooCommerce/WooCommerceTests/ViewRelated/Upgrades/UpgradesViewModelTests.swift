import XCTest
@testable import WooCommerce

final class UpgradesViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345

    func test_upgrades_are_initialized_with_empty_values() async {
        // Given, When
        let sut = UpgradesViewModel(siteID: sampleSiteID)

        // Then
        XCTAssertTrue(sut.wpcomPlans.isEmpty)
        XCTAssertTrue(sut.entitledWpcomPlanIDs.isEmpty)
    }

    func test_upgrades_when_fetchPlans_is_invoked_then_fetch_debug_wpcom_plan() async {
        // Given
        let sut = UpgradesViewModel(siteID: sampleSiteID)

        // When
        await sut.fetchPlans()

        // Then
        XCTAssertEqual(sut.wpcomPlans.first?.displayName, "Debug Monthly")
        XCTAssertEqual(sut.wpcomPlans.first?.description, "1 Month of Debug Woo")
        XCTAssertEqual(sut.wpcomPlans.first?.id, "debug.woocommerce.ecommerce.monthly")
        XCTAssertEqual(sut.wpcomPlans.first?.displayPrice, "$69.99")
    }

    func test_upgrades_when_fetchPlans_is_invoked_then_fetch_mocked_wpcom_plan() async {
        // Given
        let plans = MockInAppPurchasesForWPComPlansManager.Defaults.debugInAppPurchasesPlans
        let inAppPurchasesManager = MockInAppPurchasesForWPComPlansManager(plans: plans)
        let sut = UpgradesViewModel(siteID: sampleSiteID,
                                    inAppPurchasesPlanManager: inAppPurchasesManager)

        // When
        await sut.fetchPlans()

        // Then
        XCTAssertEqual(sut.wpcomPlans.first?.displayName, "Debug Essential Monthly")
        XCTAssertEqual(sut.wpcomPlans.first?.description, "1 Month of Debug Essential")
        XCTAssertEqual(sut.wpcomPlans.first?.id, "debug.woocommerce.express.essential.monthly")
        XCTAssertEqual(sut.wpcomPlans.first?.displayPrice, "$99.99")
    }

    func test_upgrades_when_retrievePlanDetailsIfAvailable_retrieves_debug_wpcom_plan() async {
        // Given
        let fakeInAppPurchasesManager = MockInAppPurchasesForWPComPlansManager()
        let sut = UpgradesViewModel(siteID: sampleSiteID,
                                    inAppPurchasesPlanManager: fakeInAppPurchasesManager)

        // When
        await sut.fetchPlans()
        XCTAssertEqual(sut.wpcomPlans.first?.displayName, "Debug Monthly", "Precondition")

        let wpcomPlan = sut.retrievePlanDetailsIfAvailable(.essentialMonthly)

        // Then
        XCTAssertNil(wpcomPlan)
    }

    func test_upgrades_when_retrievePlanDetailsIfAvailable_retrieves_injected_wpcom_plan() async {
        // Given
        let plans = MockInAppPurchasesForWPComPlansManager.Defaults.debugInAppPurchasesPlans
        let inAppPurchasesManager = MockInAppPurchasesForWPComPlansManager(plans: plans)
        let sut = UpgradesViewModel(siteID: sampleSiteID,
                                    inAppPurchasesPlanManager: inAppPurchasesManager)

        // When
        await sut.fetchPlans()
        let wpcomPlan = sut.retrievePlanDetailsIfAvailable(.essentialMonthly)

        // Then
        XCTAssertEqual(wpcomPlan?.displayName, "Debug Essential Monthly")
        XCTAssertEqual(wpcomPlan?.description, "1 Month of Debug Essential")
        XCTAssertEqual(wpcomPlan?.id, "debug.woocommerce.express.essential.monthly")
        XCTAssertEqual(wpcomPlan?.displayPrice, "$99.99")
    }
}
