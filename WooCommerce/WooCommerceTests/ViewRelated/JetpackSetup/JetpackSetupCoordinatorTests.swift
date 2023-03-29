import XCTest
@testable import WooCommerce
@testable import Yosemite
import enum Alamofire.AFError

final class JetpackSetupCoordinatorTests: XCTestCase {

    private var stores: MockStoresManager!
    private var navigationController: UINavigationController!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController
        super.setUp()
    }

    override func tearDown() {
        stores = nil
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

    func test_installation_flow_for_jcp_sites_is_presented_for_jcp_sites() throws {
        // Given
        let testSite = Site.fake().copy(siteID: 123, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        let benefitModal = try XCTUnwrap(navigationController.presentedViewController as? JetpackBenefitsHostingController)
        benefitModal.rootView.installAction(.failure(JetpackBenefitsViewModel.FetchJetpackUserError.notSupportedForJCPSites))
        waitUntil {
            self.navigationController.presentedViewController is JCPJetpackInstallHostingController
        }
    }

    func test_wpcom_email_screen_is_presented_for_non_jetpack_sites_without_jetpack_if_user_is_admin() throws {
        // Given
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let mockSessionManager = MockSessionManager()
        mockSessionManager.defaultRoles = [.administrator]
        let stores = DefaultStoresManager(sessionManager: mockSessionManager)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController, stores: stores)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        let benefitModal = try XCTUnwrap(navigationController.presentedViewController as? JetpackBenefitsHostingController)
        benefitModal.rootView.installAction(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))))

        // Then
        waitUntil {
            self.navigationController.presentedViewController is UINavigationController
        }
        let navigationController = try XCTUnwrap(navigationController.presentedViewController as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is WPComEmailLoginHostingController)
    }

    func test_admin_required_screen_is_presented_for_non_jetpack_sites_without_jetpack_if_user_is_not_admin() throws {
        // Given
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let mockSessionManager = MockSessionManager()
        mockSessionManager.defaultRoles = [.shopManager]
        let stores = DefaultStoresManager(sessionManager: mockSessionManager)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController, stores: stores)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        let benefitModal = try XCTUnwrap(navigationController.presentedViewController as? JetpackBenefitsHostingController)
        benefitModal.rootView.installAction(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))))

        // Then
        waitUntil {
            benefitModal.presentedViewController is UINavigationController
        }
        let navigationController = try XCTUnwrap(benefitModal.presentedViewController as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is AdminRoleRequiredHostingController)
    }

    func test_admin_required_screen_is_presented_for_non_jetpack_sites_when_jetpack_connection_check_returns_403() throws {
        // Given
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)

        // When
        coordinator.showBenefitModal()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        let benefitModal = try XCTUnwrap(navigationController.presentedViewController as? JetpackBenefitsHostingController)
        benefitModal.rootView.installAction(.failure(AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403))))

        // Then
        waitUntil {
            benefitModal.presentedViewController is UINavigationController
        }
        let navigationController = try XCTUnwrap(benefitModal.presentedViewController as? UINavigationController)
        XCTAssertTrue(navigationController.topViewController is AdminRoleRequiredHostingController)
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

    func test_handleAuthenticationUrl_presents_jetpack_setup_flow_after_fetching_wpcom_account_and_jetpack_user() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
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

        // When
        _ = coordinator.handleAuthenticationUrl(url)

        // Then
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is JetpackSetupHostingController
        }
    }

    func test_handleAuthenticationUrl_proceeds_to_authenticate_user_if_jetpack_is_already_connected() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
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
