import Codegen
import Combine
import XCTest
import Networking
import Storage
@testable import WooCommerce
import Yosemite

/// StoresManager Unit Tests
///
final class StoresManagerTests: XCTestCase {
    private var cancellable: AnyCancellable?

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        let session = SessionManager.testingInstance
        session.reset()
    }

    override func tearDown() {
        cancellable?.cancel()
        super.tearDown()
    }

    /// Verifies that the Initial State is Deauthenticated, whenever there are no Default Credentials.
    ///
    func testInitialStateIsDeauthenticatedAssumingCredentialsWereMissing() {
        // Action
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Assert
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertFalse(manager.isAuthenticatedWithoutWPCom)
        XCTAssertEqual(isLoggedInValues, [false])
    }


    /// Verifies that the Initial State is Authenticated with wpcom credentials.
    ///
    func test_initial_state_is_authenticated_if_defaultCredentials_is_wpcom() {
        // Arrange
        let session = SessionManager.testingInstance
        session.defaultCredentials = SessionSettings.wpcomCredentials

        // Action
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Assert
        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertFalse(manager.isAuthenticatedWithoutWPCom)
        XCTAssertEqual(isLoggedInValues, [true])
    }

    /// Verifies that the Initial State is Authenticated with wporg credentials.
    ///
    func test_initial_state_is_authenticated_if_defaultCredentials_is_wporg() {
        // Arrange
        let session = SessionManager.testingInstance
        session.defaultCredentials = SessionSettings.wporgCredentials

        // Action
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Assert
        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertTrue(manager.isAuthenticatedWithoutWPCom)
        XCTAssertEqual(isLoggedInValues, [true])
    }

    func test_authenticated_state_relaunch_passes_restored_custom_endpoints_to_network_factory() throws {
        // Given
        let sessionManager = SessionManager(
            defaults: try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString)),
            keychainServiceName: UUID().uuidString
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
        sessionManager.defaultCredentials = credentials
        sessionManager.saveCookieNonceAuthenticationEndpoints(endpoints, for: credentials)
        var capturedCredentials: Credentials?
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?

        // When
        let state = AuthenticatedState(sessionManager: sessionManager) { credentials, _, _, endpoints in
            capturedCredentials = credentials
            capturedEndpoints = endpoints
            return AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil)
        }

        // Then
        XCTAssertNotNil(state)
        XCTAssertEqual(capturedCredentials, credentials)
        XCTAssertEqual(capturedEndpoints, endpoints)
    }

    func test_authenticated_state_transient_custom_endpoints_pass_to_network_factory() throws {
        // Given
        let sessionManager = SessionManager(
            defaults: try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString)),
            keychainServiceName: UUID().uuidString
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
        var capturedCredentials: Credentials?
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?

        // When
        _ = AuthenticatedState(
            credentials: credentials,
            sessionManager: sessionManager,
            cookieNonceAuthenticationEndpoints: endpoints,
            networkFactory: { credentials, _, _, endpoints in
                capturedCredentials = credentials
                capturedEndpoints = endpoints
                return AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil)
            },
            isLocalCatalogFeatureFlagEnabled: false
        )

        // Then
        XCTAssertEqual(capturedCredentials, credentials)
        XCTAssertEqual(capturedEndpoints, endpoints)
    }

    func test_authenticated_state_in_session_reauthentication_restores_custom_endpoints_when_transient_value_is_missing() throws {
        // Given
        let sessionManager = SessionManager(
            defaults: try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString)),
            keychainServiceName: UUID().uuidString
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
        sessionManager.defaultCredentials = credentials
        sessionManager.saveCookieNonceAuthenticationEndpoints(endpoints, for: credentials)
        var capturedEndpoints: CookieNonceAuthenticationEndpoints?

        // When
        _ = AuthenticatedState(
            credentials: credentials,
            sessionManager: sessionManager,
            cookieNonceAuthenticationEndpoints: nil,
            networkFactory: { _, _, _, endpoints in
                capturedEndpoints = endpoints
                return AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil)
            },
            isLocalCatalogFeatureFlagEnabled: false
        )

        // Then
        XCTAssertEqual(capturedEndpoints, endpoints)
    }

    /// Verifies that the Initial State is Authenticated with application password credentials.
    ///
    func test_initial_state_is_authenticated_if_defaultCredentials_is_application_password() {
        // Arrange
        let session = SessionManager.testingInstance
        session.defaultCredentials = SessionSettings.applicationPasswordCredentials

        // Action
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Assert
        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertTrue(manager.isAuthenticatedWithoutWPCom)
        XCTAssertEqual(isLoggedInValues, [true])
    }

    /// Verifies that `authenticate(username: authToken:)` effectively switches the Manager to an Authenticated State.
    ///
    func testAuthenticateEffectivelyTogglesStoreManagerToAuthenticatedState() {
        // Arrange
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Action
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)

        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertEqual(isLoggedInValues, [false, true])
    }


    /// Verifies that `deauthenticate` effectively switches the Manager to a Deauthenticated State.
    ///
    func testDeauthenticateEffectivelyTogglesStoreManagerToDeauthenticatedState() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }
        let appCoordinator = AppCoordinator(window: UIWindow(frame: .zero),
                                            stores: manager,
                                            authenticationManager: mockAuthenticationManager,
                                            loggedOutAppSettings: MockLoggedOutAppSettings(hasFinishedOnboarding: true))
        appCoordinator.start()

        // Action
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)
        manager.deauthenticate()

        // Assert
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertTrue(mockAuthenticationManager.authenticationUIInvoked)
        XCTAssertEqual(isLoggedInValues, [false, true, false])
    }

    /// Verifies that `deauthenticate` invalidates card present payment onboarding state cache.
    ///
    func testDeauthenticate_invalidates_card_present_payment_onboarding_state_cache() {
        let cardPresentPaymentOnboardingStateCache = MockCardPresentPaymentOnboardingStateCache()
        let manager = DefaultStoresManager(sessionManager: SessionManager.testingInstance,
                                           notificationCenter: MockNotificationCenter.testingInstance,
                                           cardPresentPaymentOnboardingStateCache: cardPresentPaymentOnboardingStateCache)

        manager.deauthenticate()

        XCTAssertTrue(cardPresentPaymentOnboardingStateCache.invalidateCalled)
    }

    /// Verifies that `deauthenticate` handles catalog sync cleanup gracefully when there is a default store.
    ///
    @MainActor
    func testDeauthenticate_handles_catalog_sync_cleanup_with_default_store() async {
        // Arrange
        let sessionManager = SessionManager.testingInstance
        let manager = DefaultStoresManager(sessionManager: sessionManager,
                                           notificationCenter: MockNotificationCenter.testingInstance)
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)
        manager.updateDefaultStore(storeID: 123)

        XCTAssertEqual(sessionManager.defaultStoreID, 123, "Store ID should be set before deauthentication")

        // Action - should not crash even with default store ID set
        manager.deauthenticate()

        // Give any async cleanup time to execute
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Assert - verify deauthentication completed successfully
        XCTAssertFalse(manager.isAuthenticated, "Manager should be deauthenticated")
        XCTAssertNil(sessionManager.defaultStoreID, "Default store ID should be cleared after deauthentication")
    }

    @MainActor
    func test_deauthenticate_does_not_reset_grdb_manager_when_it_was_not_initialized() {
        // Arrange
        let sessionManager = SessionManager.testingInstance
        let grdbManagerProvider = MockGRDBManagerProvider(grdbManager: nil)
        let manager = DefaultStoresManager(sessionManager: sessionManager,
                                           notificationCenter: MockNotificationCenter.testingInstance,
                                           grdbManagerProvider: grdbManagerProvider)
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)
        manager.updateDefaultStore(storeID: 123)

        // Action
        manager.deauthenticate()

        // Assert
        XCTAssertEqual(grdbManagerProvider.initializedGRDBManagerReadCount, 1)
    }

    @MainActor
    func test_deauthenticate_resets_existing_grdb_manager() async {
        // Arrange
        let sessionManager = SessionManager.testingInstance
        let resetExpectation = expectation(description: "GRDB reset is called")
        let grdbManager = MockGRDBManager {
            resetExpectation.fulfill()
        }
        let grdbManagerProvider = MockGRDBManagerProvider(grdbManager: grdbManager)
        let manager = DefaultStoresManager(sessionManager: sessionManager,
                                           notificationCenter: MockNotificationCenter.testingInstance,
                                           grdbManagerProvider: grdbManagerProvider)
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)
        manager.updateDefaultStore(storeID: 123)

        // Action
        manager.deauthenticate()

        // Assert
        await fulfillment(of: [resetExpectation], timeout: 1)
    }

    /// Verifies that `updateDefaultStore` handles catalog sync cleanup gracefully when switching stores.
    ///
    func test_updateDefaultStore_handles_catalog_sync_cleanup_when_switching_stores() {
        // Given
        let sessionManager = SessionManager.testingInstance
        let manager = DefaultStoresManager(sessionManager: sessionManager,
                                           notificationCenter: MockNotificationCenter.testingInstance)
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)
        manager.updateDefaultStore(storeID: 123)

        XCTAssertEqual(sessionManager.defaultStoreID, 123)

        // When - switch to a different store
        manager.updateDefaultStore(storeID: 456)

        // Then
        XCTAssertEqual(sessionManager.defaultStoreID, 456, "Store ID should be updated to the new store")
    }

    /// Verifies that `authenticate(username: authToken:)` persists the Credentials in the Keychain Storage.
    ///
    func testAuthenticatePersistsDefaultCredentialsInKeychain() {
        let manager = DefaultStoresManager.testingInstance
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)

        let session = SessionManager.testingInstance
        XCTAssertEqual(session.defaultCredentials, SessionSettings.wpcomCredentials)
    }

    /// Verifies the user remains authenticated after site switching
    ///
    func testRemoveDefaultStoreLeavesUserAuthenticated() {
        // Arrange
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }

        // Action
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)
        manager.removeDefaultStore()

        // Assert
        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertEqual(isLoggedInValues, [false, true])
    }

    /// Verify the session manager resets properties after site switching
    ///
    func testRemoveDefaultStoreDeletesSessionManagerDefaultsExceptCredentials() {
        let manager = DefaultStoresManager.testingInstance
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)

        let session = SessionManager.testingInstance
        manager.removeDefaultStore()

        XCTAssertNotNil(session.defaultCredentials)
        XCTAssertNil(session.defaultAccount)
        XCTAssertNil(session.defaultStoreID)
        XCTAssertNil(session.defaultSite)
    }

    // MARK: `siteID` observable

    func test_siteID_observable_emits_initial_and_subsequent_values_after_authenticating_and_deauthenticating() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        let manager = DefaultStoresManager.testingInstance
        var siteIDValues = [Int64?]()
        cancellable = manager.siteID.sink { siteID in
            siteIDValues.append(siteID)
        }

        // Action
        let siteID: Int64 = 134
        manager.updateDefaultStore(storeID: siteID)
        manager.deauthenticate()

        // Assert
        XCTAssertEqual(siteIDValues, [nil, siteID, nil])
    }

    // MARK: `updateDefaultStore(_ site: Site)`

    func test_updateDefaultStore_with_the_same_siteID_updates_site_but_does_not_emit_siteID() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        let manager = DefaultStoresManager.testingInstance
        var siteIDValues = [Int64?]()
        cancellable = manager.siteID.sink { siteID in
            siteIDValues.append(siteID)
        }
        let siteID: Int64 = 134

        // Action
        // Default site ID needs to be set before the site can be updated.
        manager.updateDefaultStore(storeID: siteID)

        let jcpSite = Site.fake().copy(siteID: siteID, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        manager.updateDefaultStore(jcpSite)
        let siteIDValuesAfterUpdatingWithJCPSite = siteIDValues

        let jetpackSite = Site.fake().copy(siteID: siteID, isJetpackThePluginInstalled: true, isJetpackConnected: true)
        manager.updateDefaultStore(jetpackSite)
        let siteIDValuesAfterUpdatingWithJetpackSite = siteIDValues

        // Assert
        XCTAssertEqual(siteIDValuesAfterUpdatingWithJCPSite, [nil, siteID])
        XCTAssertEqual(siteIDValuesAfterUpdatingWithJetpackSite, [nil, siteID])
        XCTAssertEqual(manager.sessionManager.defaultSite, jetpackSite)
    }

    func test_updateDefaultStore_with_site_of_a_different_siteID_does_not_update_site_nor_emit_siteID() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        let manager = DefaultStoresManager.testingInstance
        var siteIDValues = [Int64?]()
        cancellable = manager.siteID.sink { siteID in
            siteIDValues.append(siteID)
        }

        // Action
        let siteID: Int64 = 134
        manager.updateDefaultStore(storeID: siteID)

        let differentSiteID: Int64 = 256
        let differentSite = Site.fake().copy(siteID: differentSiteID, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        manager.updateDefaultStore(differentSite)

        // Assert
        XCTAssertEqual(siteIDValues, [nil, siteID])
        XCTAssertNil(manager.sessionManager.defaultSite)
    }

    func test_updateDefaultStore_with_site_without_setting_previous_siteID_does_not_update_site_nor_emit_siteID() {
        // Arrange
        let mockAuthenticationManager = MockAuthenticationManager()
        ServiceLocator.setAuthenticationManager(mockAuthenticationManager)
        let manager = DefaultStoresManager.testingInstance
        var siteIDValues = [Int64?]()
        cancellable = manager.siteID.sink { siteID in
            siteIDValues.append(siteID)
        }

        // Action
        let siteID: Int64 = 134
        let site = Site.fake().copy(siteID: siteID, isJetpackThePluginInstalled: false, isJetpackConnected: true)
        manager.updateDefaultStore(site)

        // Assert
        XCTAssertEqual(siteIDValues, [nil])
        XCTAssertNil(manager.sessionManager.defaultSite)
    }

    func test_site_endpoint_overlay_when_direct_site_identities_match_then_replaces_only_login_and_admin_urls() throws {
        // Given
        let site = Site.fake().copy(
            siteID: WooConstants.placeholderStoreID,
            url: "https://example.com/store",
            adminURL: "https://example.com/store/wp-admin/",
            loginURL: "https://example.com/store/wp-login.php"
        )
        let endpoints = try makeCookieNonceAuthenticationEndpoints(siteAddress: "https://example.com/store/")
        let (sut, sessionManager) = makeStoresManager(
            credentials: .wporg(username: "merchant", password: "secret", siteAddress: "https://example.com/store/"),
            endpoints: endpoints
        )

        // When
        let result = sut.siteByApplyingCookieNonceAuthenticationEndpoints(to: site)

        // Then
        XCTAssertEqual(result, site.copy(adminURL: endpoints.adminBaseURL.absoluteString, loginURL: endpoints.loginEntryURL.absoluteString))
        XCTAssertEqual(sessionManager.cookieNonceAuthenticationEndpointCredentials, sessionManager.defaultCredentials)
    }

    func test_site_endpoint_overlay_when_site_is_default_port_HTTPS_promotion_then_replaces_login_and_admin_urls() throws {
        // Given
        let credentialSiteAddress = "http://example.com:80/store/"
        let site = Site.fake().copy(
            siteID: WooConstants.placeholderStoreID,
            url: "https://example.com/store",
            adminURL: "https://example.com/store/wp-admin/",
            loginURL: "https://example.com/store/wp-login.php"
        )
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: XCTUnwrap(URL(string: credentialSiteAddress)),
            loginEntryURL: XCTUnwrap(URL(string: "https://example.com/store/hidden-login")),
            adminBaseURL: XCTUnwrap(URL(string: "https://example.com/store/hidden-admin/"))
        )
        let (sut, _) = makeStoresManager(
            credentials: .wporg(username: "merchant", password: "secret", siteAddress: credentialSiteAddress),
            endpoints: endpoints
        )

        // When
        let result = sut.siteByApplyingCookieNonceAuthenticationEndpoints(to: site)

        // Then
        XCTAssertEqual(result, site.copy(adminURL: endpoints.adminBaseURL.absoluteString, loginURL: endpoints.loginEntryURL.absoluteString))
    }

    func test_site_endpoint_overlay_when_non_default_port_changes_scheme_then_leaves_site_unchanged() throws {
        // Given
        let credentialSiteAddress = "http://example.com:8080/store"
        let site = Site.fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://example.com:8080/store")
        let endpoints = try makeCookieNonceAuthenticationEndpoints(siteAddress: credentialSiteAddress)
        let (sut, _) = makeStoresManager(
            credentials: .wporg(username: "merchant", password: "secret", siteAddress: credentialSiteAddress),
            endpoints: endpoints
        )

        // When
        let result = sut.siteByApplyingCookieNonceAuthenticationEndpoints(to: site)

        // Then
        XCTAssertEqual(result, site)
    }

    func test_site_endpoint_overlay_when_site_has_positive_id_then_leaves_site_unchanged() throws {
        // Given
        let site = Site.fake().copy(siteID: 42, url: "https://example.com")
        let endpoints = try makeCookieNonceAuthenticationEndpoints(siteAddress: site.url)
        let (sut, sessionManager) = makeStoresManager(
            credentials: .wporg(username: "merchant", password: "secret", siteAddress: site.url),
            endpoints: endpoints
        )
        sessionManager.resetCookieNonceAuthenticationEndpointCredentials()

        // When
        let result = sut.siteByApplyingCookieNonceAuthenticationEndpoints(to: site)

        // Then
        XCTAssertEqual(result, site)
        XCTAssertNil(sessionManager.cookieNonceAuthenticationEndpointCredentials)
    }

    func test_site_endpoint_overlay_when_any_identity_differs_then_leaves_site_unchanged() throws {
        // Given
        let site = Site.fake().copy(siteID: WooConstants.placeholderStoreID, url: "https://site.example")
        let siteEndpoints = try makeCookieNonceAuthenticationEndpoints(siteAddress: site.url)
        let otherEndpoints = try makeCookieNonceAuthenticationEndpoints(siteAddress: "https://other.example")
        let cases: [(Credentials, CookieNonceAuthenticationEndpoints?)] = [
            (.wporg(username: "merchant", password: "secret", siteAddress: "https://credentials.example"), siteEndpoints),
            (.wporg(username: "merchant", password: "secret", siteAddress: site.url), otherEndpoints),
            (.wpcom(username: "merchant", authToken: "token", siteAddress: site.url), siteEndpoints),
            (.wporg(username: "merchant", password: "secret", siteAddress: site.url), nil)
        ]

        // When
        let results = cases.map { credentials, endpoints in
            makeStoresManager(credentials: credentials, endpoints: endpoints).0
                .siteByApplyingCookieNonceAuthenticationEndpoints(to: site)
        }

        // Then
        XCTAssertEqual(results, Array(repeating: site, count: cases.count))
    }

    func test_update_default_store_when_direct_site_api_copy_completes_then_reapplies_latest_endpoints() throws {
        // Given
        let site = Site.fake().copy(
            siteID: WooConstants.placeholderStoreID,
            url: "https://example.com",
            applicationPasswordAvailable: false
        )
        let initialEndpoints = try makeCookieNonceAuthenticationEndpoints(siteAddress: site.url, pathPrefix: "initial")
        let latestEndpoints = try makeCookieNonceAuthenticationEndpoints(siteAddress: site.url, pathPrefix: "latest")
        let sessionManager = MockSessionManager()
        let sut = DeferredSiteAPIStoresManager(sessionManager: sessionManager)
        sessionManager.defaultCredentials = .wporg(username: "merchant", password: "secret", siteAddress: site.url)
        sessionManager.cookieNonceAuthenticationEndpointsToReturn = initialEndpoints
        sessionManager.defaultStoreID = site.siteID
        sut.updateDefaultStore(site)
        XCTAssertEqual(
            sessionManager.defaultSite,
            site.copy(adminURL: initialEndpoints.adminBaseURL.absoluteString, loginURL: initialEndpoints.loginEntryURL.absoluteString)
        )
        sessionManager.cookieNonceAuthenticationEndpointsToReturn = latestEndpoints

        // When
        sut.completeSiteAPI(with: .success(SiteAPI(siteID: site.siteID, namespaces: [], applicationPasswordAvailable: true)))

        // Then
        XCTAssertEqual(
            sessionManager.defaultSite,
            site.copy(
                adminURL: latestEndpoints.adminBaseURL.absoluteString,
                loginURL: latestEndpoints.loginEntryURL.absoluteString,
                applicationPasswordAvailable: true
            )
        )
    }

    func test_deauthenticating_invokes_ProductImageUploader_reset() {
        // Given
        let mockProductImageUploader = MockProductImageUploader()
        ServiceLocator.setProductImageUploader(mockProductImageUploader)
        XCTAssertFalse(mockProductImageUploader.resetWasCalled)

        // When
        ServiceLocator.stores.deauthenticate()

        // Then
        XCTAssertTrue(mockProductImageUploader.resetWasCalled)
    }

    func test_deauthenticate_invokes_delete_application_password() {
        // Given
        let mockSessionManager = MockSessionManager()
        let sut = DefaultStoresManager(sessionManager: mockSessionManager)

        // When
        sut.deauthenticate()

        // Then
        XCTAssertTrue(mockSessionManager.deleteApplicationPasswordInvoked)
        XCTAssertTrue(mockSessionManager.deleteApplicationPasswordLocally)
    }

    func test_removingDefaultStore_invokes_delete_application_password() {
        // Given
        let mockSessionManager = MockSessionManager()
        let sut = DefaultStoresManager(sessionManager: mockSessionManager)

        // When
        sut.removeDefaultStore()

        // Then
        XCTAssertTrue(mockSessionManager.deleteApplicationPasswordInvoked)
        XCTAssertTrue(mockSessionManager.deleteApplicationPasswordLocally)
    }

    func test_updating_default_storeID_sets_storePhoneNumber_to_nil() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let mockSessionManager = MockSessionManager()
        let sut = DefaultStoresManager(sessionManager: mockSessionManager, defaults: defaults)

        // When
        defaults[.storePhoneNumber] = "0123456789"

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[.storePhoneNumber] as? String), "0123456789")

        // When
        sut.updateDefaultStore(storeID: 0)

        // Then
        XCTAssertNil(defaults[.storePhoneNumber])
    }

    func test_updating_default_storeID_sets_completedAllStoreOnboardingTasks_to_nil() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let mockSessionManager = MockSessionManager()
        let sut = DefaultStoresManager(sessionManager: mockSessionManager, defaults: defaults)

        // When
        defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks] as? Bool))

        // When
        sut.updateDefaultStore(storeID: 0)

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.completedAllStoreOnboardingTasks])
    }

    func test_updating_default_storeID_sets_usedProductDescriptionAI_to_nil() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let mockSessionManager = MockSessionManager()
        let sut = DefaultStoresManager(sessionManager: mockSessionManager, defaults: defaults)

        // When
        defaults[UserDefaults.Key.usedProductDescriptionAI] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.usedProductDescriptionAI] as? Bool))

        // When
        sut.updateDefaultStore(storeID: 0)

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.usedProductDescriptionAI])
    }

    func test_updating_default_storeID_sets_hasDismissedWriteWithAITooltip_to_nil() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let mockSessionManager = MockSessionManager()
        let sut = DefaultStoresManager(sessionManager: mockSessionManager, defaults: defaults)

        // When
        defaults[UserDefaults.Key.hasDismissedWriteWithAITooltip] = true

        // Then
        XCTAssertTrue(try XCTUnwrap(defaults[UserDefaults.Key.hasDismissedWriteWithAITooltip] as? Bool))

        // When
        sut.updateDefaultStore(storeID: 0)

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.hasDismissedWriteWithAITooltip])
    }

    func test_updating_default_storeID_sets_numberOfTimesWriteWithAITooltipIsShown_to_nil() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let mockSessionManager = MockSessionManager()
        let sut = DefaultStoresManager(sessionManager: mockSessionManager, defaults: defaults)

        // When
        defaults[UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown] = 3

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults[UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown] as? Int), 3)

        // When
        sut.updateDefaultStore(storeID: 0)

        // Then
        XCTAssertNil(defaults[UserDefaults.Key.numberOfTimesWriteWithAITooltipIsShown])
    }

    /// Verifies that user is logged out when WPCOM token expires
    ///
    func test_it_deauthenticates_upon_receiving_invalid_token_error_notification() {
        // Given
        let manager = DefaultStoresManager.testingInstance
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)

        // When
        let error = DotcomError.invalidToken
        MockNotificationCenter.testingInstance.post(name: .RemoteDidReceiveInvalidTokenError, object: error, userInfo: nil)

        // Assert
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertEqual(isLoggedInValues, [false, true, false])
    }

    func test_it_deauthenticates_non_wpcom_session_upon_receiving_application_password_invalidated_notification() {
        // Given
        let notificationCenter = MockNotificationCenter()
        let manager = DefaultStoresManager(sessionManager: SessionManager.testingInstance,
                                           notificationCenter: notificationCenter)
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }
        manager.authenticate(credentials: SessionSettings.applicationPasswordCredentials)

        // When
        notificationCenter.post(name: .ApplicationPasswordInvalidated, object: NetworkError.unacceptableStatusCode(statusCode: 401), userInfo: nil)

        // Then
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertEqual(isLoggedInValues, [false, true, false])
    }

    func test_it_does_not_deauthenticate_wpcom_session_upon_receiving_application_password_invalidated_notification() {
        // Given
        let notificationCenter = MockNotificationCenter()
        let manager = DefaultStoresManager(sessionManager: SessionManager.testingInstance,
                                           notificationCenter: notificationCenter)
        var isLoggedInValues = [Bool]()
        cancellable = manager.isLoggedInPublisher.sink { isLoggedIn in
            isLoggedInValues.append(isLoggedIn)
        }
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)

        // When
        notificationCenter.post(name: .ApplicationPasswordInvalidated, object: NetworkError.unacceptableStatusCode(statusCode: 401), userInfo: nil)

        // Then
        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertEqual(isLoggedInValues, [false, true])
    }

    /// Verifies that the selected store is reset—while keeping the user authenticated—upon receiving an unknown blog error notification.
    ///
    func test_it_resets_selected_store_and_stays_authenticated_upon_receiving_unknown_blog_error_notification() {
        // Given
        let sessionManager = SessionManager.testingInstance
        let manager = DefaultStoresManager(sessionManager: sessionManager,
                                           notificationCenter: MockNotificationCenter.testingInstance)
        manager.authenticate(credentials: SessionSettings.wpcomCredentials)
        manager.updateDefaultStore(storeID: 123)
        XCTAssertEqual(sessionManager.defaultStoreID, 123)

        // When
        let error = DotcomError.unknownBlog()
        MockNotificationCenter.testingInstance.post(name: .RemoteDidReceiveUnknownBlogError, object: error, userInfo: nil)

        // Then
        XCTAssertNil(sessionManager.defaultStoreID, "Selected store should be cleared")
        XCTAssertTrue(manager.isAuthenticated, "User should remain authenticated")
        XCTAssertTrue(manager.needsDefaultStore, "Should route to the store picker")
    }

    /// Verifies that default store is reset when initialized in an unexpected state: deauthenticated state with default store set.
    ///
    func test_it_resets_default_store_when_initialized_with_deauthenticated_state_and_default_store_set() {
        // Given
        let sessionManager = SessionManager.makeForTesting(defaultSite: Site.fake().copy(siteID: 123))
        let manager = DefaultStoresManager(sessionManager: sessionManager)
        manager.initializeAfterDependenciesAreInitialized()

        // Then
        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertTrue(manager.needsDefaultStore)
    }

    private func makeCookieNonceAuthenticationEndpoints(
        siteAddress: String,
        pathPrefix: String = "hidden"
    ) throws -> CookieNonceAuthenticationEndpoints {
        let siteURL = try XCTUnwrap(URL(string: siteAddress))
        return try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: siteURL.appendingPathComponent("\(pathPrefix)-login"),
            adminBaseURL: siteURL.appendingPathComponent("\(pathPrefix)-admin", isDirectory: true)
        )
    }

    private func makeStoresManager(
        credentials: Credentials,
        endpoints: CookieNonceAuthenticationEndpoints?
    ) -> (DefaultStoresManager, MockSessionManager) {
        let sessionManager = MockSessionManager()
        sessionManager.defaultCredentials = credentials
        sessionManager.cookieNonceAuthenticationEndpointsToReturn = endpoints
        return (DefaultStoresManager(sessionManager: sessionManager), sessionManager)
    }
}


