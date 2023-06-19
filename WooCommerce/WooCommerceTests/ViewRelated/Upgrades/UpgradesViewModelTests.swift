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
        XCTAssert(sut.entitledWpcomPlanIDs.isEmpty)
    }

    func test_upgrades_when_fetchPlans_is_invoked_then_fetch_mocked_wpcom_plan() async {
        // Given
        // see `setUp`

        // When
        await sut.fetchPlans()

        // Then
        guard case .loaded(let plan) = sut.upgradeViewState else {
            return XCTFail("expected `.loaded` state not found")
        }
        assertEqual("Debug Essential Monthly", plan.wpComPlan.displayName)
        assertEqual("1 Month of Debug Essential", plan.wpComPlan.description)
        assertEqual("debug.woocommerce.express.essential.monthly", plan.wpComPlan.id)
        assertEqual("$99.99", plan.wpComPlan.displayPrice)
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

        // Then
        guard case .loaded(let plan) = sut.upgradeViewState else {
            return XCTFail("expected `.loaded` state not found")
        }
        assertEqual("Test awesome plan", plan.wpComPlan.displayName)
        assertEqual("All the Woo, all the time", plan.wpComPlan.description)
        assertEqual("debug.woocommerce.express.essential.monthly", plan.wpComPlan.id)
        assertEqual("$1.50", plan.wpComPlan.displayPrice)
    }
}
