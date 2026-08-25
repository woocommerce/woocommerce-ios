import XCTest
@testable import WooCommerce
import Yosemite
import KeychainAccess
@testable import Networking
import Storage

/// SessionManager Unit Tests
///
final class SessionManagerTests: XCTestCase {

    /// Sample Application Password
    ///
    private let applicationPassword = ApplicationPassword(wpOrgUsername: "username", password: .init("password"), uuid: "8ef68e6b-4670-4cfd-8ca0-456e616bcd5e")

    /// CredentialsStorage Unit-Testing Instance
    ///
    private var manager = SessionManager(defaults: Settings.defaults, keychainServiceName: Settings.keychainServiceName)

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        manager.defaultCredentials = nil
    }

    /// Verifies that `loadDefaultCredentials` returns nil whenever there are no default credentials stored.
    ///
    func testLoadDefaultCredentialsReturnsNilWhenThereAreNoDefaultCredentials() {
        XCTAssertNil(manager.defaultCredentials)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersistedForWPCOM() {
        // Given
        manager.defaultCredentials = Settings.wpcomCredentials

        guard case let .wpcom(username, authToken, siteAddress) = manager.defaultCredentials else {
            XCTFail("Missing credentials.")
            return
        }

        // When
        let retrieved = Credentials.wpcom(username: username, authToken: authToken, siteAddress: siteAddress)

        // Then
        XCTAssertEqual(retrieved, Settings.wpcomCredentials)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func testDefaultCredentialsAreProperlyPersistedForWPOrg() {
        // Given
        manager.defaultCredentials = Settings.wporgCredentials

        guard case let .wporg(username: username, password: password, siteAddress: siteAddress) = manager.defaultCredentials else {
            XCTFail("Missing credentials.")
            return
        }

        // When
        let retrieved = Credentials.wporg(username: username, password: password, siteAddress: siteAddress)

        // Then
        XCTAssertEqual(retrieved, Settings.wporgCredentials)
    }

    /// Verifies that `loadDefaultCredentials` effectively returns the last stored credentials
    ///
    func test_default_credentials_are_properly_persisted_for_application_password() {
        // Given
        manager.defaultCredentials = Settings.applicationPasswordCredentials

        guard case let .applicationPassword(username, password, siteAddress) = manager.defaultCredentials else {
            XCTFail("Missing credentials.")
            return
        }

        // When
        let retrieved = Credentials.applicationPassword(username: username, password: password, siteAddress: siteAddress)

        // Then
        XCTAssertEqual(retrieved, Settings.applicationPasswordCredentials)
    }

    /// Verifies that `storePhoneNumber` is set to `nil` upon reset
    ///
    func test_storePhoneNumber_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.storePhoneNumber] = "0123456789"

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.storePhoneNumber] as? String), "0123456789")

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.storePhoneNumber])
    }

    /// Verifies that `completedAllStoreOnboardingTasks` is set to `nil` upon reset
    ///
    func test_completedAllStoreOnboardingTasks_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] = ["123": true]

        // Then
        XCTAssertEqual((defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] as? [String: Bool])?["123"], true)

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])
    }

    /// Verifies that `usedProductDescriptionAI` is set to `nil` upon reset
    ///
    func test_usedProductDescriptionAI_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[UserDefaults.Key.usedProductDescriptionAI] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.usedProductDescriptionAI] as? Bool))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.usedProductDescriptionAI])
    }

    /// Verifies that `hasDismissedWriteWithAITooltip` is set to `nil` upon reset
    ///
    func test_hasDismissedWriteWithAITooltip_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[UserDefaults.Key.hasDismissedWriteWithAITooltip] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.hasDismissedWriteWithAITooltip] as? Bool))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.hasDismissedWriteWithAITooltip])
    }

    /// Verifies that `numberOfTimesWriteWithAITooltipIsShown` is set to `nil` upon reset
    ///
    func test_numberOfTimesWriteWithAITooltipIsShown_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown] = 3

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown] as? Int), 3)

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown])
    }

    /// Verifies that `storeProfilerAnswers` is set to `nil` upon reset
    ///
    func test_storeProfilerAnswers_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        let encodedObject = try JSONEncoder().encode(["test": "test"])
        defaults[UserDefaults.Key.storeProfilerAnswers] = ["123": encodedObject]

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[UserDefaults.Key.storeProfilerAnswers] as? [String: Data]), ["123": encodedObject])

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.storeProfilerAnswers])
    }

    /// Verifies that `aiPromptTone` is set to `nil` upon reset
    ///
    func test_aiPromptTone_is_set_to_nil_upon_reset() throws {
        // Given
        let siteID: Int64 = 123
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.convincing.rawValue]

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults.aiTone(for: siteID)), .convincing)

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.aiPromptTone])
    }

    /// Verifies that `themesPendingInstall` is set to `nil` upon reset
    ///
    func test_themesPendingInstall_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.themesPendingInstall] = ["123": "321"]

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.themesPendingInstall] as? [String: String]), ["123": "321"])

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.themesPendingInstall])
    }

    /// Verifies that `hiddenStoreIDs` is set to `nil` upon reset
    ///
    func test_hiddenStoreIDs_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.hiddenStoreIDs] = [Int64]([123, 666])

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.hiddenStoreIDs] as? [Int64]), [123, 666])

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.hiddenStoreIDs])
    }

    /// Verifies that `blazeNoCampaignReminderOpened` is set to `nil` upon reset
    ///
    func test_blazeNoCampaignReminderOpened_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.blazeNoCampaignReminderOpened] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults.blazeNoCampaignReminderOpened()))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.blazeNoCampaignReminderOpened])
    }

    /// Verifies that `blazeAbandonedCampaignCreationReminderOpened` is set to `nil` upon reset
    ///
    func test_blazeAbandonedCampaignCreationReminderOpened_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.blazeAbandonedCampaignCreationReminderOpened] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults.blazeAbandonedCampaignCreationReminderOpened()))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.blazeAbandonedCampaignCreationReminderOpened])
    }

    /// Verifies that `blazeSelectedCampaignObjective` is set to `nil` upon reset
    ///
    func test_blazeSelectedCampaignObjective_is_set_to_nil_upon_reset() throws {
        // Given
        let siteID: Int64 = 13
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.blazeSelectedCampaignObjective] = ["\(siteID)": "sales"]

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.blazeSelectedCampaignObjective] as? [String: String]), ["13": "sales"])

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.blazeSelectedCampaignObjective])
    }

    /// Verifies that `wpcomSiteSuspended` is set to `nil` upon reset
    ///
    func test_wpcomSiteSuspended_is_set_to_nil_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.wpcomSiteSuspended] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults.wpcomSiteSuspended))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.wpcomSiteSuspended])
    }

    /// Verifies that image cache is cleared upon reset
    ///
    func test_image_cache_is_cleared_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let mockCache = MockImageCache(name: "Testing")
        let sut = SessionManager(defaults: defaults,
                                 keychainServiceName: Settings.keychainServiceName,
                                 imageCache: mockCache)

        // When
        sut.reset()

        // Then
        XCTAssertTrue(mockCache.clearCacheCalled)
    }

    /// Verifies that image cache is cleared upon reset
    ///
    func test_applicationPasswordUnsupportedList_is_cleared_upon_reset() throws {
        // Given
        let siteID: Int64 = 13
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.applicationPasswordUnsupportedList] = [siteID]

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.applicationPasswordUnsupportedList] as? [Int64]), [siteID])

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.applicationPasswordUnsupportedList])
    }

    /// Verifies that flag to hide WPCom connection suggestion is cleared upon reset
    ///
    func test_hideWPComConnectionOnDashboard_is_cleared_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.hideWPComConnectionOnDashboard] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[.hideWPComConnectionOnDashboard] as? Bool))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.hideWPComConnectionOnDashboard])
    }

    /// Verifies that dashboard analytics update mode explanation state is cleared upon reset
    ///
    func test_hasOpenedDashboardAnalyticsUpdateModeInfo_is_cleared_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        defaults[.hasOpenedDashboardAnalyticsUpdateModeInfo] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[.hasOpenedDashboardAnalyticsUpdateModeInfo] as? Bool))

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.hasOpenedDashboardAnalyticsUpdateModeInfo])
    }

    func test_pendingMagicLinkFlow_is_cleared_upon_reset() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let sut = SessionManager(defaults: defaults, keychainServiceName: Settings.keychainServiceName)

        // When
        let flow = PendingAuthFlowStorage.StoredFlow(flow: .jetpackSetup, timestamp: Date())
        defaults[.pendingMagicLinkFlow] = try? JSONEncoder().encode(flow)

        // Then
        XCTAssertNotNil(defaults[.pendingMagicLinkFlow])

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults[.pendingMagicLinkFlow])
    }

    /// Verifies that `removeDefaultCredentials` effectively nukes everything from the keychain
    ///
    func testDefaultCredentialsAreEffectivelyNuked() {
        manager.defaultCredentials = Settings.wpcomCredentials
        manager.defaultCredentials = nil

        XCTAssertNil(manager.defaultCredentials)
    }

    /// Verifies that `saveDefaultCredentials` overrides previous stored credentials
    ///
    func testDefaultCredentialsCanBeUpdated() {
        manager.defaultCredentials = Settings.wpcomCredentials
        XCTAssertEqual(manager.defaultCredentials, Settings.wpcomCredentials)

        manager.defaultCredentials = Settings.wporgCredentials
        XCTAssertEqual(manager.defaultCredentials, Settings.wporgCredentials)
    }

    func test_cookie_nonce_endpoints_when_wporg_identity_matches_then_restores_case_sensitive_identity() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sut = SessionManager(defaults: defaults, keychainServiceName: UUID().uuidString)
        let credentials = Credentials.wporg(username: "Merchant", password: "password", siteAddress: "https://example.com/")
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://example.com")),
            loginEntryURL: XCTUnwrap(URL(string: "https://example.com/custom-login"))
        )
        try sut.saveCookieNonceAuthenticationEndpoints(endpoints, for: credentials)

        // When, Then
        XCTAssertEqual(sut.cookieNonceAuthenticationEndpoints(for: credentials), endpoints)
        XCTAssertNil(sut.cookieNonceAuthenticationEndpoints(for: .wporg(
            username: "merchant",
            password: "password",
            siteAddress: "https://example.com"
        )))
        XCTAssertNil(sut.cookieNonceAuthenticationEndpoints(for: .applicationPassword(
            username: "Merchant",
            password: "application-password",
            siteAddress: "https://example.com"
        )))
    }

    func test_default_credentials_when_only_wporg_password_changes_then_retains_matching_endpoints() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sut = SessionManager(defaults: defaults, keychainServiceName: UUID().uuidString)
        let original = Credentials.wporg(username: "merchant", password: "first", siteAddress: "https://example.com")
        let updated = Credentials.wporg(username: "merchant", password: "second", siteAddress: "https://example.com/")
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://example.com")),
            adminBaseURL: XCTUnwrap(URL(string: "https://example.com/private-admin"))
        )
        try sut.saveCookieNonceAuthenticationEndpoints(endpoints, for: original)
        sut.defaultCredentials = original

        // When
        sut.defaultCredentials = updated

        // Then
        XCTAssertEqual(sut.cookieNonceAuthenticationEndpoints(for: updated), endpoints)
    }

    func test_default_credentials_when_incoming_identity_changes_then_retains_only_incoming_saved_identity() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sut = SessionManager(defaults: defaults, keychainServiceName: UUID().uuidString)
        let credentialsA = Credentials.wporg(username: "merchant-a", password: "password", siteAddress: "https://a.example")
        let credentialsB = Credentials.wporg(username: "merchant-b", password: "password", siteAddress: "https://b.example")
        let endpointsB = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://b.example")),
            loginEntryURL: XCTUnwrap(URL(string: "https://b.example/custom-login"))
        )
        sut.defaultCredentials = credentialsA
        try sut.saveCookieNonceAuthenticationEndpoints(endpointsB, for: credentialsB)

        // When
        sut.defaultCredentials = credentialsB

        // Then
        XCTAssertEqual(sut.cookieNonceAuthenticationEndpoints(for: credentialsB), endpointsB)

        // When
        sut.defaultCredentials = .wporg(username: "different", password: "password", siteAddress: "https://b.example")

        // Then
        XCTAssertNil(sut.cookieNonceAuthenticationEndpoints(for: credentialsB))
    }

    func test_default_credentials_when_incoming_type_is_not_wporg_or_nil_then_clears_endpoints() throws {
        let replacements: [Credentials?] = [
            .applicationPassword(username: "merchant", password: "application-password", siteAddress: "https://example.com"),
            .wpcom(username: "merchant", authToken: "token", siteAddress: "https://example.com"),
            nil
        ]

        for replacement in replacements {
            // Given
            let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
            let sut = SessionManager(defaults: defaults, keychainServiceName: UUID().uuidString)
            let credentials = Credentials.wporg(username: "merchant", password: "password", siteAddress: "https://example.com")
            let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: XCTUnwrap(URL(string: "https://example.com")))
            sut.defaultCredentials = credentials
            try sut.saveCookieNonceAuthenticationEndpoints(endpoints, for: credentials)

            // When
            sut.defaultCredentials = replacement

            // Then
            XCTAssertNil(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue))
        }
    }

    func test_reset_when_endpoint_record_exists_then_removes_it_explicitly() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sut = SessionManager(defaults: defaults, keychainServiceName: UUID().uuidString)
        let credentials = Credentials.wporg(username: "merchant", password: "password", siteAddress: "https://example.com")
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: XCTUnwrap(URL(string: "https://example.com")))
        try sut.saveCookieNonceAuthenticationEndpoints(endpoints, for: credentials)

        // When
        sut.reset()

        // Then
        XCTAssertNil(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue))
    }

    func test_delete_application_password_when_wporg_identity_matches_then_injects_restored_endpoints_into_final_use_case() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        var capturedUsername: String?
        var capturedPassword: String?
        var capturedSiteAddress: String?
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?
        let sut = SessionManager(
            defaults: defaults,
            keychainServiceName: UUID().uuidString,
            applicationPasswordUseCaseFactory: .init(makeWordPressOrgUseCase: { username, password, siteAddress, endpoints in
                capturedUsername = username
                capturedPassword = password
                capturedSiteAddress = siteAddress
                capturedEndpoints = endpoints
                return MockDeletionApplicationPasswordUseCase()
            })
        )
        let credentials: Credentials = .wporg(
            username: "merchant",
            password: "password",
            siteAddress: "https://example.com"
        )
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://example.com")),
            loginEntryURL: XCTUnwrap(URL(string: "https://example.com/custom-login")),
            adminBaseURL: XCTUnwrap(URL(string: "https://example.com/private-admin/"))
        )
        try sut.saveCookieNonceAuthenticationEndpoints(endpoints, for: credentials)

        // When
        sut.deleteApplicationPassword(using: credentials, locally: false)

        // Then
        XCTAssertEqual(capturedUsername, "merchant")
        XCTAssertEqual(capturedPassword, "password")
        XCTAssertEqual(capturedSiteAddress, "https://example.com")
        XCTAssertEqual(capturedEndpoints, endpoints)
    }

    func test_delete_application_password_without_explicit_credentials_then_injects_restored_credentials_and_endpoints() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let keychainServiceName = UUID().uuidString
        let keychain = Keychain(service: keychainServiceName)
        var capturedUsername: String?
        var capturedPassword: String?
        var capturedSiteAddress: String?
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?
        let sut = SessionManager(
            defaults: defaults,
            keychainServiceName: keychainServiceName,
            applicationPasswordUseCaseFactory: .init(makeWordPressOrgUseCase: { username, password, siteAddress, endpoints in
                capturedUsername = username
                capturedPassword = password
                capturedSiteAddress = siteAddress
                capturedEndpoints = endpoints
                return MockDeletionApplicationPasswordUseCase()
            })
        )
        let credentials: Credentials = .wporg(
            username: "merchant",
            password: "password",
            siteAddress: "https://example.com"
        )
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://example.com")),
            loginEntryURL: XCTUnwrap(URL(string: "https://example.com/custom-login")),
            adminBaseURL: XCTUnwrap(URL(string: "https://example.com/private-admin/"))
        )
        defaults[.defaultUsername] = credentials.username
        defaults[.defaultSiteAddress] = credentials.siteAddress
        defaults[.defaultCredentialsType] = credentials.rawType
        keychain[credentials.username] = credentials.secret
        defer { keychain[credentials.username] = nil }
        try sut.saveCookieNonceAuthenticationEndpoints(endpoints, for: credentials)

        // When
        sut.deleteApplicationPassword(using: nil, locally: false)

        // Then
        XCTAssertEqual(capturedUsername, "merchant")
        XCTAssertEqual(capturedPassword, "password")
        XCTAssertEqual(capturedSiteAddress, "https://example.com")
        XCTAssertEqual(capturedEndpoints, endpoints)
    }

    func test_delete_application_password_with_explicit_endpoints_after_credentials_change_then_injects_captured_endpoints() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?
        let sut = SessionManager(
            defaults: defaults,
            keychainServiceName: UUID().uuidString,
            applicationPasswordUseCaseFactory: .init(makeWordPressOrgUseCase: { _, _, _, endpoints in
                capturedEndpoints = endpoints
                return MockDeletionApplicationPasswordUseCase()
            })
        )
        let credentials: Credentials = .wporg(
            username: "merchant",
            password: "password",
            siteAddress: "https://example.com"
        )
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://example.com")),
            loginEntryURL: XCTUnwrap(URL(string: "https://example.com/custom-login")),
            adminBaseURL: XCTUnwrap(URL(string: "https://example.com/private-admin/"))
        )
        sut.defaultCredentials = credentials
        try sut.saveCookieNonceAuthenticationEndpoints(endpoints, for: credentials)
        sut.defaultCredentials = .wpcom(username: "wpcom-user", authToken: "token", siteAddress: "https://example.com")
        XCTAssertNil(sut.cookieNonceAuthenticationEndpoints(for: credentials))

        // When
        sut.deleteApplicationPassword(
            using: credentials,
            cookieNonceAuthenticationEndpoints: endpoints,
            locally: false
        )

        // Then
        XCTAssertEqual(capturedEndpoints, endpoints)
    }

    /// Verifies that WPCOM credentials are returned for already installed and logged in versions which don't have type stored in user defaults
    ///
    func test_already_installed_version_without_authentication_type_saved_returns_WPCOM_credentials() throws {
        // Given
        let uuid = UUID().uuidString

        // Prepare user defaults
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[UserDefaults.Key.defaultUsername] = "lalala"
        defaults[UserDefaults.Key.defaultSiteAddress] = "https://example.com"

        // Prepare keychain
        let keychainServiceName = uuid
        Keychain(service: keychainServiceName)["lalala"] = "1234"

        // When

        // Check that credential type isn't available
        XCTAssertNil(defaults[UserDefaults.Key.defaultCredentialsType])

        let sut = SessionManager(defaults: defaults, keychainServiceName: keychainServiceName)

        // Then
        XCTAssertEqual(sut.defaultCredentials, Settings.wpcomCredentials)
    }

    func test_legacy_credentials_without_type_when_replaced_by_matching_wporg_identity_then_retains_incoming_endpoints() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.defaultUsername] = "merchant"
        defaults[.defaultSiteAddress] = "https://example.com"
        Keychain(service: uuid)["merchant"] = "password"
        let sut = SessionManager(defaults: defaults, keychainServiceName: uuid)
        let incoming: Credentials = .wporg(username: "merchant", password: "password", siteAddress: "https://example.com")
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: "https://example.com")),
            loginEntryURL: XCTUnwrap(URL(string: "https://example.com/custom-login"))
        )
        try sut.saveCookieNonceAuthenticationEndpoints(endpoints, for: incoming)
        XCTAssertNil(defaults[.defaultCredentialsType])
        XCTAssertEqual(
            sut.defaultCredentials,
            .wpcom(username: "merchant", authToken: "password", siteAddress: "https://example.com")
        )

        // When
        sut.defaultCredentials = incoming

        // Then
        XCTAssertEqual(sut.cookieNonceAuthenticationEndpoints(for: incoming), endpoints)
    }

    func test_default_credentials_when_assignment_is_redundant_then_does_not_mutate_corrupt_endpoint_metadata() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let sut = SessionManager(defaults: defaults, keychainServiceName: UUID().uuidString)
        let credentials: Credentials = .wporg(username: "merchant", password: "password", siteAddress: "https://example.com")
        sut.defaultCredentials = credentials
        let corruptData = Data("corrupt endpoint metadata".utf8)
        defaults.set(corruptData, forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)

        // When
        sut.defaultCredentials = credentials

        // Then
        XCTAssertEqual(defaults.data(forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue), corruptData)
    }

    func test_endpoint_fallback_and_verified_standard_removal_preserve_credentials_and_keychain_secret() throws {
        // Given
        let keychainServiceName = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let keychain = Keychain(service: keychainServiceName)
        let sut = SessionManager(defaults: defaults, keychainServiceName: keychainServiceName)
        let credentials: Credentials = .wporg(
            username: "Merchant",
            password: "secret",
            siteAddress: "https://example.com"
        )
        defer { keychain[credentials.username] = nil }
        sut.defaultCredentials = credentials
        let invalidRecords = [
            Data("corrupt endpoint metadata".utf8),
            try PropertyListSerialization.data(
                fromPropertyList: [
                    "siteURL": "https://other.example",
                    "username": "Merchant",
                    "loginEntryURL": "https://other.example/custom-login",
                    "adminBaseURL": "https://other.example/wp-admin/"
                ],
                format: .binary,
                options: 0
            )
        ]

        for record in invalidRecords {
            // When
            defaults.set(record, forKey: UserDefaults.Key.cookieNonceAuthenticationEndpoints.rawValue)

            // Then
            XCTAssertNil(sut.cookieNonceAuthenticationEndpoints(for: credentials))
            XCTAssertEqual(sut.defaultCredentials, credentials)
            XCTAssertEqual(keychain[credentials.username], credentials.secret)
        }

        // Given
        let customEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: credentials.siteAddress)),
            loginEntryURL: XCTUnwrap(URL(string: "https://example.com/custom-login"))
        )
        let standardEndpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: credentials.siteAddress))
        )
        try sut.saveCookieNonceAuthenticationEndpoints(customEndpoints, for: credentials)
        let persistence = try XCTUnwrap(
            SiteCredentialAuthenticationEndpointPersistence(credentials: credentials, endpoints: standardEndpoints)
        )
        guard case .removeVerifiedStandard = persistence.behavior else {
            return XCTFail("Verified standard endpoints must remove the stale custom record")
        }

        // When
        try sut.removeCookieNonceAuthenticationEndpoints(for: persistence.credentials)

        // Then
        XCTAssertNil(sut.cookieNonceAuthenticationEndpoints(for: credentials))
        XCTAssertEqual(sut.defaultCredentials, credentials)
        XCTAssertEqual(keychain[credentials.username], credentials.secret)
    }

    func test_core_data_reset_clears_timestamps_stores() throws {

        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // Preload info
        defaults[UserDefaults.Key.latestBackgroundOrderSyncDate] = Date.now
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                DashboardTimestampStore.saveTimestamp(Date.now, for: card, at: range, store: defaults)
            }
        }

        // When
        let sut = SessionManager(defaults: defaults, keychainServiceName: uuid)
        NotificationCenter.default.post(name: .StorageManagerDidResetStorage, object: nil)

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.latestBackgroundOrderSyncDate])
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                XCTAssertNil(DashboardTimestampStore.loadTimestamp(for: card, at: range, store: defaults))
            }
        }
    }

    func test_core_data_database_drop_clears_timestamps_stores() throws {

        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // Preload info
        defaults[UserDefaults.Key.latestBackgroundOrderSyncDate] = Date.now
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                DashboardTimestampStore.saveTimestamp(Date.now, for: card, at: range, store: defaults)
            }
        }

        // When
        let sut = SessionManager(defaults: defaults, keychainServiceName: uuid)
        NotificationCenter.default.post(name: .StorageManagerDidDropDatabase, object: nil)

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.latestBackgroundOrderSyncDate])
        for card in DashboardTimestampStore.Card.allCases {
            for range in DashboardTimestampStore.TimeRange.allCases {
                XCTAssertNil(DashboardTimestampStore.loadTimestamp(for: card, at: range, store: defaults))
            }
        }
    }
}

// MARK: - Testing Constants
//
private enum Settings {
    static let keychainServiceName = "com.automattic.woocommerce.tests"
    static let defaults = UserDefaults(suiteName: "sessionManagerTests")!
    static let wpcomCredentials = Credentials.wpcom(username: "lalala", authToken: "1234", siteAddress: "https://example.com")
    static let wporgCredentials = Credentials.wporg(username: "yayaya", password: "5678", siteAddress: "https://wordpress.com")
    static let applicationPasswordCredentials = Credentials.applicationPassword(username: "username", password: "password", siteAddress: "siteAddress")
}

private final class MockDeletionApplicationPasswordUseCase: ApplicationPasswordUseCase {
    var applicationPassword: ApplicationPassword? { nil }
    var canRegenerateApplicationPassword: Bool { false }

    func generateNewPassword() async throws -> ApplicationPassword {
        throw ApplicationPasswordUseCaseError.notSupported
    }

    func deletePassword(locally: Bool) async throws { }
}