// MARK: - StoresManager: Testing Methods
//
extension DefaultStoresManager {

    /// Returns a StoresManager instance with testing Keychain/UserDefaults
    ///
    static var testingInstance: DefaultStoresManager {
        return DefaultStoresManager(sessionManager: SessionManager.testingInstance,
                                    notificationCenter: MockNotificationCenter.testingInstance)
    }
}

final class MockAuthenticationManager: AuthenticationManager {
    private(set) var authenticationUIInvoked: Bool = false

    override func authenticationUI() -> UIViewController {
        authenticationUIInvoked = true
        return UIViewController()
    }
}

private final class MockGRDBManagerProvider: GRDBManagerProviding {
    private let grdbManager: GRDBManagerProtocol?
    private(set) var initializedGRDBManagerReadCount = 0

    init(grdbManager: GRDBManagerProtocol?) {
        self.grdbManager = grdbManager
    }

    var initializedGRDBManager: GRDBManagerProtocol? {
        initializedGRDBManagerReadCount += 1
        return grdbManager
    }
}

private final class MockGRDBManager: GRDBManagerProtocol {
    private let onReset: () -> Void

    var databaseConnection: GRDBDatabaseConnection {
        fatalError("MockGRDBManager.databaseConnection should not be accessed by these tests.")
    }

