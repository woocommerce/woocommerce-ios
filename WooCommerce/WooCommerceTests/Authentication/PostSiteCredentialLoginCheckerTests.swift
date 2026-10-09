import XCTest
import WordPressAuthenticator
@testable import Yosemite
@testable import Networking
@testable import WooCommerce

final class PostSiteCredentialLoginCheckerTests: XCTestCase {
    private let testURL = "https://test.com"
    private var stores: MockStoresManager!
    private var navigationController: UINavigationController!

    /// Sample Application Password
    ///
    private let applicationPassword = ApplicationPassword(wpOrgUsername: "username", password: .init("password"), uuid: "8ef68e6b-4670-4cfd-8ca0-456e616bcd5e")

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

    @MainActor
    func test_unexpected_failures_when_alert_is_presented_then_track_origin_and_step() {
        for flow in [LoginUnexpectedResponseFailure.LoginFlow.siteCredentials, .appPassword] {
            for step in [LoginUnexpectedResponseFailure.Step.appPasswordGeneration, .userRoleCheck, .wooPluginCheck] {
                // Given
                let failure = UnexpectedStoreResponseError(kind: .unacceptableStatusCode, statusCode: 500)
                let useCase = MockApplicationPasswordUseCase(mockGeneratedPassword: step == .appPasswordGeneration ? nil : applicationPassword,
                                                           mockGenerationError: step == .appPasswordGeneration ? failure : nil)
                let role = MockRoleEligibilityUseCase()
                role.errorToReturn = step == .userRoleCheck ? .unknown(error: failure) : nil
                stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
                    if case let .fetchSiteInfo(_, enabled, completion) = action {
                        XCTAssertTrue(enabled)
                        completion(.failure(failure))
                    }
                }
                let provider = MockAnalyticsProvider()
                let presenter = DeferredPostLoginPresenter()
                let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: useCase,
                                                             loginFlow: flow,
                                                             roleEligibilityUseCase: role,
                                                             stores: stores,
                                                             analytics: WooAnalytics(analyticsProvider: provider),
                                                             previousViewController: nil)
                // When
                checker.checkEligibility(for: testURL, from: presenter) {}
                waitUntil { presenter.presentationCompletion != nil }
                // Then
                let event = WooAnalyticsStat.loginUnexpectedResponseErrorShown.rawValue
                XCTAssertFalse(provider.receivedEvents.contains(event))
                presenter.presentationCompletion?()
                XCTAssertEqual(provider.receivedEvents.filter { $0 == event }.count, 1)
                XCTAssertEqual(provider.receivedProperties.last?["step"] as? String, step.rawValue)
                XCTAssertEqual(provider.receivedProperties.last?["login_flow"] as? String, flow.rawValue)
                XCTAssertEqual(provider.receivedProperties.last?["failure_kind"] as? String, "unacceptable_status_code")
                XCTAssertEqual(provider.receivedProperties.last?.count, 3)
            }
        }
    }

    @MainActor
    func test_retry_when_original_step_passes_but_later_step_fails_then_reports_original_success_without_regenerating_password() throws {
        for step in [LoginUnexpectedResponseFailure.Step.appPasswordGeneration, .userRoleCheck] {
            // Given
            let fixture = makeRecoveryFixture(step: step)
            fixture.checker.checkEligibility(for: testURL, from: fixture.navigation) {}
            waitUntil { fixture.navigation.alert != nil }
            fixture.navigation.presentationCompletion?()
            fixture.navigation.alert = nil
            fixture.password.mockGenerationError = nil
            fixture.password.mockGeneratedPassword = applicationPassword
            fixture.role.errorToReturn = nil

            // When
            fixture.checker.unexpectedResponsePresenter.select(.retry)
            waitUntil { fixture.navigation.alert != nil }
            fixture.navigation.presentationCompletion?()

            // Then
            let event = WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue
            XCTAssertEqual(fixture.provider.receivedEvents.filter { $0 == event }.count, 1)
            XCTAssertEqual(fixture.provider.properties(for: event)?["step"] as? String, step.rawValue)
            XCTAssertEqual(fixture.provider.properties(for: event)?["result"] as? String, "success")
            XCTAssertEqual(fixture.password.generationCallCount, step == .appPasswordGeneration ? 2 : 1)
            XCTAssertEqual(fixture.navigation.alert?.title, "Unable to log in")
            XCTAssertEqual(fixture.provider.receivedProperties.last?["step"] as? String,
                           "woo_plugin_check")
        }
    }

    @MainActor
    func test_retry_when_fault_persists_then_reports_failure_once_and_shows_next_alert() {
        for step in [LoginUnexpectedResponseFailure.Step.appPasswordGeneration, .userRoleCheck, .wooPluginCheck] {
            // Given
            let fixture = makeRecoveryFixture(step: step)
            fixture.checker.checkEligibility(for: testURL, from: fixture.navigation) {}
            waitUntil { fixture.navigation.alert != nil }
            fixture.navigation.presentationCompletion?()
            fixture.navigation.alert = nil

            // When
            fixture.checker.unexpectedResponsePresenter.select(.retry)
            waitUntil { fixture.navigation.alert != nil }
            fixture.navigation.presentationCompletion?()

            // Then
            let event = WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue
            XCTAssertEqual(fixture.provider.receivedEvents.filter { $0 == event }.count, 1)
            XCTAssertEqual(fixture.provider.properties(for: event)?["result"] as? String, "failure")
            XCTAssertEqual(fixture.provider.properties(for: event)?["step"] as? String, step.rawValue)
            XCTAssertEqual(fixture.navigation.alert?.actions.map(\.title), ["Try Again", "Contact Support", "Dismiss"])
            XCTAssertEqual(fixture.provider.receivedEvents.filter { $0 == WooAnalyticsStat.loginUnexpectedResponseErrorShown.rawValue }.count, 2)
            XCTAssertEqual(fixture.password.generationCallCount, step == .appPasswordGeneration ? 2 : 1)
        }
    }

    @MainActor
    func test_dismiss_or_support_when_post_login_fails_then_keeps_session_and_restores_usable_form() {
        for step in [LoginUnexpectedResponseFailure.Step.appPasswordGeneration, .userRoleCheck, .wooPluginCheck] {
            for action in [LoginUnexpectedResponseFailure.Action.dismiss, .contactSupport] {
                // Given: the browser is above the originating form.
                let fixture = makeRecoveryFixture(step: step, flow: .appPassword)
                fixture.navigation.pushViewController(UIViewController(), animated: false)
                fixture.form.configureViewLoading(true)
                XCTAssertTrue(fixture.form.navigationItem.hidesBackButton)
                fixture.checker.checkEligibility(for: testURL, from: fixture.navigation) {}
                waitUntil { fixture.navigation.alert != nil }

                // When
                fixture.checker.unexpectedResponsePresenter.select(action)

                // Then: the same form remains in place; support adds only AI chat.
                XCTAssertTrue(fixture.stores.isAuthenticated)
                XCTAssertFalse(fixture.form.navigationItem.hidesBackButton)
                XCTAssertTrue(fixture.navigation.viewControllers.first === fixture.form)
                XCTAssertEqual(fixture.navigation.viewControllers.count, action == .dismiss ? 1 : 2)
                if action == .contactSupport { XCTAssertTrue(fixture.navigation.topViewController is SupportChatHostingController) }
                XCTAssertFalse(fixture.provider.receivedEvents.contains(WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue))
                XCTAssertEqual(fixture.password.generationCallCount, 1)
            }
        }
    }

    @MainActor
    func test_cancellation_when_role_retry_is_pending_then_ignores_stale_success_and_emits_no_result() {
        // Given
        let provider = MockAnalyticsProvider()
        let navigation = DeferredPostLoginPresenter()
        var completeRole: ((Result<User, Error>) -> Void)?
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            if case let .retrieveUser(_, _, completion) = action { completeRole = completion }
        }
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: MockApplicationPasswordUseCase(mockApplicationPassword: applicationPassword),
                                                     stores: stores, analytics: WooAnalytics(analyticsProvider: provider), previousViewController: nil)
        var succeeded = false
        checker.checkEligibility(for: testURL, from: navigation) { succeeded = true }
        completeRole?(.failure(UnexpectedStoreResponseError(kind: .unexpectedContent)))
        navigation.presentationCompletion?()
        checker.unexpectedResponsePresenter.select(.retry)
        let staleCompletion = completeRole

        // When
        checker.cancel()
        staleCompletion?(.success(makeUser(eligible: true)))

        // Then
        XCTAssertFalse(succeeded)
        XCTAssertFalse(provider.receivedEvents.contains(WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue))
        XCTAssertFalse(stores.receivedActions.compactMap { $0 as? WordPressSiteAction }.contains { if case .fetchSiteInfo = $0 { return true }; return false })
    }

    @MainActor
    func test_woo_retry_when_successful_then_finishes_login_without_repeating_generation_or_role_check() {
        // Given
        let fixture = makeRecoveryFixture(step: .wooPluginCheck)
        var succeeded = false
        fixture.checker.checkEligibility(for: testURL, from: fixture.navigation) { succeeded = true }
        waitUntil { fixture.navigation.alert != nil }
        fixture.stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            if case let .fetchSiteInfo(_, enabled, completion) = action {
                XCTAssertTrue(enabled)
                completion(.success(.fake().copy(isWooCommerceActive: true)))
            }
        }

        // When
        fixture.checker.unexpectedResponsePresenter.select(.retry)

        // Then
        XCTAssertTrue(succeeded)
        XCTAssertEqual(fixture.password.generationCallCount, 1)
        XCTAssertEqual(fixture.role.syncEligibilityCallCount, 1)
        XCTAssertEqual(fixture.provider.properties(for: WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue)?["result"] as? String, "success")
    }

    func test_application_password_disabled_error_is_displayed_when_application_password_is_disabled() {
        // Given
        let useCase = MockApplicationPasswordUseCase(mockGenerationError: ApplicationPasswordUseCaseError.applicationPasswordsDisabled)
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: useCase,
                                                     previousViewController: nil)
        var isSuccess = false

        // When
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }
        waitUntil {
            self.navigationController.viewControllers.isNotEmpty
        }

        // Then
        XCTAssertFalse(isSuccess)
        XCTAssertTrue(navigationController.topViewController is ULErrorViewController)
    }

    func test_error_alert_is_displayed_when_application_password_cannot_be_fetched() {
        // Given
        let useCase = MockApplicationPasswordUseCase(mockGenerationError: NetworkError.timeout())
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: useCase,
                                                     previousViewController: nil)
        var isSuccess = false

        // When
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }
        waitUntil {
            self.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertFalse(isSuccess)
        XCTAssertTrue(navigationController.viewControllers.isEmpty)
        XCTAssertTrue(navigationController.presentedViewController is UIAlertController)
    }

    func test_role_error_screen_is_displayed_when_the_user_is_not_eligible() {
        // Given
        let appPasswordUseCase = MockApplicationPasswordUseCase(mockGeneratedPassword: applicationPassword)
        let roleCheckUseCase = MockRoleEligibilityUseCase()
        let errorInfo = StorageEligibilityErrorInfo(name: "Billie Jean", roles: ["skater", "writer"])
        roleCheckUseCase.errorToReturn = .insufficientRole(info: errorInfo)
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: appPasswordUseCase,
                                                     roleEligibilityUseCase: roleCheckUseCase,
                                                     previousViewController: nil)
        var isSuccess = false

        // When
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }
        waitUntil {
            self.navigationController.viewControllers.isNotEmpty
        }

        // Then
        XCTAssertFalse(isSuccess)
        XCTAssertTrue(navigationController.topViewController is RoleErrorViewController)
    }

    func test_error_alert_is_displayed_when_user_info_cannot_be_fetched() {
        // Given
        let appPasswordUseCase = MockApplicationPasswordUseCase(mockGeneratedPassword: applicationPassword)
        let roleCheckUseCase = MockRoleEligibilityUseCase()
        roleCheckUseCase.errorToReturn = .unknown(error: NetworkError.timeout())
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: appPasswordUseCase,
                                                     roleEligibilityUseCase: roleCheckUseCase,
                                                     previousViewController: nil)
        var isSuccess = false

        // When
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }
        waitUntil {
            self.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertFalse(isSuccess)
        XCTAssertTrue(navigationController.presentedViewController is UIAlertController)
    }

    func test_onSuccess_is_triggered_when_the_site_has_active_woo() {
        // Given
        let appPasswordUseCase = MockApplicationPasswordUseCase(mockGeneratedPassword: applicationPassword)
        let roleCheckUseCase = MockRoleEligibilityUseCase()
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: appPasswordUseCase,
                                                     roleEligibilityUseCase: roleCheckUseCase,
                                                     stores: stores,
                                                     previousViewController: nil)
        var isSuccess = false

        // When
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            switch action {
            case .fetchSiteInfo(_, _, let completion):
                let site = Site.fake().copy(isWooCommerceActive: true)
                completion(.success(site))
            default:
                break
            }
        }
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }

        // Then
        waitUntil {
            isSuccess == true
        }
    }

    func test_error_alert_is_displayed_if_the_site_does_not_have_active_woo() {
        // Given
        let appPasswordUseCase = MockApplicationPasswordUseCase(mockGeneratedPassword: applicationPassword)
        let roleCheckUseCase = MockRoleEligibilityUseCase()
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: appPasswordUseCase,
                                                     roleEligibilityUseCase: roleCheckUseCase,
                                                     stores: stores,
                                                     previousViewController: nil)
        var isSuccess = false

        // When
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            switch action {
            case .fetchSiteInfo(_, _, let completion):
                let site = Site.fake().copy(isWooCommerceActive: false)
                completion(.success(site))
            default:
                break
            }
        }
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }
        waitUntil {
            self.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertFalse(isSuccess)
        XCTAssertTrue(navigationController.presentedViewController is UIAlertController)
    }

    func test_error_alert_is_displayed_if_the_site_info_cannot_be_fetched() {
        // Given
        let appPasswordUseCase = MockApplicationPasswordUseCase(mockGeneratedPassword: applicationPassword)
        let roleCheckUseCase = MockRoleEligibilityUseCase()
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: appPasswordUseCase,
                                                     roleEligibilityUseCase: roleCheckUseCase,
                                                     stores: stores,
                                                     previousViewController: nil)
        var isSuccess = false

        // When
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            switch action {
            case .fetchSiteInfo(_, _, let completion):
                completion(.failure(NetworkError.timeout()))
            default:
                break
            }
        }
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }
        waitUntil {
            self.navigationController.presentedViewController != nil
        }

        // Then
        XCTAssertFalse(isSuccess)
        XCTAssertTrue(navigationController.presentedViewController is UIAlertController)
    }

    func test_custom_endpoints_when_password_is_generated_then_persists_before_role_and_woo_checks() throws {
        // Given
        var events: [String] = []
        let appPasswordUseCase = MockApplicationPasswordUseCase(mockGeneratedPassword: applicationPassword)
        appPasswordUseCase.onGenerate = { events.append("application_password") }
        let roleCheckUseCase = MockRoleEligibilityUseCase()
        roleCheckUseCase.onCheckEligibility = { events.append("role") }
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            guard case .fetchSiteInfo(_, _, let completion) = action else { return }
            events.append("woo")
            completion(.success(.fake().copy(isWooCommerceActive: true)))
        }
        let persistence = try makePersistence(custom: true)
        let checker = PostSiteCredentialLoginChecker(
            applicationPasswordUseCase: appPasswordUseCase,
            roleEligibilityUseCase: roleCheckUseCase,
            stores: stores,
            authenticationEndpointPersistence: persistence,
            authenticationEndpointPersistenceAction: { _ in events.append("endpoint_persistence") },
            previousViewController: nil
        )
        var isSuccess = false

        // When
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }

        // Then
        waitUntil { isSuccess }
        XCTAssertEqual(events, ["application_password", "endpoint_persistence", "role", "woo"])
    }

    func test_single_custom_endpoint_when_classifying_persistence_then_persists() throws {
        // Given
        let siteURL = try XCTUnwrap(URL(string: testURL))
        let credentials = Credentials.wporg(username: "merchant", password: "password", siteAddress: testURL)
        let endpoints = [
            try CookieNonceAuthenticationEndpoints(
                siteURL: siteURL,
                loginEntryURL: try XCTUnwrap(URL(string: testURL + "/custom-login"))
            ),
            try CookieNonceAuthenticationEndpoints(
                siteURL: siteURL,
                adminBaseURL: try XCTUnwrap(URL(string: testURL + "/custom-admin/"))
            )
        ]

        for endpoint in endpoints {
            // When
            let persistence = try XCTUnwrap(
                SiteCredentialAuthenticationEndpointPersistence(credentials: credentials, endpoints: endpoint)
            )

            // Then
            guard case .persist = persistence.behavior else {
                return XCTFail("A single custom endpoint must be persisted")
            }
        }
    }

    func test_verified_standard_endpoints_when_custom_record_exists_then_removes_stale_record_before_role_check() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sessionManager = SessionManager(defaults: defaults, keychainServiceName: UUID().uuidString)
        let credentials = Credentials.wporg(username: "merchant", password: "password", siteAddress: testURL)
        let customEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: testURL)),
            loginEntryURL: XCTUnwrap(URL(string: testURL + "/custom-login"))
        )
        let standardEndpoints = try CookieNonceAuthenticationEndpoints(siteURL: XCTUnwrap(URL(string: testURL)))
        sessionManager.defaultCredentials = credentials
        sessionManager.saveCookieNonceAuthenticationEndpoints(customEndpoints, for: credentials)
        let isolatedStores = MockStoresManager(sessionManager: sessionManager)
        let roleCheckUseCase = MockRoleEligibilityUseCase()
        roleCheckUseCase.onCheckEligibility = {
            XCTAssertNil(sessionManager.cookieNonceAuthenticationEndpoints(for: credentials))
        }
        isolatedStores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            guard case .fetchSiteInfo(_, _, let completion) = action else { return }
            completion(.success(.fake().copy(isWooCommerceActive: true)))
        }
        let persistence = try XCTUnwrap(
            SiteCredentialAuthenticationEndpointPersistence(credentials: credentials, endpoints: standardEndpoints)
        )
        let checker = PostSiteCredentialLoginChecker(
            applicationPasswordUseCase: MockApplicationPasswordUseCase(mockApplicationPassword: applicationPassword),
            roleEligibilityUseCase: roleCheckUseCase,
            stores: isolatedStores,
            authenticationEndpointPersistence: persistence,
            previousViewController: nil
        )
        var isSuccess = false

        // When
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }

        // Then
        waitUntil { isSuccess }
        XCTAssertNil(sessionManager.cookieNonceAuthenticationEndpoints(for: credentials))
    }

    func test_missing_endpoint_persistence_context_when_checking_browser_or_malformed_flow_then_does_not_mutate_endpoints() {
        // Given
        var persistenceCallCount = 0
        let roleCheckUseCase = MockRoleEligibilityUseCase()
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            guard case .fetchSiteInfo(_, _, let completion) = action else { return }
            completion(.success(.fake().copy(isWooCommerceActive: true)))
        }
        let checker = PostSiteCredentialLoginChecker(
            applicationPasswordUseCase: MockApplicationPasswordUseCase(mockApplicationPassword: applicationPassword),
            roleEligibilityUseCase: roleCheckUseCase,
            stores: stores,
            authenticationEndpointPersistenceAction: { _ in persistenceCallCount += 1 },
            previousViewController: nil
        )
        var isSuccess = false

        // When
        checker.checkEligibility(for: testURL, from: navigationController) {
            isSuccess = true
        }

        // Then
        waitUntil { isSuccess }
        XCTAssertEqual(persistenceCallCount, 0)
    }
}

