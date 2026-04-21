import XCTest
@testable import WooCommerce
@testable import Yosemite
import WordPressAuthenticator

final class JetpackSetupCoordinatorTests: XCTestCase {

    private var navigationController: UINavigationController!
    private let dotcomAuthScheme = "scheme"

    override func setUp() {
        navigationController = UINavigationController()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController = navigationController

        AuthenticationManager().initialize()

        super.setUp()
    }

    override func tearDown() {
        navigationController = nil
        super.tearDown()
    }

    func test_startSetup_when_feature_flag_disabled_then_presents_benefit_modal() {
        // Given
        let testSite = Site.fake()
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: false)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  featureFlagService: featureFlagService)

        // When
        coordinator.startSetup()
        waitUntil {
            self.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertTrue(navigationController.presentedViewController is JetpackBenefitsHostingController)
    }

    func test_handleAuthenticationUrl_returns_false_for_unsupported_url_scheme() throws {
        // Given
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)
        let url = try XCTUnwrap(URL(string: "example://handle-authentication"))

        // When
        let result = coordinator.handleAuthenticationUrl(url, dotcomAuthScheme: dotcomAuthScheme)

        // Then
        XCTAssertFalse(result)
    }

    func test_handleAuthenticationUrl_returns_false_for_missing_queries() throws {
        // Given
        let testSite = Site.fake().copy(siteID: -1)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)
        let url = try XCTUnwrap(URL(string: "\(dotcomAuthScheme)://magic-login"))

        // When
        let result = coordinator.handleAuthenticationUrl(url, dotcomAuthScheme: dotcomAuthScheme)

        // Then
        XCTAssertFalse(result)
    }

    func test_handleAuthenticationUrl_returns_false_for_incorrect_host_name() throws {
        // Given
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)
        let url = try XCTUnwrap(URL(string: "\(dotcomAuthScheme)://handle-authentication?token=test"))

        // When
        let result = coordinator.handleAuthenticationUrl(url, dotcomAuthScheme: dotcomAuthScheme)

        // Then
        XCTAssertFalse(result)
    }

    func test_handleAuthenticationUrl_returns_true_for_correct_url_and_sufficient_queries() throws {
        // Given
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController)
        let url = try XCTUnwrap(URL(string: "\(dotcomAuthScheme)://magic-login?token=test"))

        // When
        let result = coordinator.handleAuthenticationUrl(url, dotcomAuthScheme: dotcomAuthScheme)

        // Then
        XCTAssertTrue(result)
    }

    func test_handleAuthenticationUrl_presents_role_error_if_user_does_not_have_admin_role() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false, defaultRoles: [.shopManager]))
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController, stores: stores)
        let url = try XCTUnwrap(URL(string: "\(dotcomAuthScheme)://magic-login?token=test"))

        let expectedAccount = Account(userID: 123, displayName: "Test", email: "test@example.com", username: "test", gravatarUrl: nil)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .loadWPComAccount(_, onCompletion):
                onCompletion(expectedAccount)
            case let .fetchJetpackConnectionData(_, completion):
                completion(.failure(JetpackSetupCoordinator.JetpackCheckError.missingPermission))
            default:
                break
            }
        }
        stores.mockJetpackCheck()

        // When
        let result = coordinator.handleAuthenticationUrl(url, dotcomAuthScheme: dotcomAuthScheme)

        // Then
        XCTAssertTrue(result)
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is AdminRoleRequiredHostingController
        }
    }

    func test_handleAuthenticationUrl_presents_jetpack_setup_flow_after_fetching_wpcom_account_and_jetpack_user() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController, stores: stores)
        let expectedScheme = "scheme"
        let url = try XCTUnwrap(URL(string: "\(dotcomAuthScheme)://magic-login?token=test"))

        let expectedAccount = Account(userID: 123, displayName: "Test", email: "test@example.com", username: "test", gravatarUrl: nil)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .loadWPComAccount(_, onCompletion):
                onCompletion(expectedAccount)
            case let .fetchJetpackConnectionData(_, completion):
                completion(.success(JetpackConnectionData.fake()))
            default:
                break
            }
        }
        stores.mockJetpackCheck()

        // When
        let result = coordinator.handleAuthenticationUrl(url, dotcomAuthScheme: dotcomAuthScheme)

        // Then
        XCTAssertTrue(result)
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is JetpackSetupHostingController
        }
    }

    func test_handleAuthenticationUrl_presents_setup_flow_if_jetpack_is_already_connected() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite, rootViewController: navigationController, stores: stores)
        let url = try XCTUnwrap(URL(string: "\(dotcomAuthScheme)://magic-login?token=test"))

        let expectedAccount = Account(userID: 123, displayName: "Test", email: "test@example.com", username: "test", gravatarUrl: nil)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .loadWPComAccount(_, onCompletion):
                onCompletion(expectedAccount)
            case let .fetchJetpackConnectionData(_, completion):
                let dotcomUser = DotcomUser.fake().copy(id: expectedAccount.userID, username: expectedAccount.username, email: expectedAccount.email)
                completion(.success(JetpackConnectionData.fake().copy(currentUser: .fake().copy(wpcomUser: dotcomUser))))
            default:
                break
            }
        }
        stores.mockJetpackCheck()

        // When
        let result = coordinator.handleAuthenticationUrl(url, dotcomAuthScheme: dotcomAuthScheme)

        // Then
        XCTAssertTrue(result)
        waitUntil {
            (self.navigationController.presentedViewController as? UINavigationController)?.topViewController is JetpackSetupHostingController
        }
    }

    func test_startSetup_when_feature_flag_enabled_then_presents_email_login_directly() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  stores: stores,
                                                  featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .fetchJetpackConnectionData(_, completion):
                completion(.success(JetpackConnectionData.fake()))
            default:
                break
            }
        }
        stores.mockJetpackCheck()

        // When
        coordinator.startSetup()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is LoginNavigationController
        }
        let loginViewController = try XCTUnwrap(navigationController.presentedViewController as? LoginNavigationController)
        XCTAssertTrue(loginViewController.topViewController is WPComEmailLoginHostingController)
    }

    func test_startSetup_when_feature_flag_enabled_then_does_not_present_benefit_modal() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  stores: stores,
                                                  featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .fetchJetpackConnectionData(_, completion):
                completion(.success(JetpackConnectionData.fake()))
            default:
                break
            }
        }
        stores.mockJetpackCheck()

        // When
        coordinator.startSetup()

        // Then
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        XCTAssertFalse(navigationController.presentedViewController is JetpackBenefitsHostingController)
    }

    func test_startSetup_when_feature_flag_enabled_and_wpcom_credentials_then_presents_setup_steps_directly() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true))
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)
        let testSite = Site.fake().copy(siteID: 123, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  stores: stores,
                                                  featureFlagService: featureFlagService)

        // When
        coordinator.startSetup()

        // Then
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        XCTAssertTrue((navigationController.presentedViewController as? UINavigationController)?.topViewController is JetpackSetupHostingController)
    }

    func test_startSetup_when_feature_flag_enabled_and_no_wpcom_credentials_then_proceeds_with_connection_check() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let featureFlagService = MockFeatureFlagService(selfDrivenPushToken: true)
        let testSite = Site.fake().copy(siteID: 123, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  stores: stores,
                                                  featureFlagService: featureFlagService)
        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case let .fetchJetpackConnectionData(_, completion):
                completion(.success(JetpackConnectionData.fake()))
            default:
                break
            }
        }
        stores.mockJetpackCheck()

        // When
        coordinator.startSetup()

        // Then
        waitUntil {
            self.navigationController.presentedViewController is LoginNavigationController
        }
        let loginViewController = navigationController.presentedViewController as? LoginNavigationController
        XCTAssertTrue(loginViewController?.topViewController is WPComEmailLoginHostingController)
    }

    func test_startAuthentication_proceeds_to_display_email_screen_when_email_is_not_found() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  stores: stores)

        // When
        coordinator.startAuthentication(with: nil)

        // Then
        waitUntil {
            self.navigationController.topmostPresentedViewController is LoginNavigationController
        }

        let loginViewController = navigationController.topmostPresentedViewController as! LoginNavigationController
        XCTAssertTrue(loginViewController.topViewController is WPComEmailLoginHostingController)
    }

    func test_startAuthentication_proceeds_to_display_password_screen_when_email_is_found() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let mockAccountService = MockWordPressComAccountService()
        mockAccountService.shouldReturnPasswordlessAccount = false
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  accountService: mockAccountService,
                                                  stores: stores)

        // When
        coordinator.startAuthentication(with: "email@test.com")

        // Then
        waitUntil {
            self.navigationController.topmostPresentedViewController is LoginNavigationController
        }

        let loginViewController = navigationController.topmostPresentedViewController as! LoginNavigationController
        XCTAssertTrue(loginViewController.topViewController is WPComPasswordLoginHostingController)
    }

    func test_startAuthentication_proceeds_to_display_magic_link_screen_when_email_is_passwordless() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let mockAccountService = MockWordPressComAccountService()
        mockAccountService.shouldReturnPasswordlessAccount = true
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  accountService: mockAccountService,
                                                  stores: stores)

        // When
        coordinator.startAuthentication(with: "email@test.com")

        // Then
        waitUntil {
            self.navigationController.topmostPresentedViewController is LoginNavigationController
        }

        let loginViewController = navigationController.topmostPresentedViewController as! LoginNavigationController
        XCTAssertTrue(loginViewController.topViewController is WPComMagicLinkHostingController)
    }
}

private extension MockStoresManager {
    func mockJetpackCheck(isJetpackInstalled: Bool = false,
                          isJetpackActive: Bool = false) {
        whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .synchronizeSystemInformation(_, onCompletion):
                onCompletion(.success(.init(systemPlugins: [.fake()
                    .copy(plugin: isJetpackInstalled ? "jetpack/jetpack.php" : "plugin/plugin.php", active: isJetpackActive)])))
            default:
                break
            }
        }

    }
}