    init(onReset: @escaping () -> Void) {
        self.onReset = onReset
    }

    func reset() throws {
        onReset()
    }
}

private final class DeferredSiteAPIStoresManager: DefaultStoresManager {
    private var siteAPICompletion: ((Result<SiteAPI, Error>) -> Void)?

    override func dispatch(_ action: Action) {
        guard let action = action as? SettingAction,
              case let .retrieveSiteAPI(_, completion) = action else {
            return
        }
        siteAPICompletion = completion
    }

    func completeSiteAPI(with result: Result<SiteAPI, Error>) {
        siteAPICompletion?(result)
    }
}

final class MockSessionManager: SessionManagerProtocol {

    private(set) var deleteApplicationPasswordInvoked: Bool = false
    private(set) var deleteApplicationPasswordLocally = false

    var defaultAccount: Yosemite.Account? = nil

    var defaultAccountID: Int64? = nil

    var defaultSite: Yosemite.Site? = nil

    let site = PassthroughSubject<Yosemite.Site?, Never>()

    var defaultSitePublisher: AnyPublisher<Yosemite.Site?, Never> {
        site.eraseToAnyPublisher()
    }

    var defaultStoreID: Int64? = nil

    var defaultStoreUUID: String? = nil

    var defaultStoreURL: String? = nil