private extension PostSiteCredentialLoginCheckerTests {
    @MainActor
    func makeRecoveryFixture(step: LoginUnexpectedResponseFailure.Step,
                             flow: LoginUnexpectedResponseFailure.LoginFlow = .siteCredentials) -> RecoveryFixture {
        let failure = UnexpectedStoreResponseError(kind: .unexpectedContent)
        let password = MockApplicationPasswordUseCase(mockGeneratedPassword: step == .appPasswordGeneration ? nil : applicationPassword,
                                                      mockGenerationError: step == .appPasswordGeneration ? failure : nil)
        let role = MockRoleEligibilityUseCase()
        role.errorToReturn = step == .userRoleCheck ? .unknown(error: failure) : nil
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            if case let .fetchSiteInfo(_, _, completion) = action { completion(.failure(failure)) }
        }
        let provider = MockAnalyticsProvider()
        let form = LoginViewController()
        let navigation = DeferredPostLoginPresenter(rootViewController: form)
        navigation.loadViewIfNeeded()
        navigation.view.layoutIfNeeded()
        let checker = PostSiteCredentialLoginChecker(applicationPasswordUseCase: password, loginFlow: flow,
                                                     roleEligibilityUseCase: role, stores: stores,
                                                     analytics: WooAnalytics(analyticsProvider: provider), previousViewController: form)
        return RecoveryFixture(checker: checker, password: password, role: role, stores: stores,
                               provider: provider, navigation: navigation, form: form)
    }

    struct RecoveryFixture {
        let checker: PostSiteCredentialLoginChecker
        let password: MockApplicationPasswordUseCase
        let role: MockRoleEligibilityUseCase
        let stores: MockStoresManager
        let provider: MockAnalyticsProvider
        let navigation: DeferredPostLoginPresenter
        let form: LoginViewController
    }

    struct Constants {
        static let eligibleRoles = ["shop_manager", "editor"]
        static let ineligibleRoles = ["author", "editor"]
    }

    func makeUser(eligible: Bool = false) -> User {
        User(localID: 0, siteID: 0, email: "email", username: "username", firstName: "first", lastName: "last",
             nickname: "nick", roles: eligible ? Constants.eligibleRoles : Constants.ineligibleRoles)
    }

    func makePersistence(custom: Bool) throws -> SiteCredentialAuthenticationEndpointPersistence {
        let siteURL = try XCTUnwrap(URL(string: testURL))
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: custom ? try XCTUnwrap(URL(string: testURL + "/custom-login")) : nil
        )
        return try XCTUnwrap(SiteCredentialAuthenticationEndpointPersistence(
            credentials: .wporg(username: "merchant", password: "password", siteAddress: testURL),
            endpoints: endpoints
        ))
    }
}

