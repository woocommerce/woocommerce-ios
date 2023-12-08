import XCTest
@testable import WooCommerce
import Yosemite

final class UpgradesViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 12345
    private var mockInAppPurchasesManager: MockInAppPurchasesForWPComPlansManager!
    private var stores: MockStoresManager!

    private var sut: UpgradesViewModel!

    @MainActor
    func createSut(alreadySubscribed: Bool = false,
                   isSiteOwner: Bool = true,
                   isIAPSupported: Bool = true,
                   plans: [WPComPlanProduct] = MockInAppPurchasesForWPComPlansManager.Defaults.essentialInAppPurchasesPlans) {

        mockInAppPurchasesManager = MockInAppPurchasesForWPComPlansManager(plans: plans,
                                                                           userIsEntitledToPlan: alreadySubscribed,
                                                                           isIAPSupported: isIAPSupported)

        let site = Site.fake().copy(isSiteOwner: isSiteOwner)

        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
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

    func test_if_user_has_active_in_app_purchases_then_returns_maximum_sites_upgraded_error() async {
        // Given
        await createSut(alreadySubscribed: true)

        // When
        await sut.prepareViewModel()

        // Then
        assertEqual(.prePurchaseError(.maximumSitesUpgraded), sut.upgradeViewState)
    }

    func test_upgrades_when_fetchPlans_is_invoked_then_fetch_mocked_wpcom_plan() async {
        // Given
        await createSut()

        // When
        await sut.prepareViewModel()

        // Then
        guard case .loaded(let plans) = sut.upgradeViewState,
              let plan = plans.first else {
            return XCTFail("expected `.loaded` state not found")
        }
        assertEqual("Essential Monthly", plan.wpComPlan.displayName)
        assertEqual("1 Month of Essential", plan.wpComPlan.description)
        assertEqual("woocommerce.express.essential.monthly", plan.wpComPlan.id)
        assertEqual("$99.99", plan.wpComPlan.displayPrice)
    }

    func test_upgrades_when_retrievePlanDetailsIfAvailable_retrieves_injected_wpcom_plan() async {
        // Given
        let expectedPlan: WPComPlanProduct = MockInAppPurchasesForWPComPlansManager.Plan(
                displayName: "Test awesome plan",
                description: "All the Woo, all the time",
                id: "woocommerce.express.essential.monthly",
                displayPrice: "$1.50")

        await createSut(plans: [expectedPlan])

        // When
        await sut.prepareViewModel()

        // Then
        guard case .loaded(let plans) = sut.upgradeViewState,
            let plan = plans.first else {
            return XCTFail("expected `.loaded` state not found")
        }
        assertEqual("Test awesome plan", plan.wpComPlan.displayName)
        assertEqual("All the Woo, all the time", plan.wpComPlan.description)
        assertEqual("woocommerce.express.essential.monthly", plan.wpComPlan.id)
        assertEqual("$1.50", plan.wpComPlan.displayPrice)
    }

    func test_upgradeViewState_when_initialized_is_loading_state() async {
        // Given, When
        await createSut()

        // Then
        assertEqual(.loading, sut.upgradeViewState)
    }

    func test_upgradeViewState_when_prepareViewModel_by_non_owner_then_state_is_prepurchaseError_userNotAllowedToUpgrade() async {
        // Given
        await createSut(isSiteOwner: false)

        // When
        await sut.prepareViewModel()

        // Then
        assertEqual(.prePurchaseError(.userNotAllowedToUpgrade), sut.upgradeViewState)
     }

    func test_upgradeViewState_when_IAP_are_not_supported_and_prepareViewModel_then_state_is_inAppPurchasesNotSupported() async {
        // Given
        await createSut(isIAPSupported: false)

        // When
        await sut.prepareViewModel()

        // Then
        assertEqual(.prePurchaseError(.inAppPurchasesNotSupported), sut.upgradeViewState)
    }

    func test_upgradeViewState_when_retrievePlanDetailsIfAvailable_fails_and_prepareViewModel_then_state_is_fetchError() async {
        // Given
        await createSut(plans: [])

        // When
        await sut.prepareViewModel()

        // Then
        assertEqual(.prePurchaseError(.fetchError), sut.upgradeViewState)
    }
}
