import XCTest
import WordPressUI
@testable import Yosemite
@testable import WooCommerce

@MainActor
final class RequirementsCheckerTests: XCTestCase {

    private let freePlan = "free_plan"
    private var viewController: UINavigationController!

    override func setUp() {
        viewController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = viewController

        super.setUp()
    }

    override func tearDown() {
        viewController = nil
        super.tearDown()
    }

    // MARK: - checkSiteEligibility

    func test_checkSiteEligibility_returns_expiredWPComPlan_if_plan_expired() {
        // Given
        let site = Site.fake().copy(siteID: 123, plan: freePlan, wasEcommerceTrial: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: site))
        let checker = RequirementsChecker(stores: stores)

        // When
        var checkResult: RequirementCheckResult?
        waitForExpectation { expectation in
            checker.checkSiteEligibility(for: site) { result in
                switch result {
                case .success(let value):
                    checkResult = value
                    expectation.fulfill()
                case .failure:
                    break
                }
            }
        }

        // Then
        XCTAssertEqual(checkResult, .expiredWPComPlan)
    }

    func test_checkSiteEligibility_returns_validWCVersion_if_highest_Woo_version_is_3() {
        // Given
        let site = Site.fake().copy(siteID: 123)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: site))
        let checker = RequirementsChecker(stores: stores)

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
        waitForExpectation { expectation in
            checker.checkSiteEligibility(for: site) { result in
                switch result {
                case .success(let value):
                    checkResult = value
                    expectation.fulfill()
                case .failure:
                    break
                }
            }
        }

        // Then
        XCTAssertEqual(checkResult, .validWCVersion)
    }

    func test_checkSiteEligibility_returns_invalidWCVersion_if_highest_Woo_version_is_not_3() {
        // Given
        let site = Site.fake().copy(siteID: 123)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: site))
        let checker = RequirementsChecker(stores: stores)

        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveSiteAPI(_, let onCompletion):
                onCompletion(.success(SiteAPI(siteID: site.siteID, namespaces: ["wc/v2"])))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.failure(NSError(domain: "test", code: 404, userInfo: nil)))
            default:
                break
            }
        }

        // When
        var checkResult: RequirementCheckResult?
        waitForExpectation { expectation in
            checker.checkSiteEligibility(for: site) { result in
                switch result {
                case .success(let value):
                    checkResult = value
                    expectation.fulfill()
                case .failure:
                    break
                }
            }
        }

        // Then
        XCTAssertEqual(checkResult, .invalidWCVersion)
    }

    func test_checkSiteEligibility_returns_failure_if_site_setting_check_fails() {
        // Given
        let site = Site.fake().copy(siteID: 123)
        let stores = MockStoresManager(sessionManager: .makeForTesting(defaultSite: site))
        let checker = RequirementsChecker(stores: stores)

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
        waitForExpectation { expectation in
            checker.checkSiteEligibility(for: site) { result in
                checkResult = result
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(checkResult).isFailure)
    }

    // MARK: - checkEligibilityForDefaultStore

    func test_checkEligibilityForDefaultStore_presents_wc_version_alert_when_highest_Woo_version_is_not_3() {
        // Given
        let site = Site.fake().copy(siteID: 123)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        let checker = RequirementsChecker(stores: stores, baseViewController: viewController)

        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveSiteAPI(_, let onCompletion):
                onCompletion(.success(SiteAPI(siteID: site.siteID, namespaces: [])))
            default:
                break
            }
        }

        // When
        checker.checkEligibilityForDefaultStore()

        // Then
        waitUntil {
            self.viewController.presentedViewController is FancyAlertViewController
        }
    }

    func test_checkEligibilityForDefaultStore_presents_plan_upgrade_alert_for_wpcom_store_with_expired_free_trial_plan() {
        // Given
        let site = Site.fake().copy(siteID: 123, plan: freePlan)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        let checker = RequirementsChecker(stores: stores, baseViewController: viewController)

        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case .retrieveSiteAPI(_, let completion):
                completion(.success(SiteAPI(siteID: site.siteID, namespaces: [])))
            default:
                break
            }
        }

        // When
        checker.checkEligibilityForDefaultStore()

        // Then
        waitUntil {
            self.viewController.presentedViewController is UIAlertController
        }
    }
}
