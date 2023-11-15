import XCTest
@testable import WooCommerce
@testable import Yosemite
import enum Alamofire.AFError

final class JetpackSetupCoordinatorTests: XCTestCase {

    private var navigationController: UINavigationController!

    override func setUp() {
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
        super.setUp()
    }

    override func tearDown() {
        navigationController = nil
        super.tearDown()
    }

    func test_benefit_modal_is_presented_correctly() {
        // Given
        let testSite = Site.fake()
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertTrue(navigationController.presentedViewController is JetpackBenefitsHostingController)
    }

    func test_handleAuthenticationUrl_returns_false_for_unsupported_url_scheme() throws {
        // Given
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let expectedScheme = "scheme"
        let coordinator = JetpackSetupCoordinator(site: testSite, dotcomAuthScheme: expectedScheme, rootViewController: navigationController)
        let url = try XCTUnwrap(URL(string: "example://handle-authentication"))

        // When
        let result = coordinator.handleAuthenticationUrl(url)

        // Then
        XCTAssertFalse(result)
    }

    func test_handleAuthenticationUrl_returns_false_for_missing_queries() throws {
        // Given
        let testSite = Site.fake().copy(siteID: -1)
        let expectedScheme = "scheme"
        let coordinator = JetpackSetupCoordinator(site: testSite, dotcomAuthScheme: expectedScheme, rootViewController: navigationController)
        let url = try XCTUnwrap(URL(string: "scheme://magic-login"))

        // When
        let result = coordinator.handleAuthenticationUrl(url)

        // Then
        XCTAssertFalse(result)
    }

    func test_handleAuthenticationUrl_returns_false_for_incorrect_host_name() throws {
        // Given
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let expectedScheme = "scheme"
        let coordinator = JetpackSetupCoordinator(site: testSite, dotcomAuthScheme: expectedScheme, rootViewController: navigationController)
        let url = try XCTUnwrap(URL(string: "scheme://handle-authentication?token=test"))

        // When
        let result = coordinator.handleAuthenticationUrl(url)

        // Then
        XCTAssertFalse(result)
    }

    func test_handleAuthenticationUrl_returns_true_for_correct_url_and_sufficient_queries() throws {
        // Given
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let expectedScheme = "scheme"
        let coordinator = JetpackSetupCoordinator(site: testSite, dotcomAuthScheme: expectedScheme, rootViewController: navigationController)
        let url = try XCTUnwrap(URL(string: "scheme://magic-login?token=test"))

        // When
        let result = coordinator.handleAuthenticationUrl(url)

        // Then
        XCTAssertTrue(result)
    }

    func test_handleAuthenticationUrl_presents_role_error_if_user_does_not_have_admin_role() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false, defaultRoles: [.shopManager]))
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let expectedScheme = "scheme"
        let coordinator = JetpackSetupCoordinator(site: testSite, dotcomAuthScheme: expectedScheme, rootViewController: navigationController, stores: stores)
        let url = try XCTUnwrap(URL(string: "scheme://magic-login?token=test"))

        let expectedAccount = Account(userID: 123, displayName: "Test", email: "test@example.com", username: "test", gravatarUrl: nil)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .loadWPComAccount(_, onCompletion):
                onCompletion(expectedAccount)
            case let .fetchJetpackUser(completion):
                completion(.success(JetpackUser.fake()))
            default:
                break
            }
        }
        stores.mockJetpackCheck()

        // When
        _ = coordinator.handleAuthenticationUrl(url)

        // Then
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is AdminRoleRequiredHostingController
        }
    }

    func test_handleAuthenticationUrl_presents_jetpack_setup_flow_after_fetching_wpcom_account_and_jetpack_user() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let expectedScheme = "scheme"
        let coordinator = JetpackSetupCoordinator(site: testSite, dotcomAuthScheme: expectedScheme, rootViewController: navigationController, stores: stores)
        let url = try XCTUnwrap(URL(string: "scheme://magic-login?token=test"))

        let expectedAccount = Account(userID: 123, displayName: "Test", email: "test@example.com", username: "test", gravatarUrl: nil)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .loadWPComAccount(_, onCompletion):
                onCompletion(expectedAccount)
            case let .fetchJetpackUser(completion):
                completion(.success(JetpackUser.fake()))
            default:
                break
            }
        }
        stores.mockJetpackCheck()

        // When
        _ = coordinator.handleAuthenticationUrl(url)

        // Then
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is JetpackSetupHostingController
        }
    }

    func test_handleAuthenticationUrl_proceeds_to_authenticate_user_if_jetpack_is_already_connected() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let expectedScheme = "scheme"
        let coordinator = JetpackSetupCoordinator(site: testSite, dotcomAuthScheme: expectedScheme, rootViewController: navigationController, stores: stores)
        let url = try XCTUnwrap(URL(string: "scheme://magic-login?token=test"))

        let expectedAccount = Account(userID: 123, displayName: "Test", email: "test@example.com", username: "test", gravatarUrl: nil)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .loadWPComAccount(_, onCompletion):
                onCompletion(expectedAccount)
            case let .fetchJetpackUser(completion):
                let dotcomUser = DotcomUser.fake().copy(id: expectedAccount.userID, username: expectedAccount.username, email: expectedAccount.email)
                completion(.success(JetpackUser.fake().copy(wpcomUser: dotcomUser)))
            default:
                break
            }
        }

        let expectedSite = Site.fake().copy(siteID: 44, url: "https://example.com")
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .synchronizeSitesAndReturnSelectedSiteInfo(_, let onCompletion):
                onCompletion(.success(expectedSite))
            case .synchronizeAccount(let onCompletion):
                onCompletion(.success(expectedAccount))
            case .synchronizeAccountSettings(_, let onCompletion):
                onCompletion(.success(AccountSettings.fake()))
            case .synchronizeSites(_, let onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        stores.mockJetpackCheck()

        // When
        _ = coordinator.handleAuthenticationUrl(url)

        // Then
        waitUntil {
            stores.sessionManager.defaultSite == expectedSite
        }
        assertEqual(expectedSite.siteID, stores.sessionManager.defaultStoreID)
        assertEqual(expectedAccount, stores.sessionManager.defaultAccount)
    }
}

private extension MockStoresManager {
    func mockJetpackCheck(isJetpackInstalled: Bool = false,
                          isJetpackActive: Bool = false) {
        whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .synchronizeSystemPlugins(_, onCompletion):
                onCompletion(.success([.fake().copy(name: isJetpackInstalled ? "Jetpack" : "Plugin", active: isJetpackActive)]))
            default:
                break
            }
        }

    }
}
