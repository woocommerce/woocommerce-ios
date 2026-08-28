import XCTest
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
            case .fetchSiteInfo(_, let completion):
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
            case .fetchSiteInfo(_, let completion):
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
            case .fetchSiteInfo(_, let completion):
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
            guard case .fetchSiteInfo(_, let completion) = action else { return }
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
            guard case .fetchSiteInfo(_, let completion) = action else { return }
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
            guard case .fetchSiteInfo(_, let completion) = action else { return }
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
    let mockGeneratedPassword: ApplicationPassword?
    let mockGenerationError: Error?
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