/// MOCK: application password use case
///
private final class MockApplicationPasswordUseCase: ApplicationPasswordUseCase {
    var mockApplicationPassword: ApplicationPassword?
    var mockGeneratedPassword: ApplicationPassword?
    var mockGenerationError: Error?
    let mockDeletionError: Error?
    var generationCallCount = 0
    var onGenerate: (() -> Void)?
    init(mockApplicationPassword: ApplicationPassword? = nil,
         mockGeneratedPassword: ApplicationPassword? = nil,
         mockGenerationError: Error? = nil,
         mockDeletionError: Error? = nil) {
        self.mockApplicationPassword = mockApplicationPassword
        self.mockGeneratedPassword = mockGeneratedPassword
        self.mockGenerationError = mockGenerationError
        self.mockDeletionError = mockDeletionError
    }

    var applicationPassword: Networking.ApplicationPassword? {
        mockApplicationPassword
    }

    var canRegenerateApplicationPassword: Bool { true }

    func generateNewPassword() async throws -> Networking.ApplicationPassword {
        generationCallCount += 1
        onGenerate?()
        if let mockGeneratedPassword {
            // Store the newly generated password
            mockApplicationPassword = mockGeneratedPassword
            return mockGeneratedPassword
        }
        throw mockGenerationError ?? NetworkError.notFound()
    }

    func deletePassword(locally: Bool) async throws {
        throw mockDeletionError ?? NetworkError.notFound()
    }
}

private final class DeferredPostLoginPresenter: UINavigationController {
    var presentationCompletion: (() -> Void)?
    var alert: UIAlertController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentationCompletion = completion
        alert = viewControllerToPresent as? UIAlertController
    }
}
