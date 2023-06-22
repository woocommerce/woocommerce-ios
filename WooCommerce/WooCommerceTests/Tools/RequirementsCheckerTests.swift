import XCTest
@testable import Yosemite
@testable import WooCommerce

final class RequirementsCheckerTests: XCTestCase {

    private let freeTrialID = "1052"

    // MARK: - checkSiteEligibility

    func test_checkSiteEligibility_skips_wpcom_plan_check_for_self_hosted_sites() {
        // Given
        let site = Site.fake().copy(isWordPressComStore: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = RequirementsChecker(stores: stores)

        var invokedWPComPlanCheck = false
        var invokedSiteAPICheck = false
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, _):
                invokedWPComPlanCheck = true
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveSiteAPI(_, _):
                invokedSiteAPICheck = true
            default:
                break
            }
        }

        // When
        checker.checkSiteEligibility(for: site)

        // Then
        XCTAssertFalse(invokedWPComPlanCheck)
        XCTAssertTrue(invokedSiteAPICheck)
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

    func test_checkSiteEligibility_returns_expiredWPComPlan_if_plan_expired() {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = RequirementsChecker(stores: stores)

        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                let sitePlan = WPComSitePlan(id: self.freeTrialID,
                                             hasDomainCredit: false,
                                             expiryDate: Date().addingDays(-3))
                completion(.success(sitePlan))
            default:
                break
            }
        }

        // When
        var checkResult: RequirementCheckResult?
        checker.checkSiteEligibility(for: site) { result in
            switch result {
            case .success(let value):
                checkResult = value
            case .failure:
                break
            }
        }

        // Then
        XCTAssertEqual(checkResult, .expiredWPComPlan)
    }

    func test_checkSiteEligibility_returns_expiredWPComPlan_if_plan_check_fails_with_noCurrentPlan() {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = RequirementsChecker(stores: stores)

        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.failure(LoadSiteCurrentPlanError.noCurrentPlan))
            default:
                break
            }
        }

        // When
        var checkResult: RequirementCheckResult?
        checker.checkSiteEligibility(for: site) { result in
            switch result {
            case .success(let value):
                checkResult = value
            case .failure:
                break
            }
        }

        // Then
        XCTAssertEqual(checkResult, .expiredWPComPlan)
    }

    func test_checkSiteEligibility_fails_if_plan_check_fails_with_error_other_than_noCurrentPlan() throws {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = RequirementsChecker(stores: stores)

        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.failure(NSError(domain: "test", code: 500)))
            default:
                break
            }
        }

        // When
        var checkResult: Result<RequirementCheckResult, Error>?
        checker.checkSiteEligibility(for: site) { result in
            checkResult = result
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(checkResult).isFailure)
    }

    func test_checkSiteEligibility_returns_validWCVersion_if_highest_Woo_version_is_3() {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = RequirementsChecker(stores: stores)

        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                let sitePlan = WPComSitePlan(id: self.freeTrialID,
                                             hasDomainCredit: false,
                                             expiryDate: Date().addingDays(14))
                completion(.success(sitePlan))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveSiteAPI(_, let onCompletion):
                onCompletion(.success(SiteAPI(siteID: site.siteID, namespaces: ["wc/v3"])))
            default:
                break
            }
        }

        // When
        var checkResult: RequirementCheckResult?
        checker.checkSiteEligibility(for: site) { result in
            switch result {
            case .success(let value):
                checkResult = value
            case .failure:
                break
            }
        }

        // Then
        XCTAssertEqual(checkResult, .validWCVersion)
    }

    func test_checkSiteEligibility_returns_invalidWCVersion_if_highest_Woo_version_is_not_3() {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = RequirementsChecker(stores: stores)

        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                let sitePlan = WPComSitePlan(id: self.freeTrialID,
                                             hasDomainCredit: false,
                                             expiryDate: Date().addingDays(14))
                completion(.success(sitePlan))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveSiteAPI(_, let onCompletion):
                onCompletion(.success(SiteAPI(siteID: site.siteID, namespaces: ["wc/v2"])))
            default:
                break
            }
        }

        // When
        var checkResult: RequirementCheckResult?
        checker.checkSiteEligibility(for: site) { result in
            switch result {
            case .success(let value):
                checkResult = value
            case .failure:
                break
            }
        }

        // Then
        XCTAssertEqual(checkResult, .invalidWCVersion)
    }

    func test_checkSiteEligibility_returns_failure_if_site_setting_check_fails() {
        // Given
        let site = Site.fake().copy(isWordPressComStore: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let checker = RequirementsChecker(stores: stores)

        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                let sitePlan = WPComSitePlan(id: self.freeTrialID,
                                             hasDomainCredit: false,
                                             expiryDate: Date().addingDays(14))
                completion(.success(sitePlan))
            default:
                break
            }
        }

        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveSiteAPI(_, let onCompletion):
                onCompletion(.failure(NSError(domain: "Test", code: 500)))
            default:
                break
            }
        }

        // When
        var checkResult: Result<RequirementCheckResult, Error>?
        checker.checkSiteEligibility(for: site) { result in
            checkResult = result
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(checkResult).isFailure)
    }
}
