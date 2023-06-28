import XCTest
@testable import WooCommerce
import Yosemite

final class UpgradesViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345
    private var mockInAppPurchasesManager: MockInAppPurchasesForWPComPlansManager!
    private var stores: MockStoresManager!

    private var sut: UpgradesViewModel!

    override func setUp() {
        let plans = MockInAppPurchasesForWPComPlansManager.Defaults.debugInAppPurchasesPlans
        mockInAppPurchasesManager = MockInAppPurchasesForWPComPlansManager(plans: plans)
        stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case .isRemoteFeatureFlagEnabled(.hardcodedPlanUpgradeDetailsMilestone1AreAccurate, defaultValue: _, let completion):
                completion(true)
            default:
                break
            }
        }
        sut = UpgradesViewModel(siteID: sampleSiteID, inAppPurchasesPlanManager: mockInAppPurchasesManager, stores: stores)
    }

    func test_upgrades_are_initialized_with_empty_values() async {
        // Given, When
        let sut = UpgradesViewModel(siteID: sampleSiteID,
                                    inAppPurchasesPlanManager: MockInAppPurchasesForWPComPlansManager(plans: []),
                                    stores: stores)

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
                                    inAppPurchasesPlanManager: inAppPurchasesManager,
                                    stores: stores)

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

    func test_upgradeViewState_when_initialized_is_loading_state() {
        // Given, When
        // see `setUp`

        // Then
        XCTAssertEqual(sut.upgradeViewState, .loading)
    }

    func test_upgradeViewState_when_initialized_by_non_owner_then_state_is_prepurchaseError_userNotAllowedToUpgrade() {
        // Given
        let site = Site.fake().copy(isSiteOwner: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: site))
        let sut = UpgradesViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertEqual(sut.upgradeViewState, .prePurchaseError(.userNotAllowedToUpgrade))
    }

    func test_upgradeViewState_when_retrievePlanDetailsIfAvailable_fetching_error_then_upgradeViewState_is_prePurchaseError_fetchError() async {
        // Given
        let inAppPurchasesManager = MockInAppPurchasesForWPComPlansManager(plans: [])
        let sut = UpgradesViewModel(siteID: sampleSiteID,
                                    inAppPurchasesPlanManager: inAppPurchasesManager)

        let expectedError: PrePurchaseError = .fetchError

        // When
        await sut.fetchPlans()

        // Then
        XCTAssertEqual(sut.upgradeViewState, .prePurchaseError(expectedError))
    }

    func test_upgradeViewState_when_retrievePlanDetailsIfAvailable_has_plans_then_upgradeViewState_is_loaded() async {
        // Given
        let expectedPlan = UpgradesViewModelTests.makeWPComPlanProduct()
        let inAppPurchasesManager = MockInAppPurchasesForWPComPlansManager(plans: [expectedPlan])
        let sut = UpgradesViewModel(siteID: sampleSiteID,
                                    inAppPurchasesPlanManager: inAppPurchasesManager)

        // When
        await sut.fetchPlans()

        // Then
        XCTAssertEqual(sut.upgradeViewState.caseString, "loaded")
    }
}

// MARK: Helpers
//
private extension UpgradeViewState {
    var caseString: String {
        switch self {
        case .loaded:
            return "loaded"
        default:
            return ""
        }
    }
}
private extension UpgradesViewModelTests {
    struct MockWPComPlanProduct: WPComPlanProduct {
        var displayName: String
        var description: String
        var id: String
        var displayPrice: String
    }

    static func makeWPComPlanProduct() -> WPComPlanProduct {
        MockInAppPurchasesForWPComPlansManager.Plan(
                displayName: "Test awesome plan",
                description: "All the Woo, all the time",
                id: "debug.woocommerce.express.essential.monthly",
                displayPrice: "$1.50")
    }

    static func makeWooWPComPlan() -> WooWPComPlan {
        let woocomplan = MockInAppPurchasesForWPComPlansManager.Plan(
                displayName: "Test awesome plan",
                description: "All the Woo, all the time",
                id: "debug.woocommerce.express.essential.monthly",
                displayPrice: "$1.50")
        let wooplan = WooPlan(id: "",
                              name: "",
                              shortName: "",
                              planFrequency: WooPlan.PlanFrequency.month,
                              planDescription: "",
                              headerImageFileName: "",
                              headerImageCardColor: .red,
                              planFeatureGroups: [])

        return WooWPComPlan(wpComPlan: woocomplan,
                            wooPlan: wooplan,
                            hardcodedPlanDataIsValid: true)
    }
}
