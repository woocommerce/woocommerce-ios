import XCTest
@testable import WooCommerce
@testable import Yosemite

final class UpgradesViewModelTests: XCTestCase {

    let freeTrialID = "1052"
    let sampleSite = Site.fake().copy(siteID: 123, isWordPressComStore: true)

    func test_active_free_trial_plan_has_correct_view_model_values() {
        // Given
        let expireDate = Date().addingDays(14)
        let plan = WPComSitePlan(id: freeTrialID,
                                 hasDomainCredit: false,
                                 expiryDate: expireDate)

        let session = SessionManager.testingInstance
        let stores = MockStoresManager(sessionManager: session)
        let featureFlags = MockFeatureFlagService(isFreeTrialUpgradeEnabled: true)
        session.defaultSite = sampleSite

        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(plan))
            default:
                break
            }
        }

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores)
        let viewModel = UpgradesViewModel(stores: stores, storePlanSynchronizer: synchronizer, featureFlagService: featureFlags)
        viewModel.loadPlan()

        // Then
        XCTAssertEqual(viewModel.planName, NSLocalizedString("Free Trial", comment: ""))
        XCTAssertTrue(viewModel.planInfo.isNotEmpty)
        XCTAssertTrue(viewModel.shouldShowUpgradeButton)
        XCTAssertFalse(viewModel.shouldShowCancelTrialButton)
        XCTAssertNil(viewModel.errorNotice)
    }

    func test_expired_free_trial_plan_has_correct_view_model_values() {
        // Given
        let expireDate = Date().addingDays(-3)
        let plan = WPComSitePlan(id: freeTrialID,
                                 hasDomainCredit: false,
                                 expiryDate: expireDate)

        let session = SessionManager.testingInstance
        let stores = MockStoresManager(sessionManager: session)
        session.defaultSite = sampleSite
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(plan))
            default:
                break
            }
        }
        let synchronizer = StorePlanSynchronizer(stores: stores)
        let featureFlags = MockFeatureFlagService(isFreeTrialUpgradeEnabled: true)
        let viewModel = UpgradesViewModel(stores: stores, storePlanSynchronizer: synchronizer, featureFlagService: featureFlags)

        // When
        viewModel.loadPlan()

        // Then
        XCTAssertEqual(viewModel.planName, NSLocalizedString("Trial ended", comment: ""))
        XCTAssertTrue(viewModel.planInfo.isNotEmpty)
        XCTAssertTrue(viewModel.shouldShowUpgradeButton)
        XCTAssertFalse(viewModel.shouldShowCancelTrialButton)
        XCTAssertNil(viewModel.errorNotice)
    }

    func test_active_regular_plan_has_correct_view_model_values() {
        // Given
        let expireDate = Date().addingDays(300)
        let plan = WPComSitePlan(id: "another-id",
                                 hasDomainCredit: false,
                                 expiryDate: expireDate,
                                 name: "WordPress.com eCommerce")

        let session = SessionManager.testingInstance
        let stores = MockStoresManager(sessionManager: session)
        session.defaultSite = sampleSite
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(plan))
            default:
                break
            }
        }
        let synchronizer = StorePlanSynchronizer(stores: stores)
        let viewModel = UpgradesViewModel(stores: stores, storePlanSynchronizer: synchronizer)

        // When
        viewModel.loadPlan()

        // Then
        XCTAssertEqual(viewModel.planName, NSLocalizedString("eCommerce", comment: ""))
        XCTAssertTrue(viewModel.planInfo.isNotEmpty)
        XCTAssertFalse(viewModel.shouldShowUpgradeButton)
        XCTAssertFalse(viewModel.shouldShowCancelTrialButton)
        XCTAssertNil(viewModel.errorNotice)
    }

    func test_WooExpress_is_removed_from_plan_name() {
        // Given
        let expireDate = Date().addingDays(300)
        let plan = WPComSitePlan(id: "another-id",
                                 hasDomainCredit: false,
                                 expiryDate: expireDate,
                                 name: "Woo Express: Essential")

        let session = SessionManager.testingInstance
        let stores = MockStoresManager(sessionManager: session)
        session.defaultSite = sampleSite
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(plan))
            default:
                break
            }
        }
        let synchronizer = StorePlanSynchronizer(stores: stores)
        let viewModel = UpgradesViewModel(stores: stores, storePlanSynchronizer: synchronizer)

        // When
        viewModel.loadPlan()

        // Then
        XCTAssertEqual(viewModel.planName, NSLocalizedString("Essential", comment: ""))
    }

    func test_error_fetching_plan_has_correct_view_model_values() {
        // Given
        let session = SessionManager.testingInstance
        let stores = MockStoresManager(sessionManager: session)
        session.defaultSite = sampleSite
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                let error = NSError(domain: "", code: 0)
                completion(.failure(error))
            default:
                break
            }
        }
        let synchronizer = StorePlanSynchronizer(stores: stores)
        let viewModel = UpgradesViewModel(stores: stores, storePlanSynchronizer: synchronizer)

        // When
        viewModel.loadPlan()

        // Then
        XCTAssertTrue(viewModel.planName.isEmpty)
        XCTAssertTrue(viewModel.planInfo.isEmpty)
        XCTAssertFalse(viewModel.shouldShowUpgradeButton)
        XCTAssertFalse(viewModel.shouldShowCancelTrialButton)
        XCTAssertNotNil(viewModel.errorNotice)
    }

}
