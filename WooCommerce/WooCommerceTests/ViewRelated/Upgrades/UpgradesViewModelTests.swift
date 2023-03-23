import XCTest
@testable import WooCommerce
@testable import Yosemite

final class UpgradesViewModelTests: XCTestCase {

    let sampleSiteID: Int64 = 123
    let freeTrialID = "1052"

    func test_active_free_trial_plan_has_correct_view_model_values() {
        // Given
        let expireDate = Date().addingDays(14)
        let plan = WPComSitePlan(id: freeTrialID,
                                 hasDomainCredit: false,
                                 expiryDate: expireDate)

        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(plan))
            default:
                break
            }
        }
        let viewModel = UpgradesViewModel(siteID: sampleSiteID, stores: stores)

        // When
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

        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(plan))
            default:
                break
            }
        }
        let viewModel = UpgradesViewModel(siteID: sampleSiteID, stores: stores)

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

        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(plan))
            default:
                break
            }
        }
        let viewModel = UpgradesViewModel(siteID: sampleSiteID, stores: stores)

        // When
        viewModel.loadPlan()

        // Then
        XCTAssertEqual(viewModel.planName, NSLocalizedString("eCommerce", comment: ""))
        XCTAssertTrue(viewModel.planInfo.isNotEmpty)
        XCTAssertFalse(viewModel.shouldShowUpgradeButton)
        XCTAssertFalse(viewModel.shouldShowCancelTrialButton)
        XCTAssertNil(viewModel.errorNotice)
    }

    func test_error_fetching_plan_has_correct_view_model_values() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                let error = NSError(domain: "", code: 0)
                completion(.failure(error))
            default:
                break
            }
        }
        let viewModel = UpgradesViewModel(siteID: sampleSiteID, stores: stores)

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