    var defaultRoles: [Yosemite.User.Role] = []

    let storeID = PassthroughSubject<Int64?, Never>()

    var defaultStoreIDPublisher: AnyPublisher<Int64?, Never> {
        storeID.eraseToAnyPublisher()
    }

    var anonymousUserID: String? = nil

    var cachedWooCommerceVersion: String? = nil

    var defaultCredentials: Yosemite.Credentials? = nil

    var cookieNonceAuthenticationEndpointsToReturn: Yosemite.CookieNonceAuthenticationEndpoints?
    private(set) var cookieNonceAuthenticationEndpointCredentials: Yosemite.Credentials?

    func cookieNonceAuthenticationEndpoints(for credentials: Credentials) -> CookieNonceAuthenticationEndpoints? {
        cookieNonceAuthenticationEndpointCredentials = credentials
        return cookieNonceAuthenticationEndpointsToReturn
    }

    func resetCookieNonceAuthenticationEndpointCredentials() {
        cookieNonceAuthenticationEndpointCredentials = nil
    }

    func saveCookieNonceAuthenticationEndpoints(_ endpoints: CookieNonceAuthenticationEndpoints,
                                                for credentials: Credentials) { }

    func removeCookieNonceAuthenticationEndpoints(for credentials: Credentials) { }

    func reset() {
        // Do nothing
    }

    func deleteApplicationPassword(using credentials: Credentials?,
                                   cookieNonceAuthenticationEndpoints: CookieNonceAuthenticationEndpoints?,
                                   locally: Bool) {
        deleteApplicationPasswordInvoked = true
        deleteApplicationPasswordLocally = locally
    }
}

private class MockNotificationCenter: NotificationCenter, @unchecked Sendable {
    static var testingInstance = MockNotificationCenter()
}

final class MockCardPresentPaymentOnboardingStateCache: CardPresentPaymentOnboardingStateCache {
    var invalidateCalled: Bool = false

    override func invalidate() {
        invalidateCalled = true
    }
}
