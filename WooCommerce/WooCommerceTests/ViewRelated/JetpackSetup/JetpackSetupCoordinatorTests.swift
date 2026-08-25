import XCTest
@testable import WooCommerce
@testable import Yosemite
import protocol Networking.ApplicationPasswordUseCase
import enum Networking.NetworkError
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

    func test_startSetup_when_not_eligible_then_presents_benefit_modal() {
        // Given
        let testSite = Site.fake()
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = false
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  pushNotificationEligibilityChecker: eligibilityChecker)

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

    func test_startSetup_when_eligible_then_presents_email_login_directly() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  stores: stores,
                                                  pushNotificationEligibilityChecker: eligibilityChecker)
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

    func test_startSetup_when_eligible_then_does_not_present_benefit_modal() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let testSite = Site.fake().copy(siteID: WooConstants.placeholderStoreID)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  stores: stores,
                                                  pushNotificationEligibilityChecker: eligibilityChecker)
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

    func test_startSetup_when_eligible_and_wpcom_credentials_then_presents_setup_steps_directly() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true))
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let testSite = Site.fake().copy(siteID: 123, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  stores: stores,
                                                  pushNotificationEligibilityChecker: eligibilityChecker)

        // When
        coordinator.startSetup()

        // Then
        waitUntil {
            self.navigationController.presentedViewController != nil
        }
        XCTAssertTrue((navigationController.presentedViewController as? UINavigationController)?.topViewController is JetpackSetupHostingController)
    }

    func test_startSetup_when_eligible_and_no_wpcom_credentials_then_proceeds_with_connection_check() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        let eligibilityChecker = MockWooPushNotificationEligibilityChecker()
        eligibilityChecker.isEligible = true
        let testSite = Site.fake().copy(siteID: 123, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        let coordinator = JetpackSetupCoordinator(site: testSite,
                                                  rootViewController: navigationController,
                                                  stores: stores,
                                                  pushNotificationEligibilityChecker: eligibilityChecker)
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

    func test_authenticateUserAndRefreshSite_when_wporg_endpoints_exist_then_uses_them_to_delete_application_password() throws {
        // Given
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?
        let sessionManager = SessionManager(
            defaults: try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString)),
            keychainServiceName: UUID().uuidString,
            applicationPasswordUseCaseFactory: .init(makeWordPressOrgUseCase: { _, _, _, endpoints in
                capturedEndpoints = endpoints
                return MockJetpackSetupApplicationPasswordUseCase()
            })
        )
        defer { sessionManager.reset() }
        let previousCredentials = Credentials.wporg(
            username: "merchant",
            password: "password",
            siteAddress: "https://example.com"
        )
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://example.com")),
            loginEntryURL: XCTUnwrap(URL(string: "https://example.com/custom-login")),
            adminBaseURL: XCTUnwrap(URL(string: "https://example.com/private-admin/"))
        )
        sessionManager.defaultCredentials = previousCredentials
        try sessionManager.saveCookieNonceAuthenticationEndpoints(endpoints, for: previousCredentials)
        let syncedSite = Site.fake().copy(siteID: 123, url: "https://example.com")
        let stores = MockJetpackSetupStoresManager(sessionManager: sessionManager, siteSyncResult: .success(syncedSite))
        let coordinator = JetpackSetupCoordinator(
            site: syncedSite,
            rootViewController: navigationController,
            stores: stores
        )
        // When
        try completeJetpackSetup(coordinator)

        // Then
        waitUntil {
            capturedEndpoints != nil
        }
        XCTAssertEqual(capturedEndpoints, endpoints)
    }

    func test_authenticateUserAndRefreshSite_when_sync_fails_and_user_cancels_then_restores_wporg_endpoints() throws {
        // Given
        let sessionManager = SessionManager(
            defaults: try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString)),
            keychainServiceName: UUID().uuidString
        )
        defer { sessionManager.reset() }
        let previousCredentials = Credentials.wporg(
            username: "merchant",
            password: "password",
            siteAddress: "https://example.com"
        )
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://example.com")),
            loginEntryURL: XCTUnwrap(URL(string: "https://example.com/custom-login")),
            adminBaseURL: XCTUnwrap(URL(string: "https://example.com/private-admin/"))
        )
        sessionManager.defaultCredentials = previousCredentials
        try sessionManager.saveCookieNonceAuthenticationEndpoints(endpoints, for: previousCredentials)
        let site = Site.fake().copy(siteID: 123, url: "https://example.com")
        let stores = MockJetpackSetupStoresManager(
            sessionManager: sessionManager,
            siteSyncResult: .failure(TestError.siteSynchronization)
        )
        let coordinator = JetpackSetupCoordinator(
            site: site,
            rootViewController: navigationController,
            stores: stores
        )
        // When
        try completeJetpackSetup(coordinator)
        waitUntil {
            self.navigationController.topmostPresentedViewController is UIAlertController
        }
        let alert = try XCTUnwrap(navigationController.topmostPresentedViewController as? UIAlertController)
        alert.tapButton(atIndex: 1)

        // Then
        XCTAssertEqual(sessionManager.defaultCredentials, previousCredentials)
        XCTAssertEqual(sessionManager.cookieNonceAuthenticationEndpoints(for: previousCredentials), endpoints)
        XCTAssertEqual(stores.authenticatedCookieNonceAuthenticationEndpoints, endpoints)
    }

    private func completeJetpackSetup(_ coordinator: JetpackSetupCoordinator) throws {
        let url = try XCTUnwrap(URL(string: "\(dotcomAuthScheme)://magic-login?token=test"))
        XCTAssertTrue(coordinator.handleAuthenticationUrl(url, dotcomAuthScheme: dotcomAuthScheme))
        waitUntil {
            (self.navigationController.topmostPresentedViewController as? UINavigationController)?.topViewController
                is JetpackSetupHostingController
        }
        let setupNavigationController = try XCTUnwrap(
            navigationController.topmostPresentedViewController as? UINavigationController
        )
        let setupViewController = try XCTUnwrap(setupNavigationController.topViewController as? JetpackSetupHostingController)
        let viewModel = try XCTUnwrap(
            Mirror(reflecting: setupViewController).descendant("viewModel") as? JetpackSetupViewModel
        )
        viewModel.navigateToStore()
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

private final class MockJetpackSetupStoresManager: DefaultStoresManager {
    private let siteSyncResult: Result<Site, Error>
    private(set) var authenticatedCookieNonceAuthenticationEndpoints: CookieNonceAuthenticationEndpoints?

    init(sessionManager: SessionManager, siteSyncResult: Result<Site, Error>) {
        self.siteSyncResult = siteSyncResult
        super.init(sessionManager: sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? JetpackConnectionAction {
            switch action {
            case let .loadWPComAccount(_, onCompletion):
                onCompletion(Account(userID: 123, displayName: "Test", email: "test@example.com", username: "test", gravatarUrl: nil))
            case let .fetchJetpackConnectionData(_, completion):
                completion(.failure(NetworkError.notFound()))
            default:
                break
            }
            return
        }
        if let action = action as? SiteAction {
            switch action {
            case let .syncSiteByDomain(_, completion):
                completion(siteSyncResult)
            default:
                break
            }
        }
    }

    @discardableResult
    override func authenticate(credentials: Credentials,
                               cookieNonceAuthenticationEndpoints: CookieNonceAuthenticationEndpoints?) -> StoresManager {
        authenticatedCookieNonceAuthenticationEndpoints = cookieNonceAuthenticationEndpoints
        return super.authenticate(
            credentials: credentials,
            cookieNonceAuthenticationEndpoints: cookieNonceAuthenticationEndpoints
        )
    }

    @discardableResult
    override func synchronizeEntities(onCompletion: (() -> Void)?) -> StoresManager {
        onCompletion?()
        return self
    }

    override func updateDefaultStore(storeID: Int64) { }

    override func updateDefaultStore(_ site: Site) { }

    override func listenToWPCOMInvalidWPCOMTokenNotification() { }

    override func listenToUnknownBlogNotification() { }
}

private final class MockJetpackSetupApplicationPasswordUseCase: ApplicationPasswordUseCase {
    var applicationPassword: ApplicationPassword? { nil }
    var canRegenerateApplicationPassword: Bool { false }

    func generateNewPassword() async throws -> ApplicationPassword {
        throw TestError.applicationPasswordGeneration
    }

    func deletePassword(locally: Bool) async throws { }
}

private enum TestError: Error {
    case applicationPasswordGeneration
    case siteSynchronization
}
