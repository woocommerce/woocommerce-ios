import XCTest
@testable import WooCommerce

final class UpgradesViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345
    private var mockInAppPurchasesManager: MockInAppPurchasesForWPComPlansManager!

    private var sut: UpgradesViewModel!

    override func setUp() {
        let plans = MockInAppPurchasesForWPComPlansManager.Defaults.debugInAppPurchasesPlans
        mockInAppPurchasesManager = MockInAppPurchasesForWPComPlansManager(plans: plans)
        sut = UpgradesViewModel(siteID: sampleSiteID, inAppPurchasesPlanManager: mockInAppPurchasesManager)
    }

    func test_upgrades_are_initialized_with_empty_values() async {
        // Given, When
        let sut = UpgradesViewModel(siteID: sampleSiteID,
                                    inAppPurchasesPlanManager: MockInAppPurchasesForWPComPlansManager(plans: []))

        // Then
        XCTAssert(sut.wpcomPlans.isEmpty)
        XCTAssert(sut.entitledWpcomPlanIDs.isEmpty)
    }

    func test_upgrades_when_fetchPlans_is_invoked_then_fetch_mocked_wpcom_plan() async {
        // Given
        // see `setUp`

        // When
        await sut.fetchPlans()

        // Then
        assertEqual("Debug Essential Monthly", sut.wpcomPlans.first?.displayName)
        assertEqual("1 Month of Debug Essential", sut.wpcomPlans.first?.description)
        assertEqual("debug.woocommerce.express.essential.monthly", sut.wpcomPlans.first?.id)
        assertEqual("$99.99", sut.wpcomPlans.first?.displayPrice)
    }

    func test_upgrades_when_retrievePlanDetailsIfAvailable_retrieves_debug_wpcom_plan() async {
        // Given (no injected plans)
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
        let expectedPlan: WPComPlanProduct = MockInAppPurchasesForWPComPlansManager.Plan(
                displayName: "Test awesome plan",
                description: "All the Woo, all the time",
                id: "debug.woocommerce.express.essential.monthly",
                displayPrice: "$1.50")
        let inAppPurchasesManager = MockInAppPurchasesForWPComPlansManager(plans: [expectedPlan])
        let sut = UpgradesViewModel(siteID: sampleSiteID,
                                    inAppPurchasesPlanManager: inAppPurchasesManager)

        // When
        await sut.fetchPlans()
        let wpcomPlan = sut.retrievePlanDetailsIfAvailable(.essentialMonthly)

        // Then
        assertEqual("Test awesome plan", wpcomPlan?.displayName)
        assertEqual("All the Woo, all the time", wpcomPlan?.description)
        assertEqual("debug.woocommerce.express.essential.monthly", wpcomPlan?.id)
        assertEqual("$1.50", wpcomPlan?.displayPrice)
    }
}
